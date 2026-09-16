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

package Fugu::OpenPGP;
our $VERSION = '0.5.1';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();
use Fugu::Process;
use Fugu::Signer;
use MIME::Base64 qw(decode_base64);

our @ISA = ('Fugu::Signer');

# Fugu::OpenPGP - read an armored OpenPGP public key as bytes, and
# drive gpg(1) over a key.
#
# The module follows Fugu::Signer over gpg(1). The parent holds the
# constructor and the command resolution, the three verbs, the run
# through Fugu::Process, the key walk of a verification, and the
# failure convention. This module holds the byte reader, the temporary
# home, and the arguments of each gpg(1) command line.
#
# The byte reader decodes the armor of RFC 4880. It computes the v4
# fingerprint of a public key packet, and the Web Key Directory hash of
# an email local part. It runs no command. Each reader is a method of
# the object, and it reports through error.
#
# The command part generates a key with an encryption subkey, it signs
# a file, it verifies a detached signature, and it reads the expiry of
# a key. Each run takes a temporary home that the run removes, so no
# run reads a home of the user and no run reads an agent of the user.
#
# Each half of a key enters as a path and leaves as a file, so no key
# byte enters Perl and no key byte reaches a log.
#
# Every method that takes armored text needs bytes. Each one rejects a
# string that holds a code point above 255, because Digest::SHA dies on
# such a string, and unpack 'C*' would take the low byte of each
# character.

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

# The time bound of one gpg(1) call, in seconds. The default of the
# parent is 30, and a key generation needs entropy. It can take
# several seconds on an idle host.
use constant GPG_TIMEOUT => 60;

# The flags of every gpg(1) call. --batch and --no-tty hold the
# command away from a terminal, and the loopback pinentry with an
# empty passphrase holds it away from a prompt. The generator makes a
# key with no passphrase, so no half ever needs one.
use constant GPG_FLAGS => (
	'--batch',  '--no-tty',     '--quiet', '--pinentry-mode',
	'loopback', '--passphrase', '',
);

# Fugu::OpenPGP->new(%args):
#	Build a generator, a signer and a verifier over gpg(1). The
#	method resolves the command once, and it runs no process.
#
#	%args:
#		command => $command # Optional: a name or an absolute path
#		timeout => $seconds # Optional: the bound of one run
#
#	The method must not die for an absent command. It sets error
#	instead, and is_available then returns 0.
sub new ( $class, %args )
{
	$args{timeout} //= GPG_TIMEOUT;

	return $class->SUPER::new(%args);
}

# $self->generate(%args):
#	Make one Ed25519 key with one user id, and one Curve25519
#	encryption subkey. The method returns 1, or undef with the
#	reason in error.
#
#	%args:
#		public  => $path    # Required: the public half
#		secret  => $path    # Required: the private half
#		email   => $address # Required: the user id
#		expires => $epoch   # Optional: seconds since the epoch
#
#	gpg(1) writes each half as armored text at its path, so no key
#	byte enters Perl. The parent writes the private half in a
#	directory of its own, and one rename then moves it into place.
#	The parent also refuses a path that exists, so one call never
#	overwrites a key.
#
#	The user id holds the email alone. A site publishes the public
#	half, and a correspondent encrypts to the subkey.
#
#	The email reaches the user id, and an angle bracket, a line
#	ending or a NUL byte would forge a second one. The method
#	refuses each of them before the command runs, so such a call
#	makes no key.
#
#	expires is seconds since the epoch, the unit that expiry
#	answers. It must be a whole number after the current time. With
#	no expires the key and the subkey hold no expiry.
sub generate ( $self, %args )
{
	my ( $email, $expires ) = @args{qw(email expires)};
	die "email is a necessary argument\n" unless defined $email;

	$self->_begin;

	return $self->_set_error('the email is empty') unless length $email;
	return $self->_set_error( 'the email holds a character above 255, '
		    . 'and this method needs bytes' )
	    if $self->_wide($email);

	# The generator writes "<$email>" as the user id. An angle
	# bracket, a line ending or a NUL byte would close that
	# user id and open a second one, so the key would carry an
	# address that the caller never named.
	return $self->_set_error(
		'the email holds <, >, a line ending or a NUL byte')
	    if $email =~ /[<>\r\n\0]/;

	if ( defined $expires ) {
		return $self->_set_error(
			"the expiry $expires is not a whole number")
		    unless $expires =~ /\A-?[0-9]+\z/;
		return $self->_set_error(
			"the expiry $expires is not after the current time")
		    unless $expires > time();
	}

	return $self->SUPER::generate(%args);
}

# $self->expiry(%args):
#	The expiry of a public half, as seconds since the epoch. The
#	method returns 0 for a key that holds no expiry, and undef with
#	the reason in error on a failure.
#
#	%args:
#		public => $path # Required: the public half
#
#	The three answers differ on purpose. A caller tells "no expiry"
#	from "cannot read" with one test, and a key with no expiry
#	never reads as a key that expired.
#
#	The read imports nothing: gpg(1) shows the key and drops it, so
#	the home keeps no keyring.
sub expiry ( $self, %args )
{
	my $public = $args{public};
	die "public is a necessary argument\n" unless defined $public;

	$self->_begin;

	$self->_check_input($public) or return;
	$self->_command              or return;

	return $self->_with_temp_dir(
		undef,
		sub ($home) {
			return $self->_expiry( $home, $public );
		} );
}

# $self->decode_armor($text):
#	The binary form of an armored block, or undef with the reason
#	in error.
#
#	The method reads the two delimiter lines and skips the armor
#	headers. It decodes the base64 body, and it compares the
#	CRC-24 checksum line against the decoded bytes.
#
#	The checksum is not decoration. A decoder that skips it
#	accepts a truncated key, and a truncated key gives a
#	fingerprint of its own.
sub decode_armor ( $self, $text )
{
	$self->_begin;

	return $self->_set_error('the armored text is undef')
	    unless defined $text;
	return $self->_set_error( 'the armored text holds a character above '
		    . '255, and this method needs bytes' )
	    if $self->_wide($text);

	if ( length($text) > MAX_ARMOR_SIZE ) {
		return $self->_set_error(
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
	return $self->_set_error('no BEGIN PGP delimiter line')
	    unless defined $type;

	my ($end) = $text =~ /^-----END PGP ([A-Z0-9 ]+)-----[ \t]*$/m;
	return $self->_set_error('no END PGP delimiter line')
	    unless defined $end;
	return $self->_set_error(
		"the delimiters name two block types: $type and $end")
	    unless $type eq $end;

	my ($block) =
	    $text =~ /^-----BEGIN \QPGP $type\E-----[ \t]*\n(.*?)^-----END/ms;
	return $self->_set_error('no text between the delimiter lines')
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
		return $self->_set_error(
			'no blank line ends the armor header section');
	}
	shift @lines;

	# The checksum line starts with one '=' and holds four base64
	# characters. It is the last non-blank line of the body.
	my ( @body, $checksum );
	for my $line (@lines) {
		next unless length $line;
		if ( $line =~ /\A=([A-Za-z0-9+\/]{4})\z/ ) {
			return $self->_set_error('more than one checksum line')
			    if defined $checksum;
			$checksum = $1;
			next;
		}
		return $self->_set_error(
			'a body line follows the checksum line')
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
		return $self->_set_error("not a base64 body line: $line")
		    unless $line =~ m{\A[A-Za-z0-9+/]+={0,2}\z};
		push @body, $line;
	}

	return $self->_set_error('no base64 body')   unless @body;
	return $self->_set_error('no checksum line') unless defined $checksum;

	# Only the last body line may carry the padding.
	for my $i ( 0 .. $#body - 1 ) {
		next unless $body[$i] =~ /=/;
		return $self->_set_error(
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
		return $self->_set_error(
			sprintf 'the base64 body holds %d characters, '
			    . 'which is not a whole number of groups',
			length $joined
		);
	}

	my $binary = decode_base64($joined);
	return $self->_set_error('the base64 body decodes to no bytes')
	    unless length $binary;

	# The pattern above fixes the checksum line at four base64
	# characters. Four characters always decode to three bytes, so
	# no length test is needed here.
	my $want = decode_base64($checksum);

	my $got = pack 'N', _crc24($binary);
	$got = substr $got, 1, 3;    # the low three bytes, big endian
	unless ( $got eq $want ) {
		return $self->_set_error(
			sprintf 'checksum mismatch: the body gives %s, '
			    . 'and the line holds %s',
			unpack( 'H*', $got ),
			unpack( 'H*', $want ) );
	}

	return $binary;
}

# $self->fingerprint($binary):
#	The v4 fingerprint of the first public key packet, in
#	upper-case hexadecimal with no separator, or undef with the
#	reason in error.
#
#	The fingerprint is the SHA-1 of the byte 0x99, the two-byte
#	length of the packet body, and that body, per RFC 4880 section
#	12.2. The constant 0x99 never changes with the packet header
#	that the file holds: a key in the new packet format gets the
#	same fingerprint as the same key in the old format. The method
#	therefore reads the length from the header and writes the
#	length again.
sub fingerprint ( $self, $binary )
{
	$self->_begin;

	return $self->_set_error('the binary form is undef')
	    unless defined $binary;
	return $self->_set_error( 'the binary form holds a character above '
		    . '255, and this method needs bytes' )
	    if $self->_wide($binary);

	my ( $tag, $body, $reason ) = _first_packet($binary);
	return $self->_set_error($reason) unless defined $tag;

	return $self->_set_error(
		"the first packet is tag $tag, and not a public key")
	    unless $tag == PACKET_PUBLIC_KEY;

	my $version = length($body) ? ord substr( $body, 0, 1 ) : undef;
	return $self->_set_error('the public key packet is empty')
	    unless defined $version;
	return $self->_set_error(
		"the public key packet is version $version, and not 4")
	    unless $version == 4;

	# The digest writes the body length in two octets, so a longer
	# body has no version 4 fingerprint. pack would wrap the value
	# without a warning, and the method would then answer with a
	# confident wrong fingerprint.
	if ( length($body) > MAX_PACKET_BODY ) {
		return $self->_set_error(
			sprintf 'the public key packet body is %d bytes, '
			    . 'and a version 4 fingerprint holds at most %d',
			length($body), MAX_PACKET_BODY
		);
	}

	return
	    uc Digest::SHA::sha1_hex(
		"\x99" . pack( 'n', length $body ) . $body );
}

# $self->wkd_hash($local):
#	The Web Key Directory hash of an email local part, or undef
#	with the reason in error.
#
#	The hash is the z-base-32 form of the SHA-1 of the local part
#	in lower case. gpg --locate-keys asks for
#	.well-known/openpgpkey/hu/<hash>, so the answer decides the
#	publication path. The method lowercases the part itself: the
#	draft states the rule, and a caller that lowercases twice gets
#	the same answer.
sub wkd_hash ( $self, $local )
{
	$self->_begin;

	return $self->_set_error('the local part is undef')
	    unless defined $local;
	return $self->_set_error('the local part is empty')
	    unless length $local;
	return $self->_set_error( 'the local part holds a character above '
		    . '255, and this method needs bytes' )
	    if $self->_wide($local);

	# The lowercase step must touch the ASCII letters only. lc
	# reads a byte above 127 as Latin-1 under the feature set of
	# this file, so it rewrites the bytes of a UTF-8 local part:
	# c3 becomes e3. gpg(1) lowercases the ASCII letters only, so
	# lc would publish a non-ASCII address at a path that gpg
	# never asks for.
	my $lower = $local =~ tr/A-Z/a-z/r;

	return $self->zbase32( Digest::SHA::sha1($lower) );
}

# $self->zbase32($bytes):
#	The z-base-32 form of the bytes, or undef with the reason in
#	error. The encoding writes no padding, and it emits one
#	character for each five bits. A byte count that is not a
#	multiple of five therefore ends on a partial group, and the low
#	bits of that group are zero.
sub zbase32 ( $self, $bytes )
{
	$self->_begin;

	return '' unless defined $bytes && length $bytes;

	# unpack 'C*' takes the low byte of each code point, so
	# character data would give a confident wrong answer: the
	# smiling face U+263A would encode as the colon. The method
	# needs bytes, and it says so.
	return $self->_set_error( 'the input holds a character above 255, '
		    . 'and this method needs bytes' )
	    if $self->_wide($bytes);

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

# --- the hooks of the parent class ----------------------------------------

# $self->_command_label:
#	The name of the command in a diagnostic.
sub _command_label ($)
{
	return 'gpg';
}

# $self->_command_defaults:
#	The search list of the command, in the order of preference. A
#	host that kept gpg for version 1 carries version 2 under the
#	name gpg2, and the command part needs version 2.
sub _command_defaults ($)
{
	return ( 'gpg2', 'gpg' );
}

# $self->_generate(%args):
#	Run the generator of gpg(1) under one temporary home. The hook
#	returns 1, or undef with the reason in error.
#
#	--quick-add-key refuses an email, so the subkey needs the
#	fingerprint. The read of the fingerprint therefore sits between
#	the two generator runs.
#
#	The export of the private half runs first. The parent holds
#	that path in a private directory, so a failed export of the
#	public half leaves no half behind.
sub _generate ( $self, %args )
{
	my ( $public, $secret, $email ) = @args{qw(public secret email)};
	my $expire =
	    defined $args{expires} ? _iso_utc( $args{expires} ) : '0';

	return $self->_with_temp_dir(
		undef,
		sub ($home) {
			$self->_gpg(
				$home,
				[
					'--quick-generate-key', '--',
					"<$email>",             'ed25519',
					'sign',                 $expire
				],
				"cannot generate a key for $email"
			) or return;

			my $fingerprint =
			    $self->_fingerprint_of( $home, $email );
			return unless defined $fingerprint;

			$self->_gpg(
				$home,
				[
					'--quick-add-key', $fingerprint,
					'cv25519',         'encr',
					$expire
				],
				"cannot add the encryption subkey of $email"
			) or return;

			for my $part (
				[ 'secret', '--export-secret-keys', $secret ],
				[ 'public', '--export',             $public ] )
			{
				$self->_export( $home, $email, @$part )
				    or return;
			}

			return 1;
		} );
}

# $self->_sign(%args):
#	Run the signer of gpg(1) under one temporary home. The command
#	reads the private half from the path, and it writes the
#	signature file itself.
#
#	--yes replaces a signature file that exists, because a rotation
#	signs one manifest again.
sub _sign ( $self, %args )
{
	my ( $secret, $file, $signature ) = @args{qw(secret file signature)};

	return $self->_with_temp_dir(
		undef,
		sub ($home) {
			$self->_gpg(
				$home,
				[ '--import', '--', $secret ],
				'cannot import the secret half'
			) or return;

			$self->_gpg(
				$home,
				[
					'--armor',       '--yes',
					'--output',      $signature,
					'--detach-sign', '--',
					$file
				],
				"cannot sign $file"
			) or return;

			return 1;
		} );
}

# $self->_verify($key, %args):
#	Verify one file against one public key file, under one
#	temporary home. The hook answers undef when the key verified,
#	and the reason that it did not.
#
#	The home takes the one public half of the key, so a signature
#	of another key fails. The home of the user holds no part in the
#	answer.
sub _verify ( $self, $key, %args )
{
	$self->_command or return $self->error;

	my $verified = $self->_with_temp_dir(
		undef,
		sub ($home) {
			$self->_gpg( $home, [ '--import', '--', $key ] )
			    or return;

			$self->_gpg(
				$home,
				[
					'--verify',       '--',
					$args{signature}, $args{file} ]
			) or return;

			return 1;
		} );

	return if $verified;

	return $self->error;
}

# $self->_reason($result):
#	The reason of a gpg(1) run that reached the child and failed:
#	a line of the diagnostic without the prefix, or the exit code.
#	The parent holds the timeout.
#
#	The method takes the last line that starts with "gpg: ".
#	gpg(1) writes "Signature made ..." first and the fault last, so
#	the first line names nothing. A bad signature ends with "BAD
#	signature from ...", an unknown signer ends with "Can't check
#	signature: No public key", and a text that is no key gives "no
#	valid OpenPGP data found.".
sub _reason ( $, $result )
{
	my $reason = '';
	for my $line ( split /\n/, $result->{stderr} // '' ) {
		next unless index( $line, 'gpg: ' ) == 0;
		$reason = substr $line, length 'gpg: ';
	}

	# gpg(1) pads a continuation line after the prefix.
	$reason =~ s/\A[ \t]+//;

	return length $reason ? $reason : "exit code $result->{exit_code}";
}

# $self->_stop_helpers($dir):
#	Stop the gpg-agent of one temporary home. gpg 2 starts an agent
#	for a key operation, and that agent outlives a home that the
#	run removes. An agent that outlives its home leaks a process.
#
#	gpgconf(1) ships beside gpg(1), so the method names it beside
#	the resolved command. The result goes unread: an absent
#	gpgconf(1) must not fail a signature. A directory that started
#	no agent takes the same call, and gpgconf(1) then stops
#	nothing.
sub _stop_helpers ( $self, $dir )
{
	return unless defined $self->{command};

	# find_command answers a path that holds a solidus under every
	# input, so the substitution always names a directory.
	my $gpgconf = $self->{command} =~ s{[^/]+\z}{gpgconf}r;
	return unless -f $gpgconf && -x _;

	Fugu::Process->run(
		cmd => [ $gpgconf, '--homedir', $dir, '--kill', 'gpg-agent' ],
		timeout => $self->{timeout},
		env     => _env($dir),
	);

	return;
}

# --- the parts of this module alone ---------------------------------------

# $self->_gpg($home, $args, $what):
#	Run one gpg(1) command under the temporary home, and answer the
#	result of the run. The method returns undef with the reason in
#	error when the run fails.
#
#	Each run takes the flags of the module, the home, and then the
#	arguments of the caller. The environment of the child names the
#	home twice: gpg(1) reads GNUPGHOME, and gpgconf(1) and the
#	agent read either name.
sub _gpg ( $self, $home, $args, $what = undef )
{
	return $self->_run( [ GPG_FLAGS, '--homedir', $home, @$args ],
		$what, env => _env($home) );
}

# $self->_fingerprint_of($home, $email):
#	The fingerprint of the key of one temporary home, or undef with
#	the reason in error. --quick-add-key names the primary key by
#	fingerprint, so the generator reads it between its two runs.
sub _fingerprint_of ( $self, $home, $email )
{
	my $list = $self->_gpg(
		$home,
		[ '--with-colons', '--list-keys' ],
		"cannot read the key of $email"
	) or return;

	my $fingerprint = _colon_field( $list->{stdout}, 'fpr', 10 );
	return $fingerprint if defined $fingerprint && length $fingerprint;

	return $self->_set_error(
		"cannot read the key of $email: no fingerprint line");
}

# $self->_export($home, $email, $name, $flag, $path):
#	Export one half of the key as armored text at the path. The
#	method returns 1, or undef with the reason in error.
#
#	gpg(1) exits 0 and writes no file when it finds no key of that
#	name. An empty half is no answer, so the method fails instead
#	of leaving an empty file behind.
sub _export ( $self, $home, $email, $name, $flag, $path )
{
	$self->_gpg(
		$home,
		[ '--armor', '--output', $path, $flag, '--', $email ],
		"cannot export the $name half of $email"
	) or return;

	return 1 if -s $path;

	return $self->_set_error( "cannot export the $name half of $email: "
		    . 'the export holds no key' );
}

# $self->_expiry($home, $public):
#	The body of expiry, under one temporary home.
#
#	The pub line of the colon form holds the creation time in field
#	6 and the expiry in field 7. An empty field 7 means that the
#	key holds no expiry.
sub _expiry ( $self, $home, $public )
{
	my $result = $self->_gpg(
		$home,
		[
			'--with-colons', '--import-options',
			'show-only',     '--import',
			'--',            $public
		],
		"cannot read $public"
	) or return;

	my $seconds = _colon_field( $result->{stdout}, 'pub', 7 );
	unless ( defined $seconds ) {
		return $self->_set_error("cannot read $public: no key line");
	}

	return 0 unless length $seconds;

	unless ( $seconds =~ /\A[0-9]+\z/ ) {
		return $self->_set_error(
			"cannot read $public: the expiry field holds $seconds");
	}

	return $seconds + 0;
}

# _env($home):
#	The environment of one gpg(1) run. The child takes this set and
#	nothing else, so no variable of the caller reaches the command.
#
#	HOME and GNUPGHOME both name the temporary home: gpg(1) reads
#	GNUPGHOME, and gpgconf(1) and the agent read either one.
#	LC_ALL holds the diagnostics in English, because _reason reads
#	them.
sub _env ($home)
{
	return {
		PATH      => $ENV{PATH} // '',
		HOME      => $home,
		GNUPGHOME => $home,
		LC_ALL    => 'C',
	};
}

# _colon_field($text, $type, $number):
#	Field $number of the first record of type $type in the colon
#	form of gpg(1), or undef when the text holds no such record.
#
#	The colon form writes one record in each line, and a colon
#	separates the fields. Field 1 names the record type. The
#	fingerprint read takes field 10 of the fpr record, and the
#	expiry read takes field 7 of the pub record.
sub _colon_field ( $text, $type, $number )
{
	for my $line ( split /\n/, $text // '' ) {
		my @field = split /:/, $line, -1;
		next unless @field && $field[0] eq $type;
		return $field[ $number - 1 ];
	}

	return;
}

# _iso_utc($epoch):
#	The UTC form YYYYMMDDTHHMMSS of an epoch. gpg(1) reads that
#	form as an expiry, and the primary key then expires on the
#	exact second. gpg(1) writes each expiry as a duration from a
#	creation time, so the subkey expiry can fall one second before
#	the key expiry. The seconds=N form is off by one, so the
#	generator never writes it.
sub _iso_utc ($epoch)
{
	my @time = gmtime $epoch;

	return sprintf '%04d%02d%02dT%02d%02d%02d', $time[5] + 1900,
	    $time[4] + 1, $time[3], $time[2], $time[1], $time[0];
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

1;
