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

package Fugu::Signer;
our $VERSION = '0.5.1';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use File::Basename qw(basename dirname);
use File::Path     qw(remove_tree);
use File::Spec     ();
use Fugu::Process;

# Fugu::Signer - one shape for the three modules that drive a signing
# command.
#
# The module is the parent class of Fugu::Signify over signify(1), of
# Fugu::OpenPGP over gpg(1), and of Fugu::X509 over openssl(1). It
# holds what the three share: the constructor and the command
# resolution, the three verbs generate, sign and verify, the run
# through Fugu::Process, the key walk of a verification, and the
# failure convention. A subclass holds its file formats, its readers,
# and the arguments of each command line. A consumer that learns one
# type then knows the other two.
#
# A subclass implements five hooks. _command_label and
# _command_defaults name the command, and _generate, _sign and _verify
# hold one command line each. It can also override _reason, which
# reads the diagnostic form of its command, and _stop_helpers, which
# stops a helper process of a temporary directory.
#
# Every private key operation runs in the command. No method takes or
# answers the bytes of a secret half: a secret half enters as a path
# and leaves as a file, so no key byte sits in the heap of a long
# process.
#
# Every recoverable failure returns undef, and error holds the reason.
# The module never logs: the caller decides what to report. A method
# dies for a programming error alone, such as a missing necessary
# argument.

# The time bound of one run, in seconds. A command that a caller named
# can be the wrong program, and each signing command needs
# milliseconds. A subclass that needs a wider bound sets timeout
# before it calls the constructor of this class.
use constant DEFAULT_TIMEOUT => 30;

# The number of names that one temporary directory tries. The name
# holds the process id, so ten cover the calls of one process.
use constant TEMP_TRIES => 10;

# Fugu::Signer->new(%args):
#	Build a generator, a signer and a verifier. The method
#	resolves the command once, and it runs no process.
#
#	%args:
#		command => $command # Optional: a name or an absolute path
#		timeout => $seconds # Optional: the bound of one run
#
#	A subclass takes each argument that its type needs beside
#	these two, and its unit names it.
#
#	The method must not die for an absent command. It sets error
#	instead, and is_available then returns 0. An absent command is
#	an install problem, and a caller reports it as one.
sub new ( $class, %args )
{
	my $timeout = $args{timeout} // DEFAULT_TIMEOUT;
	die "timeout must be a positive number\n"
	    unless $timeout =~ /\A[0-9]+(?:\.[0-9]+)?\z/ && $timeout > 0;

	my $self = bless {
		command_name   => $args{command},
		command        => undef,
		command_absent => 0,
		start_failed   => 0,
		timeout        => $timeout,
		error          => undef,
	}, $class;

	my $command =
	    Fugu::Process->find_command( $args{command},
		$self->_command_defaults );

	if ( defined $command ) {
		$self->{command} = $command;
	}
	else {
		$self->{error}          = $self->_command_error;
		$self->{command_absent} = 1;
	}

	return $self;
}

# $self->is_available:
#	Report if the object can verify. The method returns 1 when it
#	resolved an executable command, and 0 otherwise. It runs no
#	process, and it never dies.
#
#	A subclass that verifies in Perl overrides the method, and it
#	then answers 1 with no command.
sub is_available ($self)
{
	return defined $self->{command} ? 1 : 0;
}

# $self->command:
#	The resolved command path, or undef. An operator who installed
#	the wrong command needs this answer in a diagnostic.
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
#	Report if the most recent failure means that the command never
#	ran: the search list did not resolve it, or it failed to
#	execve(2). An absent command is an install problem, and a
#	failed signature is an integrity problem. The caller must tell
#	them apart.
sub command_absent ($self)
{
	return $self->{command_absent} ? 1 : 0;
}

# $self->generate(%args):
#	Make a key pair with no passphrase. The method returns 1, or
#	undef with the reason in error.
#
#	%args:
#		public => $path # Required: the public half
#		secret => $path # Required: the private half
#
#	A subclass takes each argument that its type needs beside
#	these two, and its unit names it.
#
#	The method refuses a path that exists, so one call never
#	overwrites a key.
#
#	The command writes the secret half into a private directory
#	beside its destination, the method sets the owner-only mode on
#	the file there, and one rename then moves it into place. No
#	wider access exists at any moment, and the bytes of the secret
#	half never enter Perl.
sub generate ( $self, %args )
{
	$self->_begin;

	my ( $public, $secret ) = @args{qw(public secret)};
	die "public and secret are necessary arguments\n"
	    unless defined $public && defined $secret;

	for my $path ( $public, $secret ) {
		return $self->_set_error("the path exists: $path") if -e $path;
	}

	$self->_command or return;

	return $self->_with_temp_dir(
		dirname($secret),
		sub ($dir) {
			my $temp = "$dir/" . basename($secret);
			$self->_generate( %args, secret => $temp ) or return;

			return $self->_set_error(
				"cannot set the mode of $secret: $!")
			    unless chmod 0600, $temp;

			return $self->_set_error(
				"cannot move the secret half to $secret: $!")
			    unless rename $temp, $secret;

			return 1;
		} );
}

# $self->sign(%args):
#	Sign one file with a private half. The method returns 1, or
#	undef with the reason in error.
#
#	%args:
#		secret    => $path # Required: the private half
#		file      => $path # Required: the file to sign
#		signature => $path # Required: the signature file
#
#	The command reads the private half from the path and writes
#	the signature file itself, so no key byte enters Perl. A
#	second call over one signature path replaces the file, because
#	a rotation signs one manifest again.
sub sign ( $self, %args )
{
	$self->_begin;

	my ( $secret, $file, $signature ) = @args{qw(secret file signature)};
	die "secret, file and signature are necessary arguments\n"
	    unless defined $secret && defined $file && defined $signature;

	$self->_check_input( $secret, $file ) or return;
	$self->_command                       or return;
	$self->_sign(%args)                   or return;

	return 1;
}

# $self->verify(%args):
#	Verify one file against a key set, in trust order. The method
#	returns the public key path that verified the signature, or
#	undef with the reason in error.
#
#	%args:
#		keys      => \@paths # Required: public key files
#		file      => $path   # Required: the signed file
#		signature => $path   # Required: the signature file
#
#	The order of keys is the trust order: the current key first,
#	and the next key second. The walk pins one key in one run, so
#	it reads no keyring, no home and no agent of the user. An
#	empty key set is a programming error, so the method dies.
#
#	For a signature that no key verified, the reason names the
#	file, then each key with its own reason. A caller therefore
#	tells a wrong key from an absent key file.
sub verify ( $self, %args )
{
	my ( $keys, $file, $signature ) = @args{qw(keys file signature)};
	die "keys, file and signature are necessary arguments\n"
	    unless defined $keys && defined $file && defined $signature;
	die "keys must be an array reference\n" unless ref $keys eq 'ARRAY';
	die "a verification needs a non-empty keys list\n" unless @$keys;

	$self->_begin;

	$self->_check_input( $file, $signature ) or return;

	my @reasons;
	for my $key (@$keys) {
		my $reason = $self->_verify( $key, %args );
		unless ( defined $reason ) {

			# A hook reports through error, so the reason
			# of an earlier key must not survive as the
			# reason of a call that verified.
			$self->{error} = undef;
			return $key;
		}

		# A run that did not start gives the same answer for
		# every later key. The walk stops there, and that one
		# reason stands alone. Such a failure is no integrity
		# failure, and it must not read as one.
		return $self->_set_error($reason) if $self->{start_failed};

		push @reasons, "$key: $reason";
	}

	return $self->_set_error( _no_key_verified( $file, @reasons ) );
}

# --- the parts that a subclass calls --------------------------------------

# $self->_begin:
#	Start one call: clear the reason, the command_absent flag and
#	the start_failed flag. Every public method calls it first, so
#	error answers the failure of the current call alone.
sub _begin ($self)
{
	$self->{error}          = undef;
	$self->{command_absent} = 0;
	$self->{start_failed}   = 0;

	return;
}

# $self->_set_error($reason):
#	The failure return of every method: the reason goes to error,
#	and the method answers undef. One helper keeps the two steps in
#	one place.
sub _set_error ( $self, $reason )
{
	$self->{error} = $reason;

	return;
}

# $self->_command:
#	The command of one call, or undef with the reason in error. new
#	resolved the command once, so the method reads that answer. It
#	sets command_absent for the call, because a command that never
#	ran is an install problem. It also sets start_failed, because
#	no run of the call can start.
sub _command ($self)
{
	return $self->{command} if defined $self->{command};

	$self->{command_absent} = 1;
	$self->{start_failed}   = 1;

	return $self->_set_error( $self->_command_error );
}

# $self->_command_error:
#	The reason that no command resolved. new and each method write
#	one shape, so a caller reads one string.
sub _command_error ($self)
{
	my $name = $self->{command_name};
	my $named =
	    defined $name && length $name
	    ? $name
	    : join( ', ', $self->_command_defaults );

	return 'no executable ' . $self->_command_label . " command: $named";
}

# $self->_run($args, $what, %options):
#	Run one command of this object, and answer the result of the
#	run. The method returns undef with the reason in error when the
#	run fails.
#
#	$args holds every argument after the command. The command is a
#	list, so no argument needs quoting and no argument can become a
#	shell operator.
#
#	$what names the act that failed, and the reason starts with it.
#	With no $what the reason stands alone, because the key walk of
#	verify writes a prefix of its own.
#
#	%options reaches Fugu::Process->run: stdin feeds the child, env
#	names its whole environment, and cwd runs it in a directory.
#
#	The caller resolves the command with _command before the first
#	run. Fugu::Process answers error for each failure that started
#	no child, such as a bad argument list, a rejected env, a pipe,
#	a fork, a chdir, and the execve(2). The list is open. Each such
#	failure sets start_failed. The execve(2) alone also sets
#	command_absent, because that one failure is an install problem.
sub _run ( $self, $args, $what = undef, %options )
{
	my $result = Fugu::Process->run(
		cmd     => [ $self->{command}, @$args ],
		timeout => $self->{timeout},
		%options,
	);
	return $result if $result->{success};

	my $reason;
	if ( defined $result->{error} ) {

		# The run started no child. The reason of a failed
		# execve(2) starts with "Cannot exec", and each other
		# start failure starts with another form, per
		# LIB-PROCESS-6. An absent command is an install
		# problem, and a pipe or a chdir that failed is not.
		$self->{start_failed}   = 1;
		$self->{command_absent} = 1
		    if $result->{error} =~ /\ACannot exec /;
		$reason = $result->{error};
	}
	elsif ( $result->{timed_out} ) {
		$reason = "timeout after $self->{timeout} seconds";
	}
	else {
		$reason = $self->_reason($result);
	}

	return $self->_set_error( defined $what ? "$what: $reason" : $reason );
}

# $self->_check_input(@paths):
#	Answer 1 when each path is a plain file, or undef with the
#	reason in error. A command method takes paths, and it refuses
#	an input path that is no plain file before it runs the command.
#	One check covers every input of a call, and it names the path
#	that fails.
#
#	A path of keys is the exception: a key that does not read is
#	one reason of the walk of verify.
sub _check_input ( $self, @paths )
{
	for my $path (@paths) {
		next if -f $path;
		return $self->_set_error("not a plain file: $path");
	}

	return 1;
}

# $self->_read_bounded($path, $limit):
#	The bytes of a file under the limit, or undef. The bound reads
#	the size on disk, before the content, so a file that a caller
#	named by mistake never enters memory. A reader of a subclass
#	names the bound of its own format.
sub _read_bounded ( $, $path, $limit )
{
	my $size = -s $path;
	return if !defined $size || $size > $limit;

	open my $fh, '<', $path or return;
	binmode $fh;
	my $bytes = do { local $/; <$fh> };
	close $fh;

	return $bytes // '';
}

# $self->_wide($text):
#	True when the string holds a code point above 255. Such a
#	string is character data and not bytes. Digest::SHA dies on it,
#	and a byte read takes the low byte of each character. A reader
#	of a subclass tests this, and a caller that holds text must
#	encode it first.
sub _wide ( $, $text )
{
	return $text =~ /[^\x00-\xFF]/ ? 1 : 0;
}

# $self->_with_temp_dir($parent, $body):
#	Make a private directory under $parent, run $body over it, and
#	then remove the tree. The method answers what $body answered.
#
#	$parent is the directory that holds the new one, and undef
#	names the temporary directory of the system. generate names the
#	directory of the secret half, because the rename that publishes
#	that half must stay inside one filesystem.
#
#	The directory can carry a secret half, so mkdir takes the
#	owner-only mode. A umask removes a mode bit and adds none, so
#	no wider access exists at any moment.
#
#	The method removes the tree on every exit, also after a die of
#	$body. The eval is no flow control: it holds the removal, and
#	the method then dies again with the same reason.
#
#	It calls _stop_helpers first, because a helper process that the
#	command started under the directory can outlive it.
sub _with_temp_dir ( $self, $parent, $body )
{
	my $dir = $self->_make_dir( $parent // File::Spec->tmpdir ) or return;

	my $answer = eval { $body->($dir) };
	my $why    = $@;

	$self->_stop_helpers($dir);
	remove_tree($dir);

	die $why if $why;

	return $answer;
}

# --- the parts that a subclass holds --------------------------------------

# $self->_command_label:
#	The name of the command in a diagnostic, such as gpg. A
#	subclass holds it, because the name of the module and the name
#	of the command differ.

# $self->_command_defaults:
#	The default search list of the command, in the order of
#	preference. new walks $ENV{PATH} over it when the caller named
#	no command. A subclass holds it.

# $self->_generate(%args):
#	Run the generator of one type. The hook answers 1, or undef
#	with the reason in error. A subclass holds it.
#
#	secret names a path inside a private directory, and the caller
#	of the hook moves that file into place. public names its
#	destination. Each other argument is the argument of the call.

# $self->_sign(%args):
#	Run the signer of one type over secret, file and signature. The
#	hook answers 1, or undef with the reason in error. A subclass
#	holds it.

# $self->_verify($key, %args):
#	Verify file against signature with the one key, and pin that
#	key in the run. The hook answers undef when the key verified,
#	or the reason that it did not. A subclass holds it.
#
#	The hook resolves the command with _command itself, because a
#	subclass can verify with no command. A reason of _run needs no
#	$what: the walk writes the key in front of it.

# $self->_reason($result):
#	The reason of a run that reached the child and failed, and that
#	did not time out. The default takes the first line of the
#	diagnostic, or the exit code. A subclass that reads the
#	diagnostic form of its command overrides the method.
sub _reason ( $, $result )
{
	for my $line ( split /\n/, $result->{stderr} // '' ) {
		return $line if length $line;
	}

	return "exit code $result->{exit_code}";
}

# $self->_stop_helpers($dir):
#	Stop each helper process that the command started under the
#	temporary directory, before the tree goes. The default stops
#	nothing, because most commands start no helper. A subclass
#	whose command starts one overrides the method.
sub _stop_helpers ( $, $ )
{
	return;
}

# --- the parts of this class alone ----------------------------------------

# $self->_make_dir($parent):
#	Make one private directory under $parent, and answer its path.
#	The method answers undef with the reason in error when no name
#	worked. The name holds the process id, so two processes take
#	different names, and the tries cover a repeat inside one
#	process.
#
#	The method sets start_failed, because no run inside the
#	directory can start. It sets no command_absent, because a
#	directory that it cannot make is no install problem.
sub _make_dir ( $self, $parent )
{
	for my $try ( 1 .. TEMP_TRIES ) {
		my $dir = "$parent/.fugu-signer.$$.$try";
		next if -e $dir;
		return $dir if mkdir $dir, 0700;
	}

	$self->{start_failed} = 1;

	return $self->_set_error(
		"cannot make a private directory in $parent: $!");
}

# _no_key_verified($file, @reasons):
#	The error of a verification that no key passed: the file, then
#	one reason for each key of the walk. Each subclass writes this
#	one shape, so a caller reads one shape across the three types.
sub _no_key_verified ( $file, @reasons )
{
	return "$file: no key verified the signature:\n    "
	    . join( ";\n    ", @reasons );
}

1;
