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

package Fugu::Signify;
our $VERSION = '0.5.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();
use Fugu::Ed25519;
use Fugu::File;
use Fugu::Signer;
use MIME::Base64 qw(decode_base64);

our @ISA = ('Fugu::Signer');

# Fugu::Signify - make a signify(1) key pair, sign a file, verify a
# signature and a SHA256 manifest, and read and write the manifest
# form.
#
# The module follows Fugu::Signer over signify(1). The parent holds
# the constructor and the command resolution, the three verbs, the run
# through Fugu::Process, the key walk of a verification, and the
# failure convention. This module holds the signify(1) file formats,
# the manifest methods, and the two engines.
#
# The module verifies with two engines, and engine names the one to
# take. The perl engine parses the signify(1) file formats and checks
# the signature with Fugu::Ed25519, so a host verifies a release with
# no command installed. It is the default. The signify engine runs the
# command. A caller that names a command asks for the command, so that
# call takes the signify engine.
#
# Perl holds no private key operation, so generate and sign run
# signify(1) under either engine. Each one names a key file as a path,
# so no key byte enters Perl, and no key byte reaches a log.
#
# The module also verifies each file that a signed SHA256 manifest
# names, against the digest of that manifest, with core Digest::SHA.
#
# A manifest holds one key in each line, between the parentheses. The
# key is opaque to this module: a release manifest writes a file name,
# and another producer writes a file path or a download URL. The
# caller maps each key to a local path, and the module reads no key as
# a path of its own.

# The size bound of a manifest, 1 MiB. An OpenBSD SHA256 file holds
# tens of lines. A caller that names a disk image by mistake gets a
# clean failure, not a read of 500 MB.
use constant MAX_MANIFEST_SIZE => 1_048_576;

# The size bound of a signify(1) public key file and signature file,
# 4 KiB. Each file holds two short lines. A caller that names a disk
# image by mistake gets a clean failure, not a read of 500 MB.
use constant MAX_SIGNIFY_FILE_SIZE => 4096;

# The first line of a signify(1) file. The line carries no trust: no
# signature covers it, and any producer writes any text after it.
use constant COMMENT_HEADER => 'untrusted comment: ';

# The two letters that name the algorithm at the front of each body.
use constant ALGORITHM => 'Ed';

# The length of the key number, in bytes. The number binds a
# signature to a key.
use constant KEYNUM_SIZE => 8;

# The byte length of the body of a public key file: the two letters,
# the key number, and the 32-byte public key.
use constant PUBLIC_KEY_SIZE => 42;

# The byte length of the body of a signature file: the two letters,
# the key number, and the 64-byte signature.
use constant SIGNATURE_SIZE => 74;

# Fugu::Signify->new(%args):
#	Build a generator, a signer and a verifier. The method resolves
#	the command once, and it runs no process.
#
#	%args:
#		engine  => $engine  # Optional: perl or signify
#		command => $command # Optional: a name or an absolute path
#		timeout => $seconds # Optional: the bound of one run
#
#	The engine selects the verifier alone. The default is perl. A
#	caller that names a command asks for the command, so that call
#	defaults to the signify engine. An engine name that the module
#	does not hold is a programming error.
#
#	The object holds no key set: verify and verify_manifest take
#	the keys of the call.
#
#	The method must not die for an absent command. Under the
#	signify engine it sets error instead, and is_available then
#	returns 0.
sub new ( $class, %args )
{
	my $engine = delete $args{engine}
	    // ( defined $args{command} ? 'signify' : 'perl' );
	die "engine must be perl or signify\n"
	    unless $engine eq 'perl' || $engine eq 'signify';

	my $self = $class->SUPER::new(%args);
	$self->{engine}  = $engine;
	$self->{ed25519} = Fugu::Ed25519->new;

	# The parent holds the reason of an absent command, and the
	# perl engine verifies without one. The call drops that reason,
	# so error and command_absent describe a call of this object.
	$self->_begin if $engine eq 'perl';

	return $self;
}

# $self->is_available:
#	Report if the object can verify. The perl engine always can, so
#	it returns 1 with no command. The signify engine returns 1 when
#	new resolved an executable command, and 0 otherwise. The method
#	runs no process, and it never dies.
sub is_available ($self)
{
	return 1 if $self->{engine} eq 'perl';

	return $self->SUPER::is_available;
}

# $self->generate(%args):
#	Make a signify(1) key pair with no passphrase. The method
#	returns 1, or undef with the reason in error.
#
#	%args:
#		comment => $text  # Required: the untrusted comment
#		public  => $path  # Required: the public half
#		secret  => $path  # Required: the private half
#
#	Perl holds no private key operation, so the method runs
#	signify(1) under either engine. On an absent command the method
#	returns undef, and command_absent reports 1.
#
#	signify(1) writes each half itself, so no key byte enters Perl.
#	It holds the two paths to one naming scheme: the stem of public
#	and the stem of secret must agree. The parent writes the
#	private half in a directory of its own, and the name of that
#	file does not change.
#
#	The parent refuses a path that exists, so one call never
#	overwrites a key.
#
#	The comment reaches the first line of each half, and one line
#	holds one field. The method therefore refuses a comment that
#	holds a newline, and it refuses it before the command runs, so
#	such a call writes no key.
sub generate ( $self, %args )
{
	die "comment is a necessary argument\n" unless defined $args{comment};

	$self->_begin;

	# signify(1) writes the comment in the first line of each half,
	# and one line holds one field. A comment with a newline would
	# write a third line into the key file, and the parser of this
	# module then refuses that file. The check runs before the
	# command, so the call writes no key.
	return $self->_set_error('the comment holds a newline')
	    if $args{comment} =~ /[\r\n]/;

	return $self->SUPER::generate(%args);
}

# $self->parse_public_key($bytes):
#	Parse a signify(1) public key file. The method returns a hash
#	reference with comment, keynum and key, or undef with the
#	reason in error.
#
#	The comment carries no trust. The key number binds the key to
#	a signature, and the key is the 32 bytes that Fugu::Ed25519
#	takes.
sub parse_public_key ( $self, $bytes )
{
	$self->_begin;

	my $parsed = $self->_parse_file( $bytes, PUBLIC_KEY_SIZE ) or return;

	return {
		comment => $parsed->{comment},
		keynum  => $parsed->{keynum},
		key     => $parsed->{payload},
	};
}

# $self->parse_signature($bytes):
#	Parse a signify(1) signature file. The method returns a hash
#	reference with comment, keynum and signature, or undef with
#	the reason in error.
#
#	The signature is the 64 bytes that Fugu::Ed25519 takes, and it
#	covers the bytes of the signed file.
sub parse_signature ( $self, $bytes )
{
	$self->_begin;

	my $parsed = $self->_parse_file( $bytes, SIGNATURE_SIZE ) or return;

	return {
		comment   => $parsed->{comment},
		keynum    => $parsed->{keynum},
		signature => $parsed->{payload},
	};
}

# $self->verify_manifest(%args):
#	Verify a signed SHA256 manifest, and then verify the digest of
#	each file that the caller names.
#
#	%args:
#		keys      => \@paths # Required: public key files
#		manifest  => $path   # Required: the signed SHA256 file
#		signature => $path   # Required: the signature file
#		files     => \%map   # Required: manifest key => local path
#
#	A key of files is a key of the manifest, and the module
#	compares it as text. It can be a file name, a file path, or a
#	download URL, whichever the producer of the manifest wrote.
#	The value is the local path that the module digests, so the
#	caller decides where the bytes sit.
#
#	The module must never choose which file to check, so an empty
#	files is a programming error, and the method dies. An empty
#	key set is one too: verify holds that check, and this method
#	dies with it.
#
#	The method returns the public key file that verified the
#	manifest, or undef on every failure. No file is digested
#	before the manifest verifies.
sub verify_manifest ( $self, %args )
{
	my ( $manifest, $signature ) = @args{qw(manifest signature)};
	die "manifest and signature are necessary arguments\n"
	    unless defined $manifest && defined $signature;

	my $files = $args{files};
	die "files must be a non-empty hash reference\n"
	    unless ref $files eq 'HASH' && %$files;

	my $keyfile = $self->verify(
		keys      => $args{keys},
		file      => $manifest,
		signature => $signature,
	);
	return unless defined $keyfile;

	# The bound reads the size on disk, before the content.
	my $size = -s $manifest;
	return $self->_set_error(
		sprintf '%s: manifest is larger than %d bytes',
		$manifest, MAX_MANIFEST_SIZE )
	    if !defined $size || $size > MAX_MANIFEST_SIZE;

	my $bytes = Fugu::File->read($manifest);
	return $self->_set_error("cannot read $manifest")
	    unless defined $bytes;

	my $digests = $self->_parse_manifest($bytes) or return;

	for my $key ( sort keys %$files ) {
		my $expected = $digests->{$key};
		return $self->_set_error("$manifest does not hold $key")
		    unless defined $expected;

		my $path     = $files->{$key};
		my $computed = _digest($path);
		return $self->_set_error("cannot digest $path: $!")
		    unless defined $computed;

		return $self->_set_error( "$key: digest mismatch:"
			    . " expected $expected, computed $computed" )
		    if $computed ne $expected;
	}

	return $keyfile;
}

# $self->parse_manifest($bytes):
#	The public form of the parser that verify_manifest uses. The
#	method returns a hash reference of manifest key to lowercase
#	hex digest, or undef with the reason in error.
#
#	Two callers read a manifest without a signature at that
#	moment. A rotation writes a manifest, and it must read the
#	file that it wrote. A site check compares a manifest against
#	the files beside it, and a site build cannot sign. A private
#	parser would make each one write the line form again.
#
#	The method verifies nothing. A caller that needs the signature
#	calls verify_manifest, which verifies the signature before it
#	digests one file.
sub parse_manifest ( $self, $bytes )
{
	$self->_begin;

	return $self->_set_error('the manifest bytes are undef')
	    unless defined $bytes;

	return $self->_set_error( 'the manifest holds a character above 255, '
		    . 'and a manifest holds bytes' )
	    if $self->_wide($bytes);

	return $self->_parse_manifest($bytes);
}

# $self->write_manifest($digests):
#	The text of a SHA256 manifest, or undef with the reason in
#	error.
#
#	Each line holds 'SHA256 (key) = digest'. The keys sort in
#	ascending order, so two runs of a rotation write one byte
#	sequence, and a diff of two manifests then shows the change
#	only.
#
#	The key is a file name, a file path, or a download URL,
#	whichever the producer writes. The method therefore rejects
#	only a key that another reader cannot carry. _parse_manifest
#	takes the text up to the last parenthesis, so it reads such a
#	key back without a change. A stricter reader does not: a
#	parenthesis ends the key in a reader that stops at the first
#	one, and whitespace breaks a reader that splits a line on
#	space. A manifest travels to sha256(1) and to scripts/deps, so
#	the writer holds a key to the strict form.
sub write_manifest ( $self, $digests )
{
	$self->_begin;

	unless ( ref $digests eq 'HASH' ) {
		die "digests must be a hash reference\n";
	}

	return $self->_set_error('the digest set is empty') unless %$digests;

	# A manifest is bytes. A key that holds a code point above 255
	# is character data, and print then writes its UTF-8 form: the
	# bytes on disk differ from the key that the caller passed, so
	# the manifest names a file that no reader finds. Perl also
	# warns "Wide character in print". Fugu::OpenPGP fails such a
	# string, and this method must agree.
	for my $key ( sort keys %$digests ) {
		next unless $self->_wide($key);
		return $self->_set_error( 'a manifest key holds a character '
			    . 'above 255, and a manifest holds bytes' );
	}

	my $text = '';
	for my $key ( sort keys %$digests ) {
		return $self->_set_error('a manifest key is empty')
		    unless length $key;

		return $self->_set_error(
			"a manifest key holds a parenthesis: $key")
		    if $key =~ /[()]/;

		# The class names the ASCII whitespace only. \s reads a
		# byte above 127 as Latin-1 under the feature set of
		# this file, so it matches U+0085 and U+00A0 and would
		# reject a UTF-8 file name that holds a letter such as
		# a-ogonek. A rotation would then stall on a release
		# asset whose name is valid.
		return $self->_set_error(
			"a manifest key holds whitespace: $key")
		    if $key =~ /[ \t\n\r\f\x0B]/;

		my $digest = $digests->{$key};
		return $self->_set_error( "the digest of $key is not 64 "
			    . 'hexadecimal characters' )
		    unless defined $digest && $digest =~ /\A[0-9A-Fa-f]{64}\z/;

		$text .= "SHA256 ($key) = " . lc($digest) . "\n";
	}

	return $text;
}

# --- the hooks of the parent class ----------------------------------------

# $self->_command_label:
#	The name of the command in a diagnostic.
sub _command_label ($)
{
	return 'signify';
}

# $self->_command_defaults:
#	The search list of the command, in the order of preference. On
#	Debian the plain name signify belongs to an unrelated package,
#	and the OpenBSD name exists only where the real program is
#	installed.
sub _command_defaults ($)
{
	return ( 'signify-openbsd', 'signify' );
}

# $self->_generate(%args):
#	Run the generator of signify(1) over the comment and the two
#	paths. The parent holds secret to a private directory, and it
#	moves that file into place.
sub _generate ( $self, %args )
{
	$self->_run( [
			'-G', '-n',          '-c', $args{comment},
			'-p', $args{public}, '-s', $args{secret},
		],
		"cannot generate $args{public}"
	) or return;

	return 1;
}

# $self->_sign(%args):
#	Run the signer of signify(1). The command reads the private
#	half from the path, and it writes the signature file itself.
sub _sign ( $self, %args )
{
	$self->_run( [
			'-S',        '-s', $args{secret}, '-m',
			$args{file}, '-x', $args{signature},
		],
		"cannot sign $args{file}"
	) or return;

	return 1;
}

# $self->_verify($key, %args):
#	Verify one file against one public key file, with the engine of
#	the object. The hook answers undef when the key verified, and
#	the reason that it did not.
#
#	The signify engine runs the command, and the perl engine runs
#	none. The hook therefore resolves the command under the signify
#	engine alone.
sub _verify ( $self, $key, %args )
{
	return $self->_verify_perl( $key, %args )
	    if $self->{engine} eq 'perl';

	$self->_command or return $self->error;

	# -q suppresses the success line: the run reads the exit code
	# and the standard error only.
	$self->_run( [
			'-V', '-q',             '-p', $key,
			'-x', $args{signature}, '-m', $args{file},
		] ) or return $self->error;

	return;
}

# $self->_verify_perl($key, %args):
#	Verify one file against one public key file with
#	Fugu::Ed25519. The method answers undef when the key verified,
#	and the reason that it did not.
#
#	A key number that differs from the signature gives "checked
#	against wrong key", which is the diagnostic of signify(1)
#	itself. The walk of the parent then continues to the next key.
sub _verify_perl ( $self, $key, %args )
{
	my $bytes =
	    $self->_read_bounded( $args{signature}, MAX_SIGNIFY_FILE_SIZE );
	return _bound_reason() unless defined $bytes;

	my $signature = $self->parse_signature($bytes) or return $self->error;

	my $key_bytes = $self->_read_bounded( $key, MAX_SIGNIFY_FILE_SIZE );
	return _bound_reason() unless defined $key_bytes;

	my $public = $self->parse_public_key($key_bytes)
	    or return $self->error;

	return 'checked against wrong key'
	    unless $public->{keynum} eq $signature->{keynum};

	my $verified = $self->{ed25519}->verify(
		key       => $public->{key},
		signature => $signature->{signature},
		file      => $args{file},
	);

	# undef means that the verifier refused the input, and the
	# reason belongs to this key.
	return $self->{ed25519}->error unless defined $verified;

	return 'signature verification failed' unless $verified;

	return;
}

# $self->_reason($result):
#	The reason of a signify(1) run that reached the child and
#	failed: the first line of the diagnostic without the program
#	name in front, or the exit code. The parent holds the timeout.
sub _reason ( $, $result )
{
	my ($reason) = split /\n/, $result->{stderr} // '';
	$reason //= '';
	$reason =~ s/^\S*signify\S*:\s*//;

	return length $reason ? $reason : "exit code $result->{exit_code}";
}

# --- the parts of this module alone ---------------------------------------

# _bound_reason():
#	The reason that a signify(1) file did not read under the bound.
#	The walk of a verification writes it for a key file and for a
#	signature file alike.
sub _bound_reason ()
{
	return sprintf 'cannot read a signify file under %d bytes',
	    MAX_SIGNIFY_FILE_SIZE;
}

# $self->_parse_file($bytes, $size):
#	Parse the two lines of a signify(1) file. A public key file
#	and a signature file share the shape: the comment line, then
#	the base64 body. The body holds the two letters Ed, the key
#	number, and the key or the signature.
#
#	The method returns the hash reference, or undef with the
#	reason in error. The comment carries no trust, so the method
#	reads it and tests nothing after the header.
#
#	decode_base64 skips a character that no base64 alphabet
#	holds, so a body of the right character count with one bad
#	character decodes short. The two length tests together
#	therefore hold the body to the exact form.
sub _parse_file ( $self, $bytes, $size )
{
	return $self->_set_error('the file is undef') unless defined $bytes;

	return $self->_set_error( 'the file holds a character above 255, '
		    . 'and a signify file holds bytes' )
	    if $self->_wide($bytes);

	# A list assignment would give split an implicit limit, and a
	# trailing empty field would then survive as a body. The array
	# takes the whole split, so a file of one line fails, and so
	# does a file of three.
	my @lines = split /\n/, $bytes;
	return $self->_set_error('a signify file holds two lines')
	    unless @lines == 2;

	my ( $comment, $body ) = @lines;

	return $self->_set_error('the first line is no untrusted comment')
	    unless index( $comment, COMMENT_HEADER ) == 0;

	my $characters = 4 * int( ( $size + 2 ) / 3 );
	return $self->_set_error(
		"the body is not $characters base64 characters")
	    unless length($body) == $characters;

	my $raw = decode_base64($body);
	return $self->_set_error("the body is not $size bytes")
	    unless length($raw) == $size;

	return $self->_set_error('the body names no Ed25519 key or signature')
	    unless index( $raw, ALGORITHM ) == 0;

	return {
		comment => substr( $comment, length COMMENT_HEADER ),
		keynum  => substr( $raw,     length(ALGORITHM), KEYNUM_SIZE ),
		payload => substr( $raw,     length(ALGORITHM) + KEYNUM_SIZE ),
	};
}

# $self->_parse_manifest($bytes):
#	Parse the OpenBSD sha256(1) line form:
#
#		SHA256 (miniroot78.img) = 4f2b...
#		SHA256 (dist/miniroot78.img) = 4f2b...
#		SHA256 (https://example.org/dl/miniroot78.img) = 4f2b...
#
#	The key sits between the parentheses, and this method holds it
#	as text. A release manifest writes a file name, and another
#	producer writes a file path or a download URL. The pattern
#	takes the whole text up to the last parenthesis, so a key with
#	a solidus, a colon or a dot reads like any other.
#
#	The method returns a hash reference of key to lowercase hex
#	digest, or undef with the reason in error. Like Fugu::Config,
#	the parser never skips a line: an empty manifest, a line it
#	cannot parse, a digest that is not 64 hexadecimal characters,
#	and a duplicate key are each a failure.
sub _parse_manifest ( $self, $bytes )
{
	my %digest;
	for my $line ( split /\n/, $bytes ) {
		my ( $key, $hex ) =
		    $line =~ /^SHA256 \((.+)\) = ([0-9A-Fa-f]+)$/;
		return $self->_set_error("cannot parse manifest line: $line")
		    unless defined $key;

		return $self->_set_error(
			"digest of $key is not 64 hexadecimal characters")
		    if length($hex) != 64;

		return $self->_set_error("duplicate manifest key: $key")
		    if exists $digest{$key};

		$digest{$key} = lc $hex;
	}

	return $self->_set_error('the manifest is empty') unless keys %digest;

	return \%digest;
}

# _digest($path):
#	The lowercase hex SHA256 digest of the file, or undef when the
#	file does not open. addfile reads in blocks, so a file set of
#	500 MB never enters memory whole.
sub _digest ($path)
{
	open my $fh, '<', $path or return;
	binmode $fh;

	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return lc $sha->hexdigest;
}

1;
