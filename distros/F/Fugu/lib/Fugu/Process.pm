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

package Fugu::Process;
our $VERSION = '0.1.2';

use Fcntl     qw(F_SETFD FD_CLOEXEC);
use Fugu::CLI qw(EXIT_ERROR);
use IO::Select;
use POSIX       qw(setsid WNOHANG);
use Time::HiRes qw(time);

# Fugu::Process - fork, exec, liveness and reaping.
#
# The module keeps no state and has only class methods. Two calls
# start a child: spawn_command leaves it running, and run waits for it
# and captures its output. Both report an exec failure exactly, over a
# close-on-exec pipe, and never by a wait-and-guess sleep.

# How often terminate looks again while it waits for a child to go.
use constant POLL_INTERVAL => 0.05;

# $class->spawn_command(%args):
#	Fork and execute a command. Optionally run it as a daemon.
#	The method returns a hashref: {pid => $pid, success => 1} on
#	success, or {success => 0, error => $msg} on failure.
#
#	%args:
#		cmd       => \@command  # Required: the command to execute
#		daemonize => 0|1        # Optional: detach from the terminal
#		stdout    => $path|undef # Optional: redirect stdout (default: /dev/null)
#		stderr    => $path|undef # Optional: redirect stderr (default: /dev/null)
#		stdin     => $path|undef # Optional: redirect stdin (default: /dev/null)
#
#	The method always waits for the exec to resolve, so a command
#	that does not exist reports its own error message.
sub spawn_command ( $class, %args )
{
	my $cmd       = $args{cmd};
	my $daemonize = $args{daemonize} // 0;
	my $stdout    = $args{stdout}    // '/dev/null';
	my $stderr    = $args{stderr}    // '/dev/null';
	my $stdin     = $args{stdin}     // '/dev/null';

	unless ( ref $cmd eq 'ARRAY' && @$cmd > 0 ) {
		return {
			success => 0,
			error   => 'Command must be non-empty arrayref'
		};
	}

	my ( $pid, $error ) = _fork_exec(
		$cmd, undef,
		sub ($exec_w) {
			if ($daemonize) {

				# Become the session leader
				setsid() or _fail( $exec_w, "setsid: $!" );
			}

			open STDIN, '<', $stdin
			    or _fail( $exec_w, "Cannot redirect stdin: $!" );
			open STDOUT, '>', $stdout
			    or _fail( $exec_w, "Cannot redirect stdout: $!" );
			open STDERR, '>', $stderr
			    or _fail( $exec_w, "Cannot redirect stderr: $!" );
		} );
	return { success => 0, error => $error } if $error;

	return { success => 1, pid => $pid };
}

# $class->run(%args):
#	Run a command to completion and capture what it wrote.
#
#	%args:
#		cmd     => \@command  # Required: the command to execute
#		timeout => $seconds   # Optional: kill the child after this long
#		stdin   => $string    # Optional: feed this to the child
#		cwd     => $dir       # Optional: run the child in this directory
#		passthrough => 0|1    # Optional: let the child write to the terminal
#
#	The method returns a hashref with success, stdout, stderr,
#	exit_code, timed_out and, on a startup failure, error. It never
#	runs a shell: the command is a list, so no argument needs
#	quoting and no argument can become a shell operator.
#
#	The cwd option moves the child alone. A chdir in the parent
#	would change the meaning of every other relative path in the
#	program, and a second call that ran at the same time would race
#	it. A directory that the child cannot enter is a startup
#	failure with the reason, not a silent run in the wrong place.
#
#	With passthrough the child inherits the caller's output, and
#	stdout and stderr come back empty. Use it for a command that
#	writes for minutes: an operator who waits needs to see progress,
#	and a captured stream arrives only after the wait is over.
sub run ( $class, %args )
{
	my $cmd = $args{cmd};
	unless ( ref $cmd eq 'ARRAY' && @$cmd > 0 ) {
		return _run_error('Command must be non-empty arrayref');
	}
	my $timeout = $args{timeout};
	my $input   = $args{stdin};
	my $cwd     = $args{cwd};

	return $class->_run_passthrough( $cmd, $timeout, $input, $cwd )
	    if $args{passthrough};

	pipe my $out_r, my $out_w
	    or return _run_error("Cannot create pipe: $!");
	pipe my $err_r, my $err_w
	    or return _run_error("Cannot create pipe: $!");
	pipe my $in_r, my $in_w or return _run_error("Cannot create pipe: $!");

	my ( $pid, $error ) = _fork_exec(
		$cmd, $cwd,
		sub ($exec_w) {
			close $out_r;
			close $err_r;
			close $in_w;

			open STDIN, '<&', $in_r
			    or _fail( $exec_w, "Cannot redirect stdin: $!" );
			open STDOUT, '>&', $out_w
			    or _fail( $exec_w, "Cannot redirect stdout: $!" );
			open STDERR, '>&', $err_w
			    or _fail( $exec_w, "Cannot redirect stderr: $!" );
		} );

	close $out_w;
	close $err_w;
	close $in_r;
	if ($error) {
		close $in_w;
		return _run_error($error);
	}

	# Write the input first. A child that reads nothing gets EPIPE
	# and the write stops early, which is not an error here.
	{
		local $SIG{PIPE} = 'IGNORE';
		print {$in_w} $input if defined $input && length $input;
	}
	close $in_w;

	my ( $stdout, $stderr, $timed_out ) =
	    _drain( $out_r, $err_r, $timeout, $pid );

	waitpid $pid, 0;
	my $code = $class->exit_code($?);

	return {
		success   => ( !$timed_out && $code == 0 ) ? 1 : 0,
		stdout    => $stdout,
		stderr    => $stderr,
		exit_code => $code,
		timed_out => $timed_out,
	};
}

# $class->_run_passthrough($cmd, $timeout, $input, $cwd):
#	Run a child that writes straight to the caller's output. Only
#	the exec confirmation and the exit status come back.
sub _run_passthrough ( $class, $cmd, $timeout, $input, $cwd = undef )
{
	pipe my $in_r, my $in_w or return _run_error("Cannot create pipe: $!");

	my ( $pid, $error ) = _fork_exec(
		$cmd, $cwd,
		sub ($exec_w) {
			close $in_w;

			open STDIN, '<&', $in_r
			    or _fail( $exec_w, "Cannot redirect stdin: $!" );
		} );

	close $in_r;
	if ($error) {
		close $in_w;
		return _run_error($error);
	}

	{
		local $SIG{PIPE} = 'IGNORE';
		print {$in_w} $input if defined $input && length $input;
	}
	close $in_w;

	my $timed_out = 0;
	if ( defined $timeout ) {
		unless ( $class->wait_exit( $pid, $timeout ) ) {
			$class->terminate( $pid, grace_period => 1 );
			$timed_out = 1;
		}
	}

	waitpid $pid, 0;
	my $code = $class->exit_code($?);

	return {
		success   => ( !$timed_out && $code == 0 ) ? 1 : 0,
		stdout    => '',
		stderr    => '',
		exit_code => $code,
		timed_out => $timed_out,
	};
}

# $class->exit_code($status):
#	Map a raw system() or $? wait status to a 0-255 exit code. The
#	low byte encodes the terminating signal. The high byte encodes
#	the exit code. system() returns -1 when it cannot start the
#	child at all.
#
#	A caller that passes the raw status on to exit() turns a remote
#	exit code of 1 into exit(256), which the kernel truncates to 0.
#	That silently reports a failed command as a success.
sub exit_code ( $class, $status )
{
	return EXIT_ERROR               if $status == -1;
	return 128 + ( $status & 0x7f ) if $status & 0x7f;
	return $status >> 8;
}

# $class->is_alive($pid):
#	Check if the process is alive (not dead, not a zombie).
#	The method returns 1 if the process is alive. It returns 0 if
#	the process is dead, a zombie, or does not exist.
#
#	The check reaps: a zombie child of the caller is collected
#	here, and the answer is 0. A caller that needs the exit status
#	uses run, or waits itself.
sub is_alive ( $class, $pid )
{
	return 0 unless defined $pid;
	return 0 unless $pid =~ /^\d+$/;

	# First check if the process exists
	return 0 unless kill( 0, $pid );

	# Do not try to wait on the current process
	return 1 if $pid == $$;

	# Try to reap zombies without blocking
	my $result = waitpid( $pid, WNOHANG );

	# If waitpid returns the PID, the process was a zombie.
	# waitpid has now reaped it.
	return 0 if $result == $pid;

	# If waitpid returns -1, the process is not a child of the
	# caller. kill(0) already proved that it exists, so it is alive.
	return 1;
}

# $class->terminate($pid, %args):
#	Stop a process gracefully. Use force if necessary.
#	The method returns 1 if the process is killed or dead. It
#	returns 0 on failure.
#
#	%args:
#		grace_period => $seconds # Time to wait after TERM before KILL (default: 5)
#		on_kill      => sub()    # Runs after a successful kill
#
#	The wait polls with sub-second granularity, so a child that
#	stops at once does not cost a whole second.
sub terminate ( $class, $pid, %args )
{
	return 1 unless $class->is_alive($pid);

	my $grace_period = $args{grace_period} // 5;
	my $on_kill      = $args{on_kill};

	# Send SIGTERM
	my $killed = kill 'TERM', $pid;
	unless ($killed) {

		# The process is already dead, or there is no
		# permission
		return $class->is_alive($pid) ? 0 : 1;
	}

	$class->wait_exit( $pid, $grace_period );

	# If the process is still alive, kill it with force
	if ( $class->is_alive($pid) ) {
		kill 'KILL', $pid;
		$class->wait_exit( $pid, 1 );

		# Final check
		return 0 if $class->is_alive($pid);
	}

	$on_kill->() if $on_kill;
	return 1;
}

# $class->wait_exit($pid, $timeout):
#	Wait for the process to exit.
#	The method returns 1 if the process exits. It returns 0 on
#	timeout.
sub wait_exit ( $class, $pid, $timeout = 30 )
{
	my $deadline = time + $timeout;
	while ( time < $deadline ) {
		return 1 unless $class->is_alive($pid);
		select undef, undef, undef, POLL_INTERVAL;
	}

	# Final check
	return $class->is_alive($pid) ? 0 : 1;
}

# $class->spawn_perl(%args):
#	Spawn a Perl subprocess that inherits the parent's @INC paths.
#	This is a convenience wrapper around spawn_command() to run
#	Perl code.
#
#	%args:
#		code      => $string    # Required: the Perl code to execute
#		args      => \@args     # Optional: arguments for the code
#		The method passes all other args to spawn_command().
#
#	Example:
#		Fugu::Process->spawn_perl(
#			code => 'use MyModule; MyModule->run(@ARGV)',
#			args => [$port, $dir],
#			daemonize => 1,
#		);
sub spawn_perl ( $class, %args )
{
	my $code = delete $args{code}
	    or return { success => 0, error => 'No code specified' };
	my $extra_args = delete $args{args} // [];

	# Build the -I flags for all non-default @INC paths
	my @inc_flags = map { "-I$_" } _custom_inc_paths();

	$args{cmd} = [ $^X, @inc_flags, '-e', $code, @$extra_args ];

	return $class->spawn_command(%args);
}

# _fork_exec($cmd, $cwd, $redirect):
#	The shared fork-and-exec step. Fork the child, run $redirect in
#	it to set up the standard handles (failures go through _fail),
#	move it into $cwd, and exec the command over the close-on-exec
#	failure pipe. Return ($pid, undef) when the exec resolved, or
#	(undef, $error) when the machinery or the exec failed - the
#	child is already reaped in that case.
sub _fork_exec ( $cmd, $cwd, $redirect )
{
	my ( $exec_r, $exec_w ) = _exec_pipe();
	return ( undef, "Cannot create pipe: $!" ) unless $exec_r;

	my $pid = fork;
	unless ( defined $pid ) {
		close $exec_r;
		close $exec_w;
		return ( undef, "Cannot fork: $!" );
	}

	if ( $pid == 0 ) {

		# Child process
		$DB::inhibit_exit = 0;
		close $exec_r;

		$redirect->($exec_w);
		_chdir_or_fail( $exec_w, $cwd );

		# The pipe is close-on-exec, so a successful exec closes
		# it and the parent reads EOF.
		exec { $cmd->[0] } @$cmd
		    or _fail( $exec_w, "Cannot exec $cmd->[0]: $!" );
	}

	# Parent process
	close $exec_w;
	my $exec_error = do { local $/; <$exec_r> };
	close $exec_r;

	if ( defined $exec_error && length $exec_error ) {
		waitpid $pid, 0;
		return ( undef, $exec_error );
	}

	return ( $pid, undef );
}

# _exec_pipe():
#	Make the pipe that carries an exec failure back to the parent.
#	The write end is close-on-exec. Thus a successful exec closes
#	it and the parent reads EOF, while a failure leaves a message
#	behind. The parent learns the outcome as soon as it happens,
#	with no sleep and no guess.
sub _exec_pipe()
{
	pipe my $reader, my $writer or return;
	fcntl( $writer, F_SETFD, FD_CLOEXEC ) or do {
		close $reader;
		close $writer;
		return;
	};

	return ( $reader, $writer );
}

# _chdir_or_fail($writer, $dir):
#	Move the child into the directory, in the window between the
#	fork and the exec. A failure travels back over the same pipe
#	that an exec failure does, so the parent learns the reason and
#	the child never runs where the caller did not ask.
sub _chdir_or_fail ( $writer, $dir )
{
	return unless defined $dir && length $dir;

	chdir $dir or _fail( $writer, "Cannot chdir to $dir: $!" );
	return;
}

# _fail($writer, $message):
#	Report a child-side startup failure and leave. The exit uses
#	POSIX::_exit, so the child never runs the parent's END blocks
#	or flushes the parent's buffers a second time.
sub _fail ( $writer, $message )
{
	syswrite $writer, $message;
	POSIX::_exit(127);
}

# _run_error($message):
#	The result of a run that never reached the child.
sub _run_error ($message)
{
	return {
		success   => 0,
		error     => $message,
		stdout    => '',
		stderr    => '',
		exit_code => EXIT_ERROR,
		timed_out => 0,
	};
}

# _drain($out, $err, $timeout, $pid):
#	Read both pipes until they close. On a timeout, terminate the
#	child and stop. Reading both at once matters: a child that
#	fills one pipe blocks until someone drains it, and a reader
#	that takes them in sequence would deadlock there.
sub _drain ( $out, $err, $timeout, $pid )
{
	my %buffer   = ( $out => '', $err => '' );
	my $select   = IO::Select->new( $out, $err );
	my $deadline = defined $timeout ? time + $timeout : undef;

	while ( $select->count ) {
		my $wait = POLL_INTERVAL;
		if ( defined $deadline ) {
			my $left = $deadline - time;
			if ( $left <= 0 ) {
				Fugu::Process->terminate( $pid,
					grace_period => 1 );
				return ( $buffer{$out}, $buffer{$err}, 1 );
			}
			$wait = $left < POLL_INTERVAL ? $left : POLL_INTERVAL;
		}

		for my $fh ( $select->can_read($wait) ) {
			my $n = sysread $fh, my $chunk, 65536;
			if ( !defined $n ) {
				next if $!{EINTR};
				$select->remove($fh);
				next;
			}
			if ( $n == 0 ) {
				$select->remove($fh);
				next;
			}
			$buffer{$fh} .= $chunk;
		}
	}

	return ( $buffer{$out}, $buffer{$err}, 0 );
}

# _custom_inc_paths:
#	Get the @INC paths that are not part of Perl's default
#	installation. These paths usually come from -I, use lib, or
#	PERL5LIB.
sub _custom_inc_paths()
{
	require Config;

	# Build the set of default Perl lib paths
	my %default_paths;
	for my $key (qw(privlib archlib sitelib sitearch vendorlib vendorarch))
	{
		my $path = $Config::Config{$key};
		$default_paths{$path} = 1 if defined $path && length $path;
	}

	# Return the @INC paths that are not in the default set.
	# Skip '.' and CODE refs.
	my @custom;
	for my $inc (@INC) {
		next if ref $inc;               # Skip CODE refs
		next if $inc eq '.';            # Skip the current directory
		next if $default_paths{$inc};
		push @custom, $inc;
	}

	return @custom;
}

1;
