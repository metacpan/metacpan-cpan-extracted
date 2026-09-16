# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package Fugu::Ed25519;
our $VERSION = '0.5.1';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();
use Math::BigInt try => 'GMP,Pari';

# Fugu::Ed25519 - verify an Ed25519 signature with core Perl.
#
# The module holds the field arithmetic over Math::BigInt, the point
# decoder, and the check of RFC 8032 section 5.1.7. It verifies only:
# it signs nothing, it makes no key, and it holds no private key
# operation. A private key operation stays with signify(1), which the
# signer of Fugu::Signify runs.
#
# Fugu::Signify uses the module to verify a signify(1) signature on a
# host without the command. Every input of a verification is public,
# so the module needs no constant time. A timing side channel tells an
# attacker nothing that the signature file does not.
#
# Math::BigInt takes the GMP or the Pari backend when the host has
# one, and it falls back to the pure-Perl backend. The try list adds
# no dependency, so the module loads with core Perl alone.
#
# A shape error and a failed check are different answers. A key or a
# signature of the wrong length, and a string with a character above
# 255, are caller errors: verify returns undef, and error holds the
# reason. A well-shaped signature that fails the check returns 0. A
# caller thus tells "the caller gave bad input" from "the file is not
# authentic".

# The length of a public key, in bytes.
use constant KEY_SIZE => 32;

# The length of a signature, in bytes: the point R, then the scalar S.
use constant SIGNATURE_SIZE => 64;

# The field of the curve: the integers modulo 2^255 - 19.
my $P = Math::BigInt->new(2)->bpow(255)->bsub(19);

# The order of the base point. Section 5.1 of RFC 8032 states it in
# this form, so the code needs no long number here.
my $L =
    Math::BigInt->new(2)
    ->bpow(252)
    ->badd('27742317777372353535851937790883648493');

# The curve constant d = -121665/121666 mod p, from its own
# definition, and 2d, which the addition formula of section 5.1.4
# takes.
my $D  = Math::BigInt->new(121666)->bmodinv($P)->bmul(-121665)->bmod($P);
my $D2 = $D->copy->bmul(2)->bmod($P);

# The square root of -1 modulo p, which is 2^((p-1)/4). The decoder
# takes it in the second case of the square root.
my $SQRT_MINUS_ONE = Math::BigInt->new(
'19681161376707505956807079304988542015446066515923890162744021073123829784752'
);

# (p-5)/8, the exponent of the candidate square root of section
# 5.1.3. The assignment must stay scalar: bdiv in list context gives
# the remainder as well.
my $SQRT_EXPONENT = $P->copy->bsub(5)->bdiv(8);

# The base point B of edwards25519, in extended homogeneous
# coordinates (X, Y, Z, T) with Z of one. Table 1 of RFC 8032
# section 5.1 states the two coordinates.
my $BASE = _point(
	Math::BigInt->new(
'15112221349535400772501151409588531511454012693041857206046113283949847762202'
	),
	Math::BigInt->new(
'46316835694926478169428394003475163141307993866256225615783033603165251855960'
	) );

# Fugu::Ed25519->new:
#	Build a verifier. The object holds the reason of the most
#	recent failure, and nothing else. The method takes no
#	argument, and it never dies.
sub new ($class)
{
	return bless { error => undef }, $class;
}

# $self->error:
#	The reason of the most recent shape error, or undef. A
#	signature that does not verify is not a shape error, so error
#	is undef after a return of 0.
sub error ($self)
{
	return $self->{error};
}

# $self->verify(%args):
#	Verify one Ed25519 signature.
#
#	%args:
#		key       => $bytes # Required: the 32-byte public key
#		signature => $bytes # Required: the 64-byte signature
#		message   => $bytes # The signed bytes, or
#		file      => $path  # the path of the signed file
#
#	The method returns 1 for a signature that verifies, and 0 for
#	one that does not. It returns undef for a shape error, and
#	error then holds the reason.
#
#	A file streams through the hash, so a file of any size needs
#	no memory. The caller names message or file, never both.
sub verify ( $self, %args )
{
	$self->{error} = undef;

	return
	    unless $self->_check_bytes( $args{key}, 'public key', KEY_SIZE );
	return
	    unless $self->_check_bytes( $args{signature}, 'signature',
		SIGNATURE_SIZE );
	return unless $self->_check_message(%args);

	my $r_bytes = substr $args{signature}, 0, KEY_SIZE;

	# The hash runs first, so a file that does not open is a shape
	# error and never a failed check.
	my $k = $self->_challenge( $r_bytes, $args{key}, %args );
	return unless defined $k;

	# RFC 8032 section 5.1.7 step 1: a scalar at or above the group
	# order, and an encoding that decodes to no point, are each a
	# signature that does not verify.
	my $s = _le_integer( substr $args{signature}, KEY_SIZE, KEY_SIZE );
	return 0 if $s >= $L;

	my $a = _decode_point( $args{key} );
	return 0 unless defined $a;

	my $r = _decode_point($r_bytes);
	return 0 unless defined $r;

	# Step 3, in the form that the step names as sufficient:
	# [S]B = R + [k]A. One ladder covers both scalars, so the
	# check computes [S]B + [k](-A) and compares it with R.
	my $sum = _double_scalar_multiply( $s, $BASE, $k, _negate($a) );

	return _equal( $sum, $r ) ? 1 : 0;
}

# $self->_fail($reason):
#	Hold the reason of a shape error, and return undef.
sub _fail ( $self, $reason )
{
	$self->{error} = $reason;
	return;
}

# $self->_check_bytes($value, $name, $size):
#	Hold one argument to a byte string of the named length.
#	Digest::SHA dies on a string with a character above 255, and a
#	byte unpack of one would give a wrong answer in place of a
#	failure. The method returns 1, or undef with the reason.
sub _check_bytes ( $self, $value, $name, $size )
{
	return $self->_fail("the $name is a necessary argument")
	    unless defined $value;

	return $self->_fail(
		"the $name holds a character above 255, and it is bytes")
	    if $value =~ /[^\x00-\xFF]/;

	return $self->_fail(
		sprintf 'the %s must be %d bytes, and this one is %d',
		$name, $size, length $value )
	    if length($value) != $size;

	return 1;
}

# $self->_check_message(%args):
#	Hold the message arguments to one of message and file. The
#	method returns 1, or undef with the reason.
sub _check_message ( $self, %args )
{
	my $message = $args{message};
	my $file    = $args{file};

	return $self->_fail('verify needs a message or a file')
	    unless defined $message || defined $file;

	return $self->_fail('verify takes a message or a file, never both')
	    if defined $message && defined $file;

	return $self->_fail(
		'the message holds a character above 255, and it is bytes')
	    if defined $message && $message =~ /[^\x00-\xFF]/;

	return 1;
}

# $self->_challenge($r_bytes, $key, %args):
#	The challenge scalar k of RFC 8032 section 5.1.7 step 2: the
#	SHA-512 digest of R, then A, then the message, read as a
#	little-endian integer and reduced modulo the group order.
#
#	The method returns the scalar, or undef with the reason. A
#	file that does not open is the one recoverable failure here.
sub _challenge ( $self, $r_bytes, $key, %args )
{
	my $sha = Digest::SHA->new(512);
	$sha->add($r_bytes);
	$sha->add($key);

	if ( defined $args{file} ) {
		open my $fh, '<', $args{file}
		    or return $self->_fail("cannot read $args{file}: $!");
		binmode $fh;
		$sha->addfile($fh);
		close $fh;
	}
	else {
		$sha->add( $args{message} );
	}

	return _le_integer( $sha->digest )->bmod($L);
}

# _le_integer($bytes):
#	The little-endian byte string as a Math::BigInt. The reverse
#	makes it big-endian, and one hex unpack then carries it into
#	the number.
sub _le_integer ($bytes)
{
	return Math::BigInt->from_hex( unpack 'H*', scalar reverse $bytes );
}

# _point($x, $y):
#	The affine point in extended homogeneous coordinates
#	(X, Y, Z, T), with Z of one and T of x*y.
sub _point ( $x, $y )
{
	return [ $x, $y, Math::BigInt->bone, _fmul( $x, $y ) ];
}

# _fmul($x, $y), _fadd($x, $y), _fsub($x, $y):
#	One field operation modulo p. Each one copies its first
#	argument, so no operand of a caller ever changes.
sub _fmul ( $x, $y )
{
	return $x->copy->bmul($y)->bmod($P);
}

sub _fadd ( $x, $y )
{
	return $x->copy->badd($y)->bmod($P);
}

sub _fsub ( $x, $y )
{
	return $x->copy->bsub($y)->bmod($P);
}

# _decode_point($bytes):
#	The point of a 32-byte encoding, per RFC 8032 section 5.1.3,
#	or undef when the encoding decodes to no point.
#
#	The decoder is strict, and it takes the canonical encoding
#	only. A y at or above p fails, a y whose x has no square root
#	fails, and the encoding of x of zero with the sign bit set
#	fails. Two encodings of one point would let one signature
#	count twice.
sub _decode_point ($bytes)
{
	my $last = ord substr $bytes, KEY_SIZE - 1, 1;
	my $sign = $last >> 7;
	my $y    = _le_integer(
		substr( $bytes, 0, KEY_SIZE - 1 ) . chr( $last & 0x7F ) );
	return if $y >= $P;

	# x^2 = (y^2 - 1) / (d y^2 + 1). One modular powering covers
	# the inversion of v and the square root together:
	# x = u v^3 (u v^7)^((p-5)/8).
	my $y2 = _fmul( $y, $y );
	my $u  = _fsub( $y2, Math::BigInt->bone );
	my $v  = _fadd( _fmul( $D, $y2 ), Math::BigInt->bone );

	my $v3 = _fmul( _fmul( $v,  $v ),  $v );
	my $v7 = _fmul( _fmul( $v3, $v3 ), $v );
	my $x  = _fmul( _fmul( $u, $v3 ),
		_fmul( $u, $v7 )->bmodpow( $SQRT_EXPONENT, $P ) );

	# Three cases: a square root, a square root after the turn by
	# sqrt(-1), and no square root at all.
	my $check = _fmul( $v, _fmul( $x, $x ) );
	if ( $check != $u ) {
		return if $check != _fsub( Math::BigInt->bzero, $u );
		$x = _fmul( $x, $SQRT_MINUS_ONE );
	}

	return                                if $x->is_zero && $sign;
	$x = _fsub( Math::BigInt->bzero, $x ) if $x->is_odd != $sign;

	return _point( $x, $y );
}

# _negate($point):
#	The point with the opposite x, which is the additive inverse.
sub _negate ($point)
{
	my ( $x, $y, $z, $t ) = @$point;

	return [
		_fsub( Math::BigInt->bzero, $x ),
		$y, $z, _fsub( Math::BigInt->bzero, $t ) ];
}

# _add($p, $q):
#	The sum of two points, per RFC 8032 section 5.1.4. The formula
#	is complete: it holds for every pair of valid points, and the
#	neutral point needs no case of its own.
sub _add ( $p, $q )
{
	my ( $x1, $y1, $z1, $t1 ) = @$p;
	my ( $x2, $y2, $z2, $t2 ) = @$q;

	my $a = _fmul( _fsub( $y1, $x1 ), _fsub( $y2, $x2 ) );
	my $b = _fmul( _fadd( $y1, $x1 ), _fadd( $y2, $x2 ) );
	my $c = _fmul( _fmul( $t1, $D2 ), $t2 );
	my $d = _fmul( _fadd( $z1, $z1 ), $z2 );

	my $e = _fsub( $b, $a );
	my $f = _fsub( $d, $c );
	my $g = _fadd( $d, $c );
	my $h = _fadd( $b, $a );

	return [
		_fmul( $e, $f ),
		_fmul( $g, $h ),
		_fmul( $f, $g ),
		_fmul( $e, $h ) ];
}

# _double($p):
#	The point plus itself, per RFC 8032 section 5.1.4. The
#	doubling formula turns four multiplications into squares.
sub _double ($p)
{
	my ( $x1, $y1, $z1 ) = @$p;

	my $a = _fmul( $x1,               $x1 );
	my $b = _fmul( $y1,               $y1 );
	my $c = _fmul( _fadd( $z1, $z1 ), $z1 );

	my $h = _fadd( $a,  $b );
	my $s = _fadd( $x1, $y1 );
	my $e = _fsub( $h, _fmul( $s, $s ) );
	my $g = _fsub( $a, $b );
	my $f = _fadd( $c, $g );

	return [
		_fmul( $e, $f ),
		_fmul( $g, $h ),
		_fmul( $f, $g ),
		_fmul( $e, $h ) ];
}

# _double_scalar_multiply($m, $p, $n, $q):
#	The point [m]P + [n]Q, through one ladder over both scalars.
#	The four-entry table holds the neutral point, P, Q and P+Q, so
#	each step of the ladder doubles once and adds at most once.
#	One ladder costs about half of two.
sub _double_scalar_multiply ( $m, $p, $n, $q )
{
	my @table = ( undef, $p, $q, _add( $p, $q ) );

	my $mbits = substr $m->as_bin, 2;
	my $nbits = substr $n->as_bin, 2;
	my $width =
	    length($mbits) > length($nbits) ? length($mbits) : length($nbits);
	$mbits = ( '0' x ( $width - length $mbits ) ) . $mbits;
	$nbits = ( '0' x ( $width - length $nbits ) ) . $nbits;

	my $sum = [
		Math::BigInt->bzero, Math::BigInt->bone,
		Math::BigInt->bone,  Math::BigInt->bzero
	];
	for my $i ( 0 .. $width - 1 ) {
		$sum = _double($sum);
		my $index =
		    substr( $mbits, $i, 1 ) + 2 * substr( $nbits, $i, 1 );
		$sum = _add( $sum, $table[$index] ) if $index;
	}

	return $sum;
}

# _equal($p, $q):
#	Report if two points are the same point. The comparison is
#	projective, so neither point needs an inversion: x1/z1 = x2/z2
#	holds exactly when x1*z2 = x2*z1.
sub _equal ( $p, $q )
{
	return 0 if _fmul( $p->[0], $q->[2] ) != _fmul( $q->[0], $p->[2] );
	return 0 if _fmul( $p->[1], $q->[2] ) != _fmul( $q->[1], $p->[2] );

	return 1;
}

1;
