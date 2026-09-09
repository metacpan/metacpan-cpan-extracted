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

package Fugu::Signify;
our $VERSION = '0.4.0';

use Digest::SHA ();
use Fugu::File;
use Fugu::Process;

# Fugu::Signify - verify a signify(1) signature and a SHA256 manifest,
# and read and write the manifest form.
#
# The module runs signify(1) through Fugu::Process->run, with an
# argument list and never a shell. It holds a small key set, so a
# caller can accept the current key and the next key. It also verifies
# each file that a signed SHA256 manifest names, against the digest of
# that manifest, with core Digest::SHA.
#
# A manifest holds one key in each line, between the parentheses. The
# key is opaque to this module: a release manifest writes a file name,
# and another producer writes a file path or a download URL. The
# caller maps each key to a local path, and the module reads no key as
# a path of its own.
#
# The module holds no private key, and it must not sign. A signature
# is a human act. Every recoverable failure returns undef, and error
# holds the reason. The module never logs: the caller decides what to
# report.

# The size bound of a manifest, 1 MiB. An OpenBSD SHA256 file holds
# tens of lines. A caller that names a disk image by mistake gets a
# clean failure, not a read of 500 MB.
use constant MAX_MANIFEST_SIZE => 1_048_576;

# The time bound of one signify(1) call, in seconds. A command that a
# caller named can be the wrong program. signify(1) itself needs
# milliseconds.
use constant SIGNIFY_TIMEOUT => 30;

# Fugu::Signify->new(%args):
#	Build a verifier. The method resolves the command once, and it
#	runs no process.
#
#	%args:
#		keys    => \@paths  # Required: public key files, in trust order
#		command => $command # Optional: a name or an absolute path
#
#	The order of keys is the trust order: the current key first,
#	the next key second. The method dies when keys is absent, not
#	an array reference, or empty. Each one is a programming error.
#
#	The method must not die for an absent command. It sets error
#	instead, and is_available then returns 0.
sub new ( $class, %args )
{
	my $keys = $args{keys};
	die "keys must be a non-empty array reference\n"
	    unless ref $keys eq 'ARRAY' && @$keys;

	my $self = bless {
		keys           => [@$keys],
		command        => undef,
		command_error  => undef,
		command_absent => 0,
		error          => undef,
	}, $class;

	my $command = _find_command( $args{command} );
	if ( defined $command ) {
		$self->{command} = $command;
	}
	else {
		my $named = $args{command} // 'signify-openbsd, signify';
		$self->{command_error} =
		    "no executable signify command: $named";
		$self->{error}          = $self->{command_error};
		$self->{command_absent} = 1;
	}

	return $self;
}

# $self->is_available:
#	Report if the object resolved an executable command. The
#	method returns 1 or 0. It runs no process, and it never dies.
sub is_available ($self)
{
	return defined $self->{command} ? 1 : 0;
}

# $self->command:
#	The resolved command path, or undef. An operator who installed
#	the wrong signify needs this answer in a diagnostic.
sub command ($self)
{
	return $self->{command};
}

# $self->error:
#	The reason of the most recent failure, or undef after a
#	success.
sub error ($self)
{
	return $self->{error};
}

# $self->command_absent:
#	Report if the most recent failure means that signify(1) never
#	ran: the search list did not resolve the command, or the
#	command failed to execve(2). An absent command is an install
#	problem, and a failed signature is an integrity problem. The
#	caller must tell them apart.
sub command_absent ($self)
{
	return $self->{command_absent} ? 1 : 0;
}

# $self->verify($file, $sigfile):
#	Verify one file against the key set, in order. $sigfile
#	defaults to "$file.sig", the default of signify(1) itself.
#
#	The method returns the public key file that verified the
#	signature. It returns undef on every failure, and error holds
#	the reason. For a signature that no key verified, the reason
#	names the file, then each key with the first line of its
#	signify diagnostic. A caller thus tells a wrong key from an
#	absent key file.
sub verify ( $self, $file, $sigfile = undef )
{
	$self->{error}          = undef;
	$self->{command_absent} = 0;

	unless ( defined $self->{command} ) {
		$self->{error}          = $self->{command_error};
		$self->{command_absent} = 1;
		return;
	}

	$sigfile //= "$file.sig";

	# One check covers every key, and it names the missing path.
	for my $path ( $file, $sigfile ) {
		next if -f $path;
		$self->{error} = "not a plain file: $path";
		return;
	}

	my @reasons;
	for my $keyfile ( @{ $self->{keys} } ) {
		my $result = $self->_run_signify( $keyfile, $sigfile, $file );
		return $keyfile if $result->{success};

		# A run that never reached the child means that
		# signify(1) never ran. That is an install problem, so
		# the loop stops: every later key would fail the same
		# way.
		if ( defined $result->{error} ) {
			$self->{error}          = $result->{error};
			$self->{command_absent} = 1;
			return;
		}

		my $reason;
		if ( $result->{timed_out} ) {
			$reason =
			    'timeout after ' . SIGNIFY_TIMEOUT . ' seconds';
		}
		else {
			# The first line of the diagnostic, without the
			# program name in front.
			($reason) = split /\n/, $result->{stderr} // '';
			$reason //= '';
			$reason =~ s/^\S*signify\S*:\s*//;
			$reason = "exit code $result->{exit_code}"
			    unless length $reason;
		}
		push @reasons, "$keyfile: $reason";
	}

	$self->{error} = "$file: no key verified the signature:\n    "
	    . join( ";\n    ", @reasons );

	return;
}

# $self->verify_manifest(%args):
#	Verify a signed SHA256 manifest, and then verify the digest of
#	each file that the caller names.
#
#	%args:
#		manifest  => $path  # Required: the signed SHA256 file
#		signature => $path  # Optional: default "$manifest.sig"
#		files     => \%map  # Required: manifest key => local path
#
#	A key of files is a key of the manifest, and the module
#	compares it as text. It can be a file name, a file path, or a
#	download URL, whichever the producer of the manifest wrote.
#	The value is the local path that the module digests, so the
#	caller decides where the bytes sit.
#
#	The module must never choose which file to check, so an empty
#	files is a programming error, and the method dies. The method
#	returns the public key file that verified the manifest, or
#	undef on every failure. No file is digested before the
#	manifest verifies.
sub verify_manifest ( $self, %args )
{
	my $manifest = $args{manifest};
	die "manifest is a necessary argument\n"
	    unless defined $manifest;

	my $files = $args{files};
	die "files must be a non-empty hash reference\n"
	    unless ref $files eq 'HASH' && %$files;

	my $signature = $args{signature} // "$manifest.sig";

	my $keyfile = $self->verify( $manifest, $signature );
	return unless defined $keyfile;

	# The bound reads the size on disk, before the content.
	my $size = -s $manifest;
	if ( !defined $size || $size > MAX_MANIFEST_SIZE ) {
		$self->{error} = sprintf '%s: manifest is larger than %d bytes',
		    $manifest, MAX_MANIFEST_SIZE;
		return;
	}

	my $bytes = Fugu::File->read($manifest);
	unless ( defined $bytes ) {
		$self->{error} = "cannot read $manifest";
		return;
	}

	my $digests = $self->_parse_manifest($bytes);
	return unless defined $digests;

	for my $key ( sort keys %$files ) {
		my $expected = $digests->{$key};
		unless ( defined $expected ) {
			$self->{error} = "$manifest does not hold $key";
			return;
		}

		my $path     = $files->{$key};
		my $computed = _digest($path);
		unless ( defined $computed ) {
			$self->{error} = "cannot digest $path: $!";
			return;
		}

		if ( $computed ne $expected ) {
			$self->{error} = "$key: digest mismatch:"
			    . " expected $expected, computed $computed";
			return;
		}
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
	$self->{error} = undef;

	unless ( defined $bytes ) {
		$self->{error} = 'the manifest bytes are undef';
		return;
	}

	if ( $bytes =~ /[^\x00-\xFF]/ ) {
		$self->{error} = 'the manifest holds a character above 255, '
		    . 'and a manifest holds bytes';
		return;
	}

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
	$self->{error} = undef;

	unless ( ref $digests eq 'HASH' ) {
		die "digests must be a hash reference\n";
	}

	unless (%$digests) {
		$self->{error} = 'the digest set is empty';
		return;
	}

	# A manifest is bytes. A key that holds a code point above 255
	# is character data, and print then writes its UTF-8 form: the
	# bytes on disk differ from the key that the caller passed, so
	# the manifest names a file that no reader finds. Perl also
	# warns "Wide character in print". Fugu::OpenPGP fails such a
	# string, and this method must agree.
	for my $key ( sort keys %$digests ) {
		next unless $key =~ /[^\x00-\xFF]/;
		$self->{error} = 'a manifest key holds a character above '
		    . '255, and a manifest holds bytes';
		return;
	}

	my $text = '';
	for my $key ( sort keys %$digests ) {
		unless ( length $key ) {
			$self->{error} = 'a manifest key is empty';
			return;
		}

		if ( $key =~ /[()]/ ) {
			$self->{error} =
			    "a manifest key holds a parenthesis: $key";
			return;
		}

		# The class names the ASCII whitespace only. \s reads a
		# byte above 127 as Latin-1 under the feature set of
		# this file, so it matches U+0085 and U+00A0 and would
		# reject a UTF-8 file name that holds a letter such as
		# a-ogonek. A rotation would then stall on a release
		# asset whose name is valid.
		if ( $key =~ /[ \t\n\r\f\x0B]/ ) {
			$self->{error} =
			    "a manifest key holds whitespace: $key";
			return;
		}

		my $digest = $digests->{$key};
		unless ( defined $digest && $digest =~ /\A[0-9A-Fa-f]{64}\z/ ) {
			$self->{error} = "the digest of $key is not 64 "
			    . 'hexadecimal characters';
			return;
		}

		$text .= "SHA256 ($key) = " . lc($digest) . "\n";
	}

	return $text;
}

# _find_command($name):
#	Resolve an executable path, or return undef. With a name that
#	holds a solidus the sub tests that path only. With a plain
#	name it walks $ENV{PATH} for that name. With no name it walks
#	$ENV{PATH} over the search list: signify-openbsd, then
#	signify. On Debian the plain name signify belongs to an
#	unrelated package, and the OpenBSD-specific name exists only
#	where the real program is installed.
sub _find_command ( $name = undef )
{
	my @names = defined $name ? ($name) : ( 'signify-openbsd', 'signify' );

	for my $candidate (@names) {
		if ( index( $candidate, '/' ) >= 0 ) {
			return $candidate if -f $candidate && -x _;
			next;
		}
		for my $dir ( split /:/, $ENV{PATH} // '' ) {
			next unless length $dir;
			my $path = "$dir/$candidate";
			return $path if -f $path && -x _;
		}
	}

	return;
}

# $self->_run_signify($keyfile, $sigfile, $file):
#	Run one signify(1) verification through Fugu::Process->run.
#	The command is a list, so no argument needs quoting and no
#	argument can become a shell operator. -q suppresses the
#	success line: the caller reads the exit code and the standard
#	error only.
sub _run_signify ( $self, $keyfile, $sigfile, $file )
{
	my @cmd = (
		$self->{command}, '-V', '-q',     '-p',
		$keyfile,         '-x', $sigfile, '-m',
		$file,
	);

	return Fugu::Process->run(
		cmd     => \@cmd,
		timeout => SIGNIFY_TIMEOUT,
	);
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
		unless ( defined $key ) {
			$self->{error} = "cannot parse manifest line: $line";
			return;
		}
		if ( length($hex) != 64 ) {
			$self->{error} =
			    "digest of $key is not 64 hexadecimal characters";
			return;
		}
		if ( exists $digest{$key} ) {
			$self->{error} = "duplicate manifest key: $key";
			return;
		}
		$digest{$key} = lc $hex;
	}

	unless ( keys %digest ) {
		$self->{error} = 'the manifest is empty';
		return;
	}

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
