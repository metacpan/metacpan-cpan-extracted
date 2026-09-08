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

use v5.36;

package Fugu::OpenPGP;
our $VERSION = '0.3.0';

use Digest::SHA  ();
use MIME::Base64 qw(decode_base64);

# Fugu::OpenPGP - read an armored OpenPGP public key as bytes.
#
# The module decodes the armor of RFC 4880. It computes the v4
# fingerprint of a public key packet, and the Web Key Directory hash
# of an email local part. It runs no command, so a caller needs no
# gpg(1). It holds class methods only, because it holds no state.
#
# Every recoverable failure returns undef, and the reason goes to the
# second return value in list context. The module never logs, and it
# never dies for bad input: a key file comes from outside, so bad
# bytes are data and not a programming error.
#
# Every public method needs bytes. Each one rejects a string that
# holds a code point above 255, because Digest::SHA dies on such a
# string and unpack 'C*' would take the low byte of each character.
#
# The module reads a public key only. It holds no private key, it
# decrypts nothing, and it verifies no signature. gpg(1) owns those
# acts.

# The CRC-24 generator polynomial and initial value of RFC 4880
# section 6.1. The armor checksum line holds this value over the
# decoded bytes.
use constant CRC24_INIT => 0x00B7_04CE;
use constant CRC24_POLY => 0x0186_4CFB;

# The z-base-32 alphabet of the Web Key Directory. It is not the
# RFC 4648 alphabet: the order differs, so the same digest gives a
# different string. A caller that swaps the alphabet publishes a key
# at a URL that gpg(1) never asks for.
use constant ZBASE32_ALPHABET => 'ybndrfg8ejkmcpqxot1uwisza345h769';

# The tag of a public key packet, per RFC 4880 section 4.3.
use constant PACKET_PUBLIC_KEY => 6;

# The largest public key packet body that a version 4 fingerprint can
# hold. The digest writes the length in two octets, per RFC 4880
# section 12.2, so a longer body has no fingerprint of this version.
use constant MAX_PACKET_BODY => 0xFFFF;

# The size bound of an armored block, 1 MiB. A public key of a person
# holds a few kilobytes. A caller that names a disk image by mistake
# gets a clean failure, not a decode of 500 MB.
use constant MAX_ARMOR_SIZE => 1_048_576;

# Fugu::OpenPGP->decode_armor($text):
#	The binary form of an armored block, or undef with the reason.
#
#	The method reads the two delimiter lines and skips the armor
#	headers. It decodes the base64 body, and it compares the
#	CRC-24 checksum line against the decoded bytes.
#
#	The checksum is not decoration. A decoder that skips it
#	accepts a truncated key, and a truncated key gives a
#	fingerprint of its own.
#
#	The method returns the bytes in scalar context. In list
#	context it returns the bytes and undef on a success, and undef
#	and the reason on a failure.
sub decode_armor ( $class, $text )
{
	return _fail('the armored text is undef') unless defined $text;
	return _fail( 'the armored text holds a character above 255, '
		    . 'and this method needs bytes' )
	    if _wide($text);

	if ( length($text) > MAX_ARMOR_SIZE ) {
		return _fail(
			sprintf 'the armored text is larger than %d bytes',
			MAX_ARMOR_SIZE );
	}

	# Armor is text, so a producer can write either line ending. A
	# block that travelled through email holds CRLF. One
	# normalization here serves the delimiters and the body
	# together. The signature gives a copy, so the caller keeps
	# its own string.
	$text =~ s/\r\n/\n/g;

	# The delimiters name the block type, and both lines must name
	# the same type. A begin line of one type with an end line of
	# another is a spliced file.
	my ($type) = $text =~ /^-----BEGIN PGP ([A-Z0-9 ]+)-----[ \t]*$/m;
	return _fail('no BEGIN PGP delimiter line') unless defined $type;

	my ($end) = $text =~ /^-----END PGP ([A-Z0-9 ]+)-----[ \t]*$/m;
	return _fail('no END PGP delimiter line') unless defined $end;
	return _fail("the delimiters name two block types: $type and $end")
	    unless $type eq $end;

	my ($block) =
	    $text =~ /^-----BEGIN \QPGP $type\E-----[ \t]*\n(.*?)^-----END/ms;
	return _fail('no text between the delimiter lines')
	    unless defined $block;

	# The normalization above removed every CRLF, so no line holds
	# a trailing carriage return. A mailer that pads a line leaves
	# a space or a tab instead, and the delimiter patterns
	# tolerate the same two. The trim therefore names those two
	# and nothing else.
	#
	# \s must not stand here. Under the feature set of this file
	# it also matches 0x0B, 0x0C, 0x85 and 0xA0, and gpg(1)
	# rejects a body line that holds any of them with "invalid
	# radix64 character". A trim on \s would strip the byte and
	# accept a block that gpg(1) rejects.
	#
	# The trim touches the two ends of a line only. A line with
	# interior whitespace stays a failure, although gpg(1) reads
	# one. This method is stricter there on purpose: it validates
	# a key that a site publishes.
	my @lines = map { s/\A[ \t]+|[ \t]+\z//gr } split /\n/, $block, -1;

	# An armor header is "Key: value" or a bare "Key:", and a
	# blank line ends the header section. RFC 4880 makes that
	# blank line necessary, and gpg(1) enforces it: a block
	# without it fails with "invalid armor header". This method
	# must not accept what gpg(1) rejects, because a site would
	# then publish a key that no consumer can import.
	#
	# A header holds "Key: value" or a bare "Key:". gpg(1) reads
	# an empty value, and it rejects a value with no space after
	# the colon: "Comment:nospace" fails with "invalid armor
	# header". The pattern therefore needs the space whenever a
	# value follows. The trim above already removed a trailing
	# space, so "Key: " arrives here as "Key:".
	while ( @lines && $lines[0] =~ /\A[A-Za-z][A-Za-z0-9-]*:(?: .*)?\z/ ) {
		shift @lines;
	}

	# The trim above removed the space and the tab, so a blank
	# line is an empty line here. The test must not read \S: that
	# class treats 0x85 and 0xA0 as content on one build and not
	# on another, and a length test says the same thing on every
	# build.
	unless ( @lines && !length $lines[0] ) {
		return _fail('no blank line ends the armor header section');
	}
	shift @lines;

	# The checksum line starts with one '=' and holds four base64
	# characters. It is the last non-blank line of the body.
	my ( @body, $checksum );
	for my $line (@lines) {
		next unless length $line;
		if ( $line =~ /\A=([A-Za-z0-9+\/]{4})\z/ ) {
			return _fail('more than one checksum line')
			    if defined $checksum;
			$checksum = $1;
			next;
		}
		return _fail('a body line follows the checksum line')
		    if defined $checksum;

		# The padding of base64 ends the data, and
		# decode_base64 drops every byte after it. A line with
		# interior padding would therefore decode to a
		# truncated key, and a crafted checksum line would
		# still agree with the truncation. gpg(1) rejects such
		# a block, so this method must reject it too. The
		# padding may sit at the end of the last body line
		# only, and the loop tests that after it reads them
		# all.
		return _fail("not a base64 body line: $line")
		    unless $line =~ m{\A[A-Za-z0-9+/]+={0,2}\z};
		push @body, $line;
	}

	return _fail('no base64 body')   unless @body;
	return _fail('no checksum line') unless defined $checksum;

	# Only the last body line may carry the padding.
	for my $i ( 0 .. $#body - 1 ) {
		next unless $body[$i] =~ /=/;
		return _fail(
			      'a base64 body line before the last one holds '
			    . "padding: $body[$i]" );
	}

	# base64 carries four characters for each three bytes, so the
	# joined body must hold a whole number of groups.
	# decode_base64 drops a trailing partial group without a word.
	# One extra character would therefore give the same bytes and
	# the same checksum, and gpg(1) rejects such a block.
	my $joined = join '', @body;
	if ( length($joined) % 4 != 0 ) {
		return _fail(
			sprintf 'the base64 body holds %d characters, '
			    . 'which is not a whole number of groups',
			length $joined
		);
	}

	my $binary = decode_base64($joined);
	return _fail('the base64 body decodes to no bytes')
	    unless length $binary;

	# The pattern above fixes the checksum line at four base64
	# characters. Four characters always decode to three bytes, so
	# no length test is needed here.
	my $want = decode_base64($checksum);

	my $got = pack 'N', _crc24($binary);
	$got = substr $got, 1, 3;    # the low three bytes, big endian
	unless ( $got eq $want ) {
		return _fail(
			sprintf 'checksum mismatch: the body gives %s, '
			    . 'and the line holds %s',
			unpack( 'H*', $got ),
			unpack( 'H*', $want ) );
	}

	return wantarray ? ( $binary, undef ) : $binary;
}

# Fugu::OpenPGP->fingerprint($binary):
#	The v4 fingerprint of the first public key packet, in
#	upper-case hexadecimal with no separator, or undef with the
#	reason.
#
#	The fingerprint is the SHA-1 of the byte 0x99, the two-byte
#	length of the packet body, and that body, per RFC 4880 section
#	12.2. The constant 0x99 never changes with the packet header
#	that the file holds: a key in the new packet format gets the
#	same fingerprint as the same key in the old format. The method
#	therefore reads the length from the header and writes the
#	length again.
sub fingerprint ( $class, $binary )
{
	return _fail('the binary form is undef') unless defined $binary;
	return _fail( 'the binary form holds a character above 255, '
		    . 'and this method needs bytes' )
	    if _wide($binary);

	my ( $tag, $body, $reason ) = _first_packet($binary);
	return _fail($reason) unless defined $tag;

	return _fail("the first packet is tag $tag, and not a public key")
	    unless $tag == PACKET_PUBLIC_KEY;

	my $version = length($body) ? ord substr( $body, 0, 1 ) : undef;
	return _fail('the public key packet is empty') unless defined $version;
	return _fail("the public key packet is version $version, and not 4")
	    unless $version == 4;

	# The digest writes the body length in two octets, so a longer
	# body has no version 4 fingerprint. pack would wrap the value
	# without a warning, and the method would then answer with a
	# confident wrong fingerprint.
	if ( length($body) > MAX_PACKET_BODY ) {
		return _fail(
			sprintf 'the public key packet body is %d bytes, '
			    . 'and a version 4 fingerprint holds at most %d',
			length($body), MAX_PACKET_BODY
		);
	}

	my $hex =
	    Digest::SHA::sha1_hex( "\x99" . pack( 'n', length $body ) . $body );

	return wantarray ? ( uc $hex, undef ) : uc $hex;
}

# Fugu::OpenPGP->wkd_hash($local):
#	The Web Key Directory hash of an email local part.
#
#	The hash is the z-base-32 form of the SHA-1 of the local part
#	in lower case. gpg --locate-keys asks for
#	.well-known/openpgpkey/hu/<hash>, so the answer decides the
#	publication path. The method lowercases the part itself: the
#	draft states the rule, and a caller that lowercases twice gets
#	the same answer.
sub wkd_hash ( $class, $local )
{
	return _fail('the local part is undef') unless defined $local;
	return _fail('the local part is empty') unless length $local;
	return _fail( 'the local part holds a character above 255, '
		    . 'and this method needs bytes' )
	    if _wide($local);

	# The lowercase step must touch the ASCII letters only. lc
	# reads a byte above 127 as Latin-1 under the feature set of
	# this file, so it rewrites the bytes of a UTF-8 local part:
	# c3 becomes e3. gpg(1) lowercases the ASCII letters only, so
	# lc would publish a non-ASCII address at a path that gpg
	# never asks for.
	my $lower = $local =~ tr/A-Z/a-z/r;

	my $hash = $class->zbase32( Digest::SHA::sha1($lower) );

	return wantarray ? ( $hash, undef ) : $hash;
}

# Fugu::OpenPGP->zbase32($bytes):
#	The z-base-32 form of the bytes. The encoding writes no
#	padding, and it emits one character for each five bits. A byte
#	count that is not a multiple of five therefore ends on a
#	partial group, and the low bits of that group are zero.
sub zbase32 ( $class, $bytes )
{
	return '' unless defined $bytes && length $bytes;

	# unpack 'C*' takes the low byte of each code point, so
	# character data would give a confident wrong answer: the
	# smiling face U+263A would encode as the colon. The method
	# needs bytes, and it says so.
	return _fail( 'the input holds a character above 255, '
		    . 'and this method needs bytes' )
	    if _wide($bytes);

	my @alphabet = split //, ZBASE32_ALPHABET;
	my ( $accumulator, $bits, $out ) = ( 0, 0, '' );

	for my $byte ( unpack 'C*', $bytes ) {
		$accumulator = ( $accumulator << 8 ) | $byte;
		$bits += 8;
		while ( $bits >= 5 ) {
			$bits -= 5;
			$out .= $alphabet[ ( $accumulator >> $bits ) & 0x1F ];
		}
	}

	$out .= $alphabet[ ( $accumulator << ( 5 - $bits ) ) & 0x1F ]
	    if $bits;

	return $out;
}

# _first_packet($binary):
#	The tag and the body of the first packet, or undef with the
#	reason as the third value.
#
#	RFC 4880 holds two packet header formats. The old format
#	writes the tag in bits 5 to 2 and the length type in bits 1
#	and 0. The new format writes the tag in bits 5 to 0, and the
#	length in one, two or five bytes.
#
#	An armored public key of gpg(1) uses the old format. Its
#	length type is 0 for a small key and 1 for a large one. The
#	method reads both formats, because a producer chooses
#	either.
sub _first_packet ($binary)
{
	return ( undef, undef, 'the binary form holds no packet header' )
	    unless length($binary) >= 2;

	my $first = ord substr $binary, 0, 1;
	return ( undef, undef, 'the packet header has no high bit set' )
	    unless $first & 0x80;

	my ( $tag, $length, $offset );

	if ( $first & 0x40 ) {

		# The new format. One length byte below 192, two bytes
		# up to 8383, and a five-byte form for anything above.
		$tag = $first & 0x3F;
		my $first_octet = ord substr $binary, 1, 1;
		if ( $first_octet < 192 ) {
			( $length, $offset ) = ( $first_octet, 2 );
		}
		elsif ( $first_octet < 224 ) {
			return ( undef, undef,
				'the two-byte length is truncated' )
			    unless length($binary) >= 3;
			my $second = ord substr $binary, 2, 1;
			$length =
			    ( ( $first_octet - 192 ) << 8 ) + $second + 192;
			$offset = 3;
		}
		elsif ( $first_octet == 255 ) {
			return ( undef, undef,
				'the five-byte length is truncated' )
			    unless length($binary) >= 6;
			$length = unpack 'N', substr $binary, 2, 4;
			$offset = 6;
		}
		else {
			return ( undef, undef,
				'a partial body length holds no whole packet' );
		}
	}
	else {
		# The old format.
		$tag = ( $first & 0x3C ) >> 2;
		my $type = $first & 0x03;
		if ( $type == 0 ) {
			( $length, $offset ) =
			    ( ord substr( $binary, 1, 1 ), 2 );
		}
		elsif ( $type == 1 ) {
			return ( undef, undef,
				'the two-byte length is truncated' )
			    unless length($binary) >= 3;
			$length = unpack 'n', substr $binary, 1, 2;
			$offset = 3;
		}
		elsif ( $type == 2 ) {
			return ( undef, undef,
				'the four-byte length is truncated' )
			    unless length($binary) >= 5;
			$length = unpack 'N', substr $binary, 1, 4;
			$offset = 5;
		}
		else {
			return ( undef, undef,
				'an indeterminate length holds no whole packet'
			);
		}
	}

	return ( undef, undef, 'the packet body is truncated' )
	    unless length($binary) >= $offset + $length;

	return ( $tag, substr( $binary, $offset, $length ), undef );
}

# _crc24($bytes):
#	The CRC-24 of RFC 4880 section 6.1, as an integer. The armor
#	checksum line holds the low three bytes, big endian.
sub _crc24 ($bytes)
{
	my $crc = CRC24_INIT;

	for my $byte ( unpack 'C*', $bytes ) {
		$crc ^= $byte << 16;
		for ( 1 .. 8 ) {
			$crc <<= 1;
			$crc ^= CRC24_POLY if $crc & 0x0100_0000;
		}
	}

	return $crc & 0x00FF_FFFF;
}

# _wide($text):
#	True when the string holds a code point above 255. Such a
#	string is character data and not bytes. Digest::SHA dies on
#	it with "Wide character in subroutine entry", and unpack 'C*'
#	takes the low byte of each character. The contract of this
#	module is a clean failure, so every public method tests this.
#	A caller that holds text must encode it.
sub _wide ($text)
{
	return $text =~ /[^\x00-\xFF]/ ? 1 : 0;
}

# _fail($reason):
#	The failure return of every public method: undef in scalar
#	context, and undef with the reason in list context. One helper
#	keeps the two contexts in step.
sub _fail ($reason)
{
	return wantarray ? ( undef, $reason ) : undef;
}

1;
