#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Guards for Fugu::OpenPGP
#
# The two fixtures are real armored keys of gpg(1), committed as
# files. The byte reader runs no command, so its subtests run
# everywhere. The Ed25519 key packs its public key packet behind a
# one-byte length, and the RSA key needs a two-byte length. Both
# header paths therefore read a real key.
#
# The expected fingerprint of each fixture comes from
# 'gpg --list-keys --with-colons' at the time the fixture was made.
#
# The subtests of the command part run gpg(1), and each one skips
# when the command is absent. Each one takes a key that the test
# generated, so the tree carries no secret half.

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);
use Test::More;
use File::Path   ();
use File::Spec   ();
use File::Temp   qw(tempdir);
use MIME::Base64 qw(encode_base64);
use Digest::SHA  ();
use FindBin      qw($RealBin);
use lib "$RealBin/../../lib";

use_ok('Fugu::OpenPGP');
use Fugu::Process;

# The work tree of this test. Each fixture file, each key and each
# signature sits under it.
#
# The temporary home of a gpg(1) run sits under TMPDIR, and this test
# leaves that variable alone. The agent socket sits in the home, and a
# unix socket path holds about 100 bytes, so a deeper root would break
# the runs on a host whose TMPDIR is already long. The name of a home
# holds the process id, so homes() finds the homes of this test under
# TMPDIR itself.
my $BASE = $ENV{TMPDIR} // '/tmp';
$BASE =~ s{/+\z}{};
my $ROOT = "$BASE/fugu-openpgp-$$";
mkdir $ROOT or die "Cannot make $ROOT: $!";

my $WORK = "$ROOT/work";
mkdir $WORK or die "Cannot make $WORK: $!";

END {
	File::Path::remove_tree($ROOT) if defined $ROOT && -d $ROOT;

	# A home that a run left behind is a failure of the subtest
	# that reads it. The removal here holds the temporary
	# directory of the system clean after that report.
	File::Path::remove_tree($_) for homes();
}

# The fixtures, with the fingerprint that gpg(1) reported.
my %FIXTURE = (
	'openpgp-ed25519.asc' => {
		fingerprint => '5E0B59F43C61B6AEAB99BA27ED353DC0A93A0BF6',
		note        => 'a one-byte packet length',
	},
	'openpgp-rsa.asc' => {
		fingerprint => 'FB1AE38CBE7138D5F87232D4C52EC81D604D60D6',
		note        => 'a two-byte packet length',
	},
);

# slurp($name):
#	The text of a fixture beside this test file.
sub slurp ($name)
{
	my $path = "$RealBin/$name";
	open my $fh, '<', $path or die "Cannot read $path: $!";
	local $/ = undef;
	my $text = <$fh>;
	close $fh;
	return $text;
}

# The object of the byte reader. Each reader is a method of the
# object, and it needs no command, so one object serves every subtest
# of the reader.
my $PGP = Fugu::OpenPGP->new;

# reader($method, @args):
#	The answer of one reader, and the reason of a failure. Each
#	reader reports through error, per LIB-SIGNER-8, so a subtest
#	that checks a failure reads the two together.
sub reader ( $method, @args )
{
	my $answer = $PGP->$method(@args);

	return ( $answer, $PGP->error );
}

subtest 'a reader answers no reason in list context' => sub {

	# LIB-SIGNER-8 forbids a reason as a second return value. A
	# reader that kept the old shape would answer two values here,
	# and the reason would reach a caller that asked for one
	# answer.
	for my $case ( [ 'decode_armor', 'no armor here' ],
		[ 'fingerprint', "\x98\x03" ],
		[ 'wkd_hash',    '' ],
		[ 'zbase32',     "\x{263A}" ] )
	{
		my ( $method, $input ) = @$case;
		my @answer = $PGP->$method($input);
		my $reason = $PGP->error;

		is( $answer[0], undef, "$method answers undef" );
		ok( length($reason), 'and error holds the reason' );
		cmp_ok( scalar @answer, '<=', 1,
			'and the method answers no second value' );
		is( scalar( grep { defined && $_ eq $reason } @answer ),
			0, 'and no return value holds the reason' );
	}
};

subtest 'decode_armor reads each fixture' => sub {
	for my $name ( sort keys %FIXTURE ) {
		my ( $binary, $reason ) =
		    reader( 'decode_armor', slurp($name) );

		ok( defined $binary, "$name decodes" )
		    or diag($reason);
		is( $reason, undef, "$name reports no reason" );
		ok( length($binary) > 0, "$name gives bytes" );

		# The armor holds a public key packet first, so the
		# high bit of the first byte is set.
		ok( ord( substr $binary, 0, 1 ) & 0x80,
			"$name starts on a packet header" );
	}
};

subtest 'fingerprint matches the answer of gpg(1)' => sub {
	for my $name ( sort keys %FIXTURE ) {
		my $binary = $PGP->decode_armor( slurp($name) );
		my ( $got, $reason ) = reader( 'fingerprint', $binary );

		is( $got, $FIXTURE{$name}{fingerprint},
			"$name gives the fingerprint of gpg(1)"
			    . " ($FIXTURE{$name}{note})" )
		    or diag($reason);
		is( $reason, undef, "$name reports no reason" );
	}
};

subtest 'the checksum line catches a damaged body' => sub {
	my $text = slurp('openpgp-ed25519.asc');

	# A flipped checksum character. The body is intact, so only
	# the comparison finds this.
	my $flipped = $text;
	$flipped =~ s/^=(.)/'=' . ( $1 eq 'A' ? 'B' : 'A' )/me;
	my ( $binary, $reason ) = reader( 'decode_armor', $flipped );
	is( $binary, undef, 'a flipped checksum fails' );
	like( $reason, qr/checksum mismatch/, 'and the reason says so' );

	# A dropped body line. This is the dangerous case: without the
	# checksum a decoder accepts the truncated key, and a
	# truncated key has a fingerprint of its own.
	my @lines   = split /\n/, $text;
	my @shorter = grep { !/\Am[A-Za-z0-9+\/]/ } @lines;
	( $binary, $reason ) =
	    reader( 'decode_armor', join "\n", @shorter );
	is( $binary, undef, 'a dropped body line fails' );
	like( $reason, qr/checksum mismatch|no base64 body/,
		'and the reason says so' );
};

subtest 'decode_armor holds the delimiters' => sub {
	my $text = slurp('openpgp-ed25519.asc');

	my ( $binary, $reason ) = reader( 'decode_armor', 'no armor here' );
	is( $binary, undef, 'text with no delimiter fails' );
	like( $reason, qr/no BEGIN PGP delimiter/, 'and the reason says so' );

	my $no_end = $text;
	$no_end =~ s/-----END PGP PUBLIC KEY BLOCK-----//;
	( $binary, $reason ) = reader( 'decode_armor', $no_end );
	is( $binary, undef, 'a block with no end delimiter fails' );
	like( $reason, qr/no END PGP delimiter/, 'and the reason says so' );

	# A begin line of one type with an end line of another is a
	# spliced file.
	my $spliced = $text;
	$spliced =~ s/-----END PGP PUBLIC KEY BLOCK-----/-----END PGP MESSAGE-----/;
	( $binary, $reason ) = reader( 'decode_armor', $spliced );
	is( $binary, undef, 'two block types fail' );
	like( $reason, qr/two block types/, 'and the reason says so' );

	( $binary, $reason ) = reader( 'decode_armor', undef );
	is( $binary, undef, 'undef fails' );
	like( $reason, qr/undef/, 'and the reason says so' );
};

subtest 'decode_armor needs a checksum line' => sub {
	my $text = slurp('openpgp-ed25519.asc');
	my $none = $text;
	$none =~ s/^=\S{4}\n//m;

	my ( $binary, $reason ) = reader( 'decode_armor', $none );
	is( $binary, undef, 'a block with no checksum line fails' );
	like( $reason, qr/no checksum line/, 'and the reason says so' );
};

subtest 'decode_armor holds the checksum line to one place' => sub {
	my $text = slurp('openpgp-ed25519.asc');

	# Two checksum lines: a reader that took the first would
	# compare against the wrong three bytes.
	my $twice = $text;
	$twice =~ s/^(=\S{4})$/$1\n$1/m;
	my ( $binary, $reason ) = reader( 'decode_armor', $twice );
	is( $binary, undef, 'two checksum lines fail' );
	like( $reason, qr/more than one checksum line/,
		'and the reason says so' );

	# A body line after the checksum line: the checksum covers
	# the body before it, so the later line would go unchecked.
	my $after = $text;
	$after =~ s/^(=\S{4})$/$1\nbWRNRQ==/m;
	( $binary, $reason ) = reader( 'decode_armor', $after );
	is( $binary, undef, 'a body line after the checksum fails' );
	like( $reason, qr/follows the checksum line/, 'and the reason says so' );
};

subtest 'decode_armor reads an armor header' => sub {
	my $text = slurp('openpgp-ed25519.asc');

	# gpg(1) writes no header today, so the test adds one. A
	# reader must skip it and still decode the body.
	my $headed = $text;
	$headed =~
	    s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)/$1Comment: a header\n\n/;

	my ( $binary, $reason ) = reader( 'decode_armor', $headed );
	ok( defined $binary, 'a block with an armor header decodes' )
	    or diag($reason);
	is(
		$PGP->fingerprint($binary),
		$FIXTURE{'openpgp-ed25519.asc'}{fingerprint},
		'and the header changes no fingerprint'
	);
};

subtest 'decode_armor reads each line-ending and header shape' => sub {
	my $text = slurp('openpgp-ed25519.asc');
	my $want = $FIXTURE{'openpgp-ed25519.asc'}{fingerprint};

	# RFC 4880 makes the blank line after the armor headers
	# necessary, and gpg --show-keys rejects a block without it
	# with "invalid armor header". This method must not accept
	# what gpg(1) rejects: a site publishes the key that this
	# decoder validated, so a consumer must be able to import it.
	my $no_blank = $text;
	$no_blank =~ s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)\n/$1/;
	my ( $none, $why ) = reader( 'decode_armor', $no_blank );
	is( $none, undef, 'a block with no blank line fails' );
	like( $why, qr/no blank line ends the armor header section/,
		'and the reason names the blank line' );

	# Two headers, then the blank line.
	my $two = $text;
	$two =~
	    s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)/$1Comment: one\nVersion: 9\n/;
	is( $PGP->fingerprint(
			$PGP->decode_armor($two) ),
		$want, 'a block with two armor headers decodes' );

	# Armor is text, so a block that travelled through email
	# holds CRLF. The delimiter lines carry it too.
	my $crlf = $text;
	$crlf =~ s/\n/\r\n/g;
	is( $PGP->fingerprint(
			$PGP->decode_armor($crlf) ),
		$want, 'a block with CRLF line endings decodes' );

	my $crlf_no_blank = $no_blank;
	$crlf_no_blank =~ s/\n/\r\n/g;
	is( $PGP->decode_armor($crlf_no_blank),
		undef, 'CRLF with no blank line fails the same way' );

	# An armor header can hold an empty value, and gpg(1) reads
	# such a header. The pattern must therefore not need the
	# space after the colon.
	my $empty_header = $text;
	$empty_header =~
	    s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)/$1Comment:\n/;
	is( $PGP->fingerprint(
			$PGP->decode_armor($empty_header) ),
		$want, 'a header with an empty value decodes' );

	# The method must not change the string of the caller.
	my $copy = $text;
	$PGP->decode_armor($copy);
	is( $copy, $text, 'the method leaves the input string alone' );

	# A first line that is neither a header nor base64 must fail.
	# It sits before the blank line, so the header section never
	# ends, and the reason names that.
	my $garbage = $text;
	$garbage =~
	    s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)\n/$1garbage here\n\n/;
	my ( $binary, $reason ) = reader( 'decode_armor', $garbage );
	is( $binary, undef, 'a garbage first line fails' );
	like( $reason, qr/no blank line ends the armor header section/,
		'and the reason says so' );
};

subtest 'fingerprint holds the first packet to a public key' => sub {
	# A literal data packet, tag 11, in the old format with a
	# one-byte length.
	my $literal = chr( 0x80 | ( 11 << 2 ) ) . chr(3) . 'abc';
	my ( $got, $reason ) = reader( 'fingerprint', $literal );
	is( $got, undef, 'a literal data packet fails' );
	like( $reason, qr/tag 11, and not a public key/,
		'and the reason names the tag' );

	# A version 3 public key packet. Only version 4 has this
	# fingerprint form.
	my $v3 = chr(0x98) . chr(4) . chr(3) . 'xyz';
	( $got, $reason ) = reader( 'fingerprint', $v3 );
	is( $got, undef, 'a version 3 packet fails' );
	like( $reason, qr/version 3, and not 4/, 'and the reason says so' );

	( $got, $reason ) = reader( 'fingerprint', undef );
	is( $got, undef, 'undef fails' );
	like( $reason, qr/undef/, 'and the reason says so' );

	( $got, $reason ) = reader( 'fingerprint', '' );
	is( $got, undef, 'an empty string fails' );

	# A header that claims more body than the bytes hold.
	my $short = chr(0x98) . chr(200) . 'abc';
	( $got, $reason ) = reader( 'fingerprint', $short );
	is( $got, undef, 'a truncated packet body fails' );
	like( $reason, qr/truncated/, 'and the reason says so' );
};

subtest 'wkd_hash matches the published vectors' => sub {
	# The two vectors of the Web Key Directory draft.
	is(
		$PGP->wkd_hash('Joe.Doe'),
		'iy9q119eutrkn8s1mk4r39qejnbu3n5q',
		'Joe.Doe gives the published hash'
	);
	is(
		$PGP->wkd_hash('bernhard.reiter'),
		'it5sewh54rxz33fwmr8u6dy4bbz8itz4',
		'bernhard.reiter gives the published hash'
	);

	# The method lowercases the part itself, so the case of the
	# input never changes the publication path.
	is(
		$PGP->wkd_hash('joe.doe'),
		$PGP->wkd_hash('JOE.DOE'),
		'the case of the local part changes nothing'
	);

	my ( $hash, $reason ) = reader( 'wkd_hash', '' );
	is( $hash, undef, 'an empty local part fails' );
	like( $reason, qr/empty/, 'and the reason says so' );

	( $hash, $reason ) = reader( 'wkd_hash', undef );
	is( $hash, undef, 'undef fails' );
	like( $reason, qr/undef/, 'and the reason says so' );
};

subtest 'zbase32 encodes each group' => sub {
	is( $PGP->zbase32(''),    '', 'the empty string gives nothing' );
	is( $PGP->zbase32(undef), '', 'undef gives nothing' );

	# A SHA-1 digest is 20 bytes, which is 160 bits, and 160 is a
	# multiple of 5. The hash therefore ends on a whole group, and
	# it is 32 characters.
	is( length( $PGP->zbase32( "\x00" x 20 ) ),
		32, '20 bytes give 32 characters' );

	# One byte is 8 bits, so it takes two characters, and the
	# second one carries three zero bits. The assertion names the
	# characters, not the count: a missing shift of the last group
	# keeps the count and changes the answer. 0xFF is 11111111, so
	# the groups are 11111 and 11100, which are 9 and h.
	is( $PGP->zbase32("\xFF"),
		'9h', 'a partial group shifts its low bits to zero' );
	is( $PGP->zbase32("\x80"),
		'oy', 'and the same for a leading one bit' );
	is( $PGP->zbase32("\x00"),
		'yy', 'and the same for a zero byte' );

	# The alphabet starts with y, so an all-zero input gives y
	# for every character. This catches a swap to the RFC 4648
	# alphabet, which would give a.
	is( $PGP->zbase32( "\x00" x 5 ),
		'y' x 8, 'zero bytes give the first letter of the alphabet' );

};

subtest 'fingerprint reads every length form that holds a packet' => sub {
	# The body of the real key, so each form gives a checkable
	# fingerprint. The header of the file never reaches the
	# digest, so every form that carries this body must agree.
	my $binary = $PGP->decode_armor( slurp('openpgp-ed25519.asc') );
	my $length = ord substr $binary, 1, 1;
	my $body   = substr $binary, 2, $length;
	my $want   = $FIXTURE{'openpgp-ed25519.asc'}{fingerprint};

	my %form = (
		'old one-byte'  => chr(0x98) . chr($length) . $body,
		'old two-byte'  => chr(0x99) . pack( 'n', $length ) . $body,
		'old four-byte' => chr(0x9A) . pack( 'N', $length ) . $body,
		'new one-byte'  => chr(0xC6) . chr($length) . $body,
		'new five-byte' => chr(0xC6)
		    . chr(255)
		    . pack( 'N', $length )
		    . $body,
	);

	for my $name ( sort keys %form ) {
		is( $PGP->fingerprint( $form{$name} ),
			$want, "the $name length form gives the fingerprint" );
	}

	# The new two-byte form must decode a real body. Its length
	# field carries an offset of 192, so a body of 200 bytes needs
	# the field 200: the arithmetic is
	# ((first - 192) << 8) + second + 192. A test that asserts a
	# failure only would pass for any arithmetic here.
	{
		my $long = "\x04" . ( 'B' x 199 );    # 200 bytes
		my $encoded = length($long) - 192;
		my $first   = ( $encoded >> 8 ) + 192;
		my $second  = $encoded & 0xFF;
		my $packet =
		    chr(0xC6) . chr($first) . chr($second) . $long;

		is(
			$PGP->fingerprint($packet),
			uc Digest::SHA::sha1_hex(
				"\x99" . pack( 'n', length $long ) . $long
			),
			'the new two-byte length form decodes a real body'
		);
	}

	# A short length must not take the two-byte form: the offset
	# would name a body that the bytes do not hold.
	my $offset = $length + 192;
	if ( $offset >= 192 && $offset < 8384 ) {
		my $first  = ( ( $offset - 192 ) >> 8 ) + 192;
		my $second = ( $offset - 192 ) & 0xFF;
		is(
			$PGP->fingerprint(
				chr(0xC6) . chr($first) . chr($second) . $body
			),
			undef,
			'the new two-byte form of a short length holds no packet'
		);
	}

	# Two forms carry no whole packet, and a public key packet
	# never uses either.
	my ( $got, $reason ) =
	    reader( 'fingerprint', chr(0x9B) . $body );
	is( $got, undef, 'the old indeterminate length fails' );
	like( $reason, qr/indeterminate/, 'and the reason names it' );

	( $got, $reason ) = reader( 'fingerprint',
		chr(0xC6) . chr(224) . $body );
	is( $got, undef, 'a new-format partial body length fails' );
	like( $reason, qr/partial body length/, 'and the reason names it' );

	# A declared length above the bytes on hand must fail, and
	# must not read past the end.
	( $got, $reason ) =
	    reader( 'fingerprint', chr(0x99) . pack( 'n', 65535 ) . $body );
	is( $got, undef, 'an oversized declared length fails' );
	like( $reason, qr/truncated/, 'and the reason says so' );
};

subtest 'decode_armor rejects interior whitespace in a body line' => sub {
	# The trim touches the two ends of a line only. gpg(1) reads a
	# line with interior whitespace, and this method rejects one on
	# purpose: LIB-OPENPGP-5 lets the decoder be stricter, and a
	# published key must hold the shape that RFC 4880 states.
	my $text = slurp('openpgp-ed25519.asc');
	my @lines = split /\n/, $text;
	for my $i ( 0 .. $#lines ) {
		next unless $lines[$i] =~ /\Am[A-Za-z0-9+\/]/;
		substr $lines[$i], 4, 0, ' ';
		last;
	}

	my ( $binary, $reason ) =
	    reader( 'decode_armor', join "\n", @lines );
	is( $binary, undef, 'a body line with an interior space fails' );
	like( $reason, qr/not a base64 body line/, 'and the reason says so' );

	# A tab inside a line is the same fault.
	my @tabbed = split /\n/, $text;
	for my $i ( 0 .. $#tabbed ) {
		next unless $tabbed[$i] =~ /\Am[A-Za-z0-9+\/]/;
		substr $tabbed[$i], 4, 0, "\t";
		last;
	}
	is( $PGP->decode_armor( join "\n", @tabbed ),
		undef, 'a body line with an interior tab fails' );
};

subtest 'decode_armor rejects a header value with no space' => sub {
	# gpg(1) rejects "Comment:nospace" with "invalid armor
	# header", so LIB-OPENPGP-5 makes this a rule and not a
	# choice. An empty value stays valid, and gpg(1) reads it.
	my $text = slurp('openpgp-ed25519.asc');

	my $nospace = $text;
	$nospace =~
	    s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)/$1Comment:nospace\n/;
	my ( $binary, $reason ) = reader( 'decode_armor', $nospace );
	is( $binary, undef, 'a header value with no space fails' );
	like( $reason, qr/no blank line ends the armor header section/,
		'and the reason names the header section' );

	my $empty = $text;
	$empty =~ s/(-----BEGIN PGP PUBLIC KEY BLOCK-----\n)/$1Comment:\n/;
	ok( defined $PGP->decode_armor($empty),
		'an empty header value still decodes' );
};

subtest 'decode_armor holds the body to whole base64 groups' => sub {
	# base64 carries four characters for each three bytes, and
	# decode_base64 drops a trailing partial group without a
	# word. One extra character therefore gives the same bytes and
	# the same checksum, and gpg --dearmor rejects such a block.
	my $text  = slurp('openpgp-ed25519.asc');
	my @lines = split /\n/, $text;
	for my $i ( 0 .. $#lines ) {
		next unless $lines[$i] =~ /\A=/;
		$lines[ $i - 1 ] .= 'A';
		last;
	}

	my ( $binary, $reason ) =
	    reader( 'decode_armor', join "\n", @lines );
	is( $binary, undef, 'one extra base64 character fails' );
	like( $reason, qr/not a whole number of groups/,
		'and the reason names the group count' );
};

subtest 'the methods need bytes, and say so' => sub {
	# Digest::SHA dies with "Wide character in subroutine entry"
	# for a string that holds a code point above 255. The
	# contract of this module is a clean failure, so each entry
	# point must test for such a string first.
	my ( $hash, $reason ) = reader( 'wkd_hash', "caf\x{263A}" );
	is( $hash, undef, 'a wide local part fails' );
	like( $reason, qr/above 255/, 'and the reason says so' );

	my ( $got, $why ) =
	    reader( 'fingerprint', "\x98\x03\x{263A}ab" );
	is( $got, undef, 'a wide binary form fails' );
	like( $why, qr/above 255/, 'and the reason says so' );

	# unpack 'C*' takes the low byte of each code point, so
	# zbase32 would give a confident wrong answer for character
	# data: U+263A would encode as the colon, 0x3A.
	my ( $z, $zwhy ) = reader( 'zbase32', "\x{263A}" );
	is( $z, undef, 'a wide zbase32 input fails' );
	like( $zwhy, qr/above 255/, 'and the reason says so' );

	my ( $a, $awhy ) = reader( 'decode_armor', "\x{263A}" );
	is( $a, undef, 'a wide armored text fails' );
	like( $awhy, qr/above 255/, 'and the reason says so' );
};

subtest 'wkd_hash lowercases the ASCII letters alone' => sub {
	# lc reads a byte above 127 as Latin-1 under the feature set
	# of the module, so it rewrites the bytes of a UTF-8 local
	# part: c3 becomes e3. gpg(1) lowercases the ASCII letters
	# only, so lc would publish a non-ASCII address at a path
	# that gpg never asks for.
	my $utf8 = "w\xc3\x84\xc2\x85z";
	my $ascii_lowered = $utf8 =~ tr/A-Z/a-z/r;

	is(
		$PGP->wkd_hash($utf8),
		$PGP->zbase32( Digest::SHA::sha1($ascii_lowered) ),
		'a UTF-8 local part keeps its bytes above 127'
	);

	# The ASCII case still folds.
	is(
		$PGP->wkd_hash("W\xc3\x84\xc2\x85Z"),
		$PGP->wkd_hash($utf8),
		'and the ASCII letters still fold'
	);
};

subtest 'fingerprint bounds the packet body' => sub {
	# The digest writes the body length in two octets, so a longer
	# body has no version 4 fingerprint. pack wraps the value with
	# no warning, so without the bound the method would answer
	# with a confident wrong fingerprint over a wrapped length.
	my $over = "\x04" . ( 'A' x 69999 );
	my $packet = chr(0x9A) . pack( 'N', length $over ) . $over;

	my ( $got, $reason ) = reader( 'fingerprint', $packet );
	is( $got, undef, 'a body above 65535 bytes fails' );
	like( $reason, qr/holds at most 65535/, 'and the reason names the bound' );

	# The bound itself must still answer, so the guard is not off
	# by one.
	my $at = "\x04" . ( 'A' x ( 0xFFFF - 1 ) );
	ok(
		defined $PGP->fingerprint(
			chr(0x9A) . pack( 'N', length $at ) . $at
		),
		'a body of exactly 65535 bytes still answers'
	);

	is( Fugu::OpenPGP::MAX_PACKET_BODY(), 0xFFFF,
		'MAX_PACKET_BODY is the two-octet ceiling' );
};

subtest 'decode_armor reads a body that a mailer padded' => sub {
	# base64 ignores whitespace between the groups, and the
	# delimiter patterns tolerate trailing padding, so the body
	# must not be stricter than they are.
	my $text = slurp('openpgp-ed25519.asc');
	my $padded = join "\n",
	    map { /\A-----|\A\z/ ? $_ : "$_   " } split /\n/, $text;

	my ( $binary, $reason ) = reader( 'decode_armor', $padded );
	ok( defined $binary, 'a padded body decodes' ) or diag($reason);
	is(
		$PGP->fingerprint($binary),
		$FIXTURE{'openpgp-ed25519.asc'}{fingerprint},
		'and the padding changes no fingerprint'
	);

	# A tab is the other padding that a mailer leaves.
	my $tabbed = join "\n",
	    map { /\A-----|\A\z/ ? $_ : "$_\t" } split /\n/, $text;
	ok( defined $PGP->decode_armor($tabbed),
		'a tab-padded body decodes' );

	# The trim names the space and the tab, and nothing else. \s
	# would also strip 0x0B, 0x0C, 0x85 and 0xA0, and gpg(1)
	# rejects a body line that holds any of them with "invalid
	# radix64 character". A trim on \s would therefore accept a
	# block that gpg(1) rejects, against LIB-OPENPGP-5.
	for my $byte ( "\x0B", "\x0C", "\x85", "\xA0" ) {
		my $padded = join "\n",
		    map { /\A-----|\A\z/ ? $_ : "$_$byte" }
		    split /\n/, $text;
		is(
			$PGP->decode_armor($padded),
			undef,
			sprintf 'a body line padded with %02x fails',
			ord $byte
		);
	}
};

subtest 'decode_armor holds the base64 padding to the end' => sub {
	# The padding of base64 ends the data, and decode_base64
	# drops every byte after it. A line with interior padding
	# therefore decodes to a truncated key, and an attacker can
	# craft a checksum line that agrees with the truncation.
	# gpg(1) rejects such a block with a CRC error.
	my $text = slurp('openpgp-ed25519.asc');
	my ($block) = $text =~ /BLOCK-----\n\n(.*?)\n=/s;
	my @lines = split /\n/, $block;

	my $first = $lines[0];
	$first =~ s/.\z/=/;

	my $crafted =
	      "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n$first\n"
	    . join( "\n", @lines[ 1 .. $#lines ] )
	    . "\n=abcd\n-----END PGP PUBLIC KEY BLOCK-----\n";

	my ( $binary, $reason ) = reader( 'decode_armor', $crafted );
	is( $binary, undef, 'interior padding fails' );
	like( $reason, qr/before the last one holds padding/,
		'and the reason names the fault, not the checksum' );

	# Both real keys must still decode. The RSA fixture carries
	# padding on its last body line, so it drives the accept side
	# of the rule. The Ed25519 fixture ends on a whole group, so
	# it drives the case with no padding at all.
	for my $name ( sort keys %FIXTURE ) {
		is(
			$PGP->fingerprint(
				$PGP->decode_armor( slurp($name) )
			),
			$FIXTURE{$name}{fingerprint},
			"$name still decodes with padding on its last line"
		);
	}
};

subtest 'decode_armor bounds the input size' => sub {
	my $huge =
	      "-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n"
	    . encode_base64( 'x' x ( 2 * 1024 * 1024 ) )
	    . "=abcd\n-----END PGP PUBLIC KEY BLOCK-----\n";

	my ( $binary, $reason ) = reader( 'decode_armor', $huge );
	is( $binary, undef, 'a block above the bound fails' );
	like( $reason, qr/larger than/, 'and the reason says so' );
};


# --- the command part -----------------------------------------------------

my $gpg = Fugu::Process->find_command( undef, 'gpg2', 'gpg' );

# write_file($path, $text):
#	Write a fixture file, and answer the path.
sub write_file ( $path, $text )
{
	open my $fh, '>', $path or die "Cannot write $path: $!";
	binmode $fh;
	print {$fh} $text;
	close $fh or die "Cannot close $path: $!";

	return $path;
}

# read_file($path):
#	The bytes of a file that a method wrote. Each half of a key and
#	each signature is a file now, so a subtest reads the text back.
sub read_file ($path)
{
	open my $fh, '<', $path or die "Cannot read $path: $!";
	binmode $fh;
	local $/ = undef;
	my $text = <$fh>;
	close $fh;

	return $text // '';
}

# gpg_colons($path):
#	The colon form of a public half, from gpg(1) itself. The check
#	drives the command directly, so no assertion rests on the
#	module that it checks. The home holds no name of the module, so
#	the leak subtest reads the homes of the module alone.
sub gpg_colons ($path)
{
	my $home = tempdir( 'check-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );
	my %env  = (
		PATH      => $ENV{PATH} // '',
		HOME      => $home,
		GNUPGHOME => $home,
		LC_ALL    => 'C',
	);

	my $result = Fugu::Process->run(
		cmd => [
			$gpg,            '--batch',
			'--no-tty',      '--quiet',
			'--homedir',     $home,
			'--with-colons', '--import-options',
			'show-only',     '--import',
			'--',            $path
		],
		env => \%env
	);
	die "Cannot read $path: $result->{stderr}" unless $result->{success};

	Fugu::Process->run(
		cmd => [
			$gpg =~ s{[^/]+\z}{gpgconf}r, '--homedir',
			$home,                        '--kill',
			'gpg-agent'
		],
		env => \%env
	);
	File::Path::remove_tree($home);

	return $result->{stdout};
}

# gpg_fingerprint($path):
#	The fingerprint of a public half, from gpg(1) itself. Field 10
#	of the fpr record holds it.
sub gpg_fingerprint ($path)
{
	for my $line ( split /\n/, gpg_colons($path) ) {
		my @field = split /:/, $line, -1;
		return $field[9] if @field && $field[0] eq 'fpr';
	}

	return;
}

# homes():
#	Every temporary home of this process under the temporary
#	directory of the system. The parent class writes the process id
#	in the name, so the pattern names the homes of this test alone.
#	Each run makes one home and removes it, so the list must stay
#	empty.
sub homes ()
{
	# glob answers one name at a time in scalar context, so the
	# list assignment stands here: the caller counts the homes.
	my @home = glob File::Spec->tmpdir . "/.fugu-signer.$$.*";

	return @home;
}

# agents():
#	Every gpg-agent process that names a home of this test. A host
#	with no ps(1) gives the empty list, so the check is a floor.
sub agents ()
{
	open my $fh, '-|', 'ps', '-axww', '-o', 'args=' or return ();
	my @line = grep { /gpg-agent/ && /\Q.fugu-signer.$$.\E/ } <$fh>;
	close $fh;

	return @line;
}

subtest 'the module follows the signer shape' => sub {
	isa_ok( $PGP, 'Fugu::Signer' );

	ok( Fugu::OpenPGP->can('generate'), 'generate exists' );
	ok( Fugu::OpenPGP->can('sign'),     'sign exists' );
	ok( Fugu::OpenPGP->can('verify'),   'verify exists' );

	# The parent holds the command resolution, so the module holds
	# no resolver of its own.
	ok( !Fugu::OpenPGP->can('_find_command'),
		'the module holds no resolver of its own' );

	# The old names took each half as text, and LIB-SIGNER-3 takes
	# each half as a path. No shim keeps the old shape.
	ok( !Fugu::OpenPGP->can('sign_detached'),
		'sign_detached is gone' );
	ok( !Fugu::OpenPGP->can('verify_detached'),
		'verify_detached is gone' );

	# The parent names the command through the label and the
	# search list of the subclass.
	is( $PGP->_command_label, 'gpg', 'the label names the command' );
	is_deeply(
		[ $PGP->_command_defaults ],
		[ 'gpg2', 'gpg' ],
		'and the search list names gpg2 first'
	);
};

subtest 'the module raises the timeout of the parent' => sub {

	# LIB-OPENPGP-12 holds the default at 60 seconds, over the
	# parent default of 30, because a key generation waits for
	# entropy. The constructor runs no process, so the subtest
	# runs where gpg(1) is absent.
	is( Fugu::OpenPGP->new->{timeout},
		60, 'the default timeout is 60 seconds' );
	is( Fugu::OpenPGP->new( timeout => 5 )->{timeout},
		5, 'and the caller names its own' );
};

subtest 'the command resolves through Fugu::Process' => sub {

	# A host that kept gpg for version 1 carries version 2 under
	# the name gpg2, and the command part needs version 2. A PATH
	# that holds both names must therefore give gpg2.
	my $bindir = tempdir( 'path-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );
	for my $name (qw(gpg gpg2)) {
		my $stub = write_file( "$bindir/$name", "#!/bin/sh\nexit 0\n" );
		chmod 0755, $stub or die "Cannot chmod $stub: $!";
	}

	{
		local $ENV{PATH} = $bindir;
		is( Fugu::OpenPGP->new->command,
			"$bindir/gpg2", 'a PATH with both names gives gpg2' );
	}

	local $ENV{PATH} = '';
	like( Fugu::OpenPGP->new->error, qr/no executable gpg command: gpg2, gpg/,
		'and the reason names the search list in that order' );
};

subtest 'the object answers cleanly for an absent command' => sub {

	# An absent gpg(1) is an install problem, and new must never
	# die for one. Each command method then answers undef, and it
	# reports the absent command through command_absent.
	my $pgp = Fugu::OpenPGP->new( command => "$WORK/no-such-gpg" );

	is( $pgp->is_available,   0,     'is_available answers 0' );
	is( $pgp->command_absent, 1,     'command_absent answers 1' );
	is( $pgp->command,        undef, 'command stays undef' );
	like( $pgp->error, qr/no executable gpg command/,
		'error names the reason' );

	my $dir  = tempdir( 'absent-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );
	my $file = write_file( "$dir/body.txt", "the body\n" );
	my $key  = write_file( "$dir/key.asc",  "no key here\n" );

	is(
		$pgp->generate(
			email  => 'a@example.org',
			public => "$dir/made.asc",
			secret => "$dir/made.sec"
		),
		undef,
		'generate answers undef'
	);
	is( $pgp->command_absent, 1, 'and command_absent answers 1' );

	is(
		$pgp->sign(
			secret    => $key,
			file      => $file,
			signature => "$dir/body.asc"
		),
		undef,
		'sign answers undef'
	);
	is( $pgp->command_absent, 1, 'and command_absent answers 1' );

	is(
		$pgp->verify(
			keys      => [$key],
			file      => $file,
			signature => $key
		),
		undef,
		'verify answers undef'
	);
	is( $pgp->command_absent, 1, 'and command_absent answers 1' );

	# The walk stops at the first key, because every later key
	# would fail the same way.
	like( $pgp->error, qr/\Ano executable gpg command/,
		'and the walk reports that one reason alone' );

	is( $pgp->expiry( public => $key ), undef, 'expiry answers undef' );
	is( $pgp->command_absent, 1, 'and command_absent answers 1' );

	ok( !-e "$dir/made.asc" && !-e "$dir/made.sec",
		'no call wrote a half' );
};

subtest 'each command method dies for an absent argument' => sub {
	my $pgp = Fugu::OpenPGP->new;

	ok( !eval { $pgp->generate( public => 'p', secret => 's' ); 1 },
		'generate dies for an absent email' );
	like( $@, qr/email/, 'the message names email' );

	ok(
		!eval {
			$pgp->generate( email => 'a@example.org', public => 'p' );
			1;
		},
		'generate dies for an absent secret'
	);
	like( $@, qr/secret/, 'the message names secret' );

	ok( !eval { $pgp->sign( secret => 's', file => 'f' ); 1 },
		'sign dies for an absent signature' );
	like( $@, qr/signature/, 'the message names signature' );

	ok( !eval { $pgp->verify( file => 'f', signature => 's' ); 1 },
		'verify dies for an absent keys' );
	like( $@, qr/keys/, 'the message names keys' );

	ok(
		!eval {
			$pgp->verify( keys => [], file => 'f', signature => 's' );
			1;
		},
		'verify dies for an empty keys'
	);
	like( $@, qr/non-empty/, 'the message names the empty list' );

	ok( !eval { $pgp->expiry; 1 }, 'expiry dies for an absent public' );
	like( $@, qr/public/, 'the message names public' );
};

subtest 'a command method refuses a path that is no plain file' => sub {

	# LIB-SIGNER-7 refuses an input path that is no plain file,
	# before the command runs. The refusal needs no gpg(1).
	my $pgp  = Fugu::OpenPGP->new;
	my $dir  = tempdir( 'input-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );
	my $file = write_file( "$dir/body.txt", "the body\n" );

	is(
		$pgp->sign(
			secret    => "$dir/absent.sec",
			file      => $file,
			signature => "$dir/body.asc"
		),
		undef,
		'sign refuses an absent private half'
	);
	like( $pgp->error, qr/\Qnot a plain file: $dir\/absent.sec\E/,
		'and error names the path' );
	is( $pgp->command_absent, 0, 'a refusal is no absent command' );

	is( $pgp->expiry( public => "$dir/absent.asc" ),
		undef, 'expiry refuses an absent public half' );
	like( $pgp->error, qr/not a plain file/, 'and error says so' );
};

subtest 'generate refuses an email that would forge a user id' => sub {

	# The generator writes "<$email>" as the user id. An angle
	# bracket, a newline or a NUL byte would close that user id
	# and open a second one, so the key would carry an address
	# that the caller never named. The refusal stands before the
	# command runs, so no gpg(1) is needed here.
	my $pgp = Fugu::OpenPGP->new;
	my $dir = tempdir( 'forge-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );

	my @case = (
		[ 'an angle bracket',  'a<b@example.org' ],
		[ 'a closing bracket', 'a>b@example.org' ],
		[ 'a newline',         "a\@example.org\nuid two" ],
		[ 'a carriage return', "a\@example.org\ruid two" ],
		[ 'a NUL byte',        "a\@example.org\0uid two" ],
		[ 'an empty email',    '' ],
		[ 'a wide email',      "caf\x{263A}\@example.org" ],
	);

	for my $case (@case) {
		my ( $name, $email ) = @$case;
		is(
			$pgp->generate(
				email  => $email,
				public => "$dir/key.asc",
				secret => "$dir/key.sec"
			),
			undef,
			"$name fails"
		);
		like( $pgp->error, qr/holds <|empty|above 255/,
			'and error names the fault' );
	}

	ok( !-e "$dir/key.asc", 'and no refused call wrote a half' );
};

subtest 'generate refuses an expiry that names no future second' => sub {
	my $pgp = Fugu::OpenPGP->new;
	my $dir = tempdir( 'expiry-XXXXXXXX', DIR => $WORK, CLEANUP => 1 );

	my @case = (
		[ 'a past expiry',      time() - 10 ],
		[ 'the current second', time() ],
		[ 'a fraction',         '1893456000.5' ],
		[ 'a word',             'tomorrow' ],
	);

	for my $case (@case) {
		my ( $name, $expires ) = @$case;
		is(
			$pgp->generate(
				email   => 'a@example.org',
				expires => $expires,
				public  => "$dir/key.asc",
				secret  => "$dir/key.sec"
			),
			undef,
			"$name fails"
		);
		like( $pgp->error, qr/whole number|after the current time/,
			'and error names the fault' );
	}

	ok( !-e "$dir/key.asc", 'and no refused call wrote a half' );
};

# The fixtures of the command part. The test generates each key, so
# the tree carries no secret half. One generation serves every
# subtest below, because a key takes a second of entropy.
my $KEYDIR = "$WORK/keys";
mkdir $KEYDIR or die "Cannot make $KEYDIR: $!";

my $EXPIRES = time() + 86_400 * 30;
my %HALF    = (
	signer => { email => 'signer@example.org' },
	other  => { email => 'other@example.org' },
	dated  => { email => 'dated@example.org', expires => $EXPIRES },
);
my ( $MESSAGE, $SIGNATURE );

if ( defined $gpg ) {
	my $pgp = Fugu::OpenPGP->new;

	for my $name ( sort keys %HALF ) {
		my $half = $HALF{$name};
		$half->{public} = "$KEYDIR/$name.asc";
		$half->{secret} = "$KEYDIR/$name.sec";

		$pgp->generate(%$half)
		    or die "Cannot generate the $name key: " . $pgp->error;
	}

	$MESSAGE   = write_file( "$WORK/message.txt", "the fixture body\n" );
	$SIGNATURE = "$WORK/message.asc";
	$pgp->sign(
		secret    => $HALF{signer}{secret},
		file      => $MESSAGE,
		signature => $SIGNATURE
	) or die 'Cannot sign the message: ' . $pgp->error;
}

subtest 'generate writes the two halves as files' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	my ( $public, $secret ) = @{ $HALF{signer} }{qw(public secret)};

	ok( -f $public, 'the public half exists' );
	ok( -f $secret, 'the private half exists' );

	like( read_file($public), qr/\A-----BEGIN PGP PUBLIC KEY BLOCK-----/,
		'the public half is an armored public key block' );
	like( read_file($secret), qr/\A-----BEGIN PGP PRIVATE KEY BLOCK-----/,
		'the private half is an armored private key block' );

	# The private half must hold no group mode and no other mode.
	is( sprintf( '%04o', ( stat $secret )[2] & 07777 ),
		'0600', 'the private half is owner-only' );

	# The parent makes the private directory beside the private
	# half, and it removes the tree on every exit.
	is_deeply( [ glob "$KEYDIR/.fugu-signer.*" ],
		[], 'and the private directory is gone' );

	# The byte reader and gpg(1) must answer one fingerprint. A
	# site publishes the one that the reader gives.
	my $binary = $PGP->decode_armor( read_file($public) );
	is( $PGP->fingerprint($binary), gpg_fingerprint($public),
		'the byte reader gives the fingerprint of gpg(1)' );

	# The parent refuses a path that exists, so one call never
	# overwrites a key.
	my $pgp = Fugu::OpenPGP->new;
	is(
		$pgp->generate(
			email  => 'again@example.org',
			public => $public,
			secret => $secret
		),
		undef,
		'a second generate over one path returns undef'
	);
	like( $pgp->error, qr/\Qthe path exists: $public\E/,
		'error names the path that exists' );
	is( $pgp->command_absent, 0, 'a refusal is no absent command' );
};

subtest 'generate makes the encryption subkey' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	# FuguWeb publishes the key, and a correspondent encrypts to
	# the subkey. A primary key alone takes no encrypted mail.
	my $colons = gpg_colons( $HALF{signer}{public} );

	my @sub = grep { /\Asub:/ } split /\n/, $colons;
	is( scalar @sub, 1, 'the public half holds one subkey' );
	like( $sub[0], qr/:cv25519:/, 'and the subkey is a Curve25519 key' );

	my ($flags) = ( split /:/, $sub[0], -1 )[11];
	is( $flags, 'e', 'and it holds the encryption use alone' );

	# LIB-OPENPGP-8 gives the key and the subkey the expiry that
	# the caller named, and no expiry when the caller names none.
	# Field 7 of the sub line holds that expiry, and an empty
	# field 7 means no expiry. The caller named no expiry here.
	is( ( split /:/, $sub[0], -1 )[6],
		'', 'and it holds no expiry, because the caller named none' );

	my @dated =
	    grep { /\Asub:/ } split /\n/, gpg_colons( $HALF{dated}{public} );
	is( scalar @dated, 1, 'the dated key holds one subkey' );

	# A subkey with no expiry outlives the primary key, and it
	# takes mail after the owner retired that key.
	my $expiry = ( split /:/, $dated[0], -1 )[6];
	like( $expiry, qr/\A[0-9]+\z/, 'and that subkey holds an expiry' );

	# gpg(1) writes an expiry as a duration from the creation time
	# of a key, and not as an absolute second. --quick-add-key
	# samples the creation time and the duration in two steps, so a
	# second boundary between them moves the subkey expiry one
	# second early. The primary key holds one creation time in one
	# run, so it never moves. This window holds that one second,
	# and a subkey with another expiry falls outside it.
	cmp_ok( abs( $expiry - $EXPIRES ),
		'<=', 2, 'and it expires with its primary key' );

	my ($pub) = grep { /\Apub:/ } split /\n/, $colons;
	like( $pub, qr/:ed25519:/, 'the primary key is an Ed25519 key' );

	my @uid = grep { /\Auid:/ } split /\n/, $colons;
	is( scalar @uid, 1, 'the key holds one user id' );
	like( $uid[0], qr/:<signer\@example\.org>:/,
		'and the user id holds the email alone' );
};

subtest 'expiry tells no expiry from an expiry' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	my $pgp = Fugu::OpenPGP->new;

	is( $pgp->expiry( public => $HALF{signer}{public} ),
		0, 'a key with no expiry answers 0' );
	is( $pgp->error, undef, 'and the answer is no failure' );

	# The ISO form of the generator lands on the exact second. The
	# seconds=N form of gpg(1) is off by one, and this comparison
	# catches that.
	is( $pgp->expiry( public => $HALF{dated}{public} ),
		$EXPIRES, 'a dated key answers the exact second' );
	is( $pgp->error, undef, 'and the answer is no failure' );

	# A file that is no key is the third answer: undef with the
	# reason. A caller thus tells "no expiry" from "cannot read".
	my $body = write_file( "$WORK/no-key.asc", "the body of no key\n" );
	is( $pgp->expiry( public => $body ), undef, 'a file that is no key fails' );
	like( $pgp->error, qr/no valid OpenPGP data/,
		'and the reason comes from gpg(1)' );
};

subtest 'sign writes a signature that verify takes' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	my $pgp = Fugu::OpenPGP->new;

	ok( -f $SIGNATURE, 'the signer wrote the signature file' );
	like( read_file($SIGNATURE), qr/\A-----BEGIN PGP SIGNATURE-----/,
		'and it holds an armored signature block' );

	is(
		$pgp->verify(
			keys      => [ $HALF{signer}{public} ],
			file      => $MESSAGE,
			signature => $SIGNATURE
		),
		$HALF{signer}{public},
		'verify answers the key that verified the signature'
	) or diag( $pgp->error );
	is( $pgp->error,          undef, 'error is undef after a success' );
	is( $pgp->command_absent, 0,     'and command_absent answers 0' );

	# A rotation signs one manifest again, so a second sign over
	# one signature path replaces the file, per LIB-SIGNER-5.
	is(
		$pgp->sign(
			secret    => $HALF{signer}{secret},
			file      => $MESSAGE,
			signature => $SIGNATURE
		),
		1,
		'a second sign over one path answers 1'
	) or diag( $pgp->error );
	is(
		$pgp->verify(
			keys      => [ $HALF{signer}{public} ],
			file      => $MESSAGE,
			signature => $SIGNATURE
		),
		$HALF{signer}{public},
		'and verify takes the signature that replaced it'
	) or diag( $pgp->error );
};

subtest 'verify walks the key set in trust order' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	# The walk pins one key in one run, and it answers the key that
	# verified. A caller therefore learns that a release moved to
	# the next key.
	my $pgp = Fugu::OpenPGP->new;

	is(
		$pgp->verify(
			keys =>
			    [ $HALF{other}{public}, $HALF{signer}{public} ],
			file      => $MESSAGE,
			signature => $SIGNATURE
		),
		$HALF{signer}{public},
		'a later key of the set verifies the signature'
	) or diag( $pgp->error );

	# The reason of the first key must not survive a call that
	# verified.
	is( $pgp->error, undef, 'and error holds no reason of the first key' );
};

subtest 'verify fails for a signature of another key' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	# The home takes the one public half of the key of the walk, so
	# the signature of another key has no key to check against.
	my $pgp = Fugu::OpenPGP->new;

	is(
		$pgp->verify(
			keys      => [ $HALF{other}{public} ],
			file      => $MESSAGE,
			signature => $SIGNATURE
		),
		undef,
		'a signature of another key fails'
	);
	like( $pgp->error, qr/\Q$MESSAGE: no key verified the signature\E/,
		'error names the file' );
	like( $pgp->error,
		qr/\Q$HALF{other}{public}\E: [^\n]*No public key/,
		'and it names the key with its own reason' );
	is( $pgp->command_absent, 0, 'a bad signature is no absent command' );
};

subtest 'verify fails for a tampered file' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	my $pgp      = Fugu::OpenPGP->new;
	my $tampered = write_file( "$WORK/tampered.txt", "the other body\n" );

	is(
		$pgp->verify(
			keys      => [ $HALF{signer}{public} ],
			file      => $tampered,
			signature => $SIGNATURE
		),
		undef,
		'a tampered file fails'
	);

	# gpg(1) writes "Signature made ..." first and the fault last,
	# so the reason must come from the last line of the
	# diagnostic.
	like( $pgp->error, qr/BAD signature/, 'and the reason names the fault' );
};

subtest 'the runs leave no temporary home and no agent' => sub {
	plan skip_all => 'gpg(1) not available' unless defined $gpg;

	# Every subtest above ran its commands already. A home that a
	# run left behind carries a secret half, and an agent that
	# outlives its home leaks a process.
	is( scalar homes(), 0, 'no temporary home stays behind' )
	    or diag( join ', ', homes() );

	# gpgconf(1) stops the agent at once, and the wait below is
	# the margin of a loaded host. An agent that no kill stopped
	# outlives the wait: gpg-agent notices its lost home seconds
	# later, and it exits then.
	for ( 1 .. 5 ) {
		last unless agents();
		select undef, undef, undef, 0.2;
	}
	is( scalar agents(), 0, 'no gpg-agent stays behind' )
	    or diag( join '', agents() );
};

done_testing();
