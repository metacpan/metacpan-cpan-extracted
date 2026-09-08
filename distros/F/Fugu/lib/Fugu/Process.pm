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
our $VERSION = '0.3.0';

use Config;
use Fcntl     qw(F_DUPFD F_SETFD FD_CLOEXEC);
use Fugu::CLI qw(EXIT_ERROR);
use IO::Select;
use POSIX       qw(setsid WNOHANG);
use Socket      qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
use Time::HiRes qw(time);

# Fugu::Process - fork, exec, liveness and reaping.
#
# The module keeps no state and has only class methods. Three calls
# start a child: spawn_command leaves it running, run waits for it
# and captures its output, and spawn_peer connects it over a
# socketpair. Each one reports an exec failure exactly, over a
# close-on-exec pipe, and never by a wait-and-guess sleep.

# How often terminate looks again while it waits for a child to go.
use constant POLL_INTERVAL => 0.05;

# The default @INC paths of this perl. Config.pm holds a small key
# set, and the first read of any other key pulls Config_heavy.pl from
# disk. The BEGIN block reads every key that the module needs, so the
# read happens at compile time. A caller can then pledge without the
# rpath promise, and no method opens a file behind it. The table is a
# compile-time constant, not run-time state.
my %DEFAULT_INC;

BEGIN {
	for my $key (qw(privlib archlib sitelib sitearch vendorlib vendorarch))
	{
		my $path = $Config{$key};
		$DEFAULT_INC{$path} = 1 if defined $path && length $path;
	}
}

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
#		env       => \%vars     # Optional: the exact child environment
#		inherit   => \@handles  # Optional: descriptors the child keeps
#
#	The method always waits for the exec to resolve, so a command
#	that does not exist reports its own error message.
#
#	The env option names the environment of the child. The child
#	holds exactly the named variables, and the parent %ENV does not
#	change. Without the option the child inherits the parent
#	environment. An empty hashref gives the child an empty
#	environment. The .pod sidecar states the full contract.
#
#	The inherit option names the open handles that survive the
#	exec, each at its own descriptor number. The child clears
#	FD_CLOEXEC on each one, and then closes every other descriptor
#	from 3 upward. The .pod sidecar states the full contract.
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

	my $inherit = $args{inherit} // [];
	_check_inherit($inherit);

	my $env;
	if ( exists $args{env} ) {
		my $env_error = _check_env( $args{env} );
		return { success => 0, error => $env_error } if $env_error;
		$env = $args{env};
	}

	my ( $pid, $error ) = _fork_exec(
		$cmd, undef, $env,
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

			# After the redirect, before the chdir of
			# _fork_exec.
			_child_fds( $exec_w, $inherit );
		} );
	return { success => 0, error => $error } if $error;

	return { success => 1, pid => $pid };
}

# $class->spawn_peer(%args):
#	Start a peer child over a socketpair, for the OpenBSD pattern
#	of a privileged parent with unprivileged children.
#
#	%args:
#		cmd     => \@command  # Required: the command to execute
#		fd      => $number    # The child end lands here (default: 3)
#		inherit => \@handles  # Optional: extra descriptors, as above
#		env     => \%vars     # Optional: the exact child environment
#
#	The method returns {success => 1, pid => $pid, socket => $fh}
#	with the parent end, or {success => 0, error => $msg}. The
#	child opens its end with open($peer, '+<&=', $fd), so it needs
#	no descriptor argument. The caller wraps the parent end when it
#	wants framing; the module holds no transport. The method makes
#	no session and no process group: a peer child stays in the
#	group of the parent, so one signal reaches the whole set.
sub spawn_peer ( $class, %args )
{
	my $cmd = $args{cmd};
	unless ( ref $cmd eq 'ARRAY' && @$cmd > 0 ) {
		return {
			success => 0,
			error   => 'Command must be non-empty arrayref'
		};
	}

	my $fd      = $args{fd}      // 3;
	my $inherit = $args{inherit} // [];
	_check_inherit($inherit);

	# The standard descriptors end at 2, so a peer number below 3
	# is a programming error, as is a collision with an inherit
	# member.
	die "fd must be a number of 3 or above, not $fd"
	    unless $fd =~ /^\d+$/ && $fd >= 3;
	for my $fh (@$inherit) {
		die "fd $fd collides with an inherit descriptor"
		    if fileno($fh) == $fd;
	}

	my $env;
	if ( exists $args{env} ) {
		my $env_error = _check_env( $args{env} );
		return { success => 0, error => $env_error } if $env_error;
		$env = $args{env};
	}

	socketpair(
		my $parent_end,
		my $child_end,
		AF_UNIX, SOCK_STREAM, PF_UNSPEC
	    )
	    or return {
		success => 0,
		error   => "Cannot create socketpair: $!"
	    };

	my ( $pid, $error ) = _fork_exec(
		$cmd, undef, $env,
		sub ($exec_w) {
			close $parent_end;
			_occupy_fd( $exec_w, $child_end, $fd );
			_child_fds( $exec_w, $inherit, $fd );
		} );

	close $child_end;
	if ($error) {
		close $parent_end;
		return { success => 0, error => $error };
	}

	return { success => 1, pid => $pid, socket => $parent_end };
}

# $class->run(%args):
#	Run a command to completion and capture what it wrote.
#
#	%args:
#		cmd     => \@command  # Required: the command to execute
#		timeout => $seconds   # Optional: kill the child after this long
#		stdin   => $string    # Optional: feed this to the child
#		cwd     => $dir       # Optional: run the child in this directory
#		env     => \%vars     # Optional: the exact child environment
#		passthrough => 0|1    # Optional: let the child write to the terminal
#		new_session => 0|1    # Optional: make the child a group leader
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
#	The env option names the environment of the child, exactly as
#	on spawn_command.
#
#	With passthrough the child inherits the caller's output, and
#	stdout and stderr come back empty. Use it for a command that
#	writes for minutes: an operator who waits needs to see progress,
#	and a captured stream arrives only after the wait is over.
#
#	With new_session the child calls setsid(2) before the
#	redirect. The child then leads a new session and a new process
#	group, and its group id equals its pid. The timeout path then
#	signals the whole group, in both forms of the call. A
#	grandchild that holds a pipe open therefore dies with the
#	child, and the drain ends. setsid(2) removes the controlling
#	terminal, so do not combine new_session with a command that
#	prompts on the terminal under passthrough.
sub run ( $class, %args )
{
	my $cmd = $args{cmd};
	unless ( ref $cmd eq 'ARRAY' && @$cmd > 0 ) {
		return _run_error('Command must be non-empty arrayref');
	}
	my $timeout     = $args{timeout};
	my $input       = $args{stdin};
	my $cwd         = $args{cwd};
	my $new_session = $args{new_session} // 0;

	my $env;
	if ( exists $args{env} ) {
		my $env_error = _check_env( $args{env} );
		return _run_error($env_error) if $env_error;
		$env = $args{env};
	}

	return $class->_run_passthrough( $cmd, $timeout, $input, $cwd, $env,
		$new_session )
	    if $args{passthrough};

	pipe my $out_r, my $out_w
	    or return _run_error("Cannot create pipe: $!");
	pipe my $err_r, my $err_w
	    or return _run_error("Cannot create pipe: $!");
	pipe my $in_r, my $in_w or return _run_error("Cannot create pipe: $!");

	my ( $pid, $error ) = _fork_exec(
		$cmd, $cwd, $env,
		sub ($exec_w) {
			if ($new_session) {
				setsid() or _fail( $exec_w, "setsid: $!" );
			}

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
	    _drain( $out_r, $err_r, $timeout, $pid, $new_session );

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

# $class->_run_passthrough($cmd, $timeout, $input, $cwd, $env, $new_session):
#	Run a child that writes straight to the caller's output. Only
#	the exec confirmation and the exit status come back.
sub _run_passthrough (
	$class, $cmd, $timeout, $input,
	$cwd         = undef,
	$env         = undef,
	$new_session = 0
    )
{
	pipe my $in_r, my $in_w or return _run_error("Cannot create pipe: $!");

	my ( $pid, $error ) = _fork_exec(
		$cmd, $cwd, $env,
		sub ($exec_w) {
			if ($new_session) {
				setsid() or _fail( $exec_w, "setsid: $!" );
			}

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
			$class->terminate(
				$pid,
				grace_period => 1,
				group        => $new_session
			);
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
#		group        => 0|1      # Signal the process group of $pid
#
#	The wait polls with sub-second granularity, so a child that
#	stops at once does not cost a whole second.
#
#	With group each signal goes to the process group of $pid, and
#	$pid must be the pid of a process-group leader. The liveness
#	test is then kill 0 on the group, because a group can outlive
#	its leader, so the group form must not return early on a dead
#	leader. The method cannot wait for a member that is not its
#	child. A member that init has yet to reap can therefore still
#	answer for a moment.
sub terminate ( $class, $pid, %args )
{
	return $class->_terminate_group( $pid, %args ) if $args{group};

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

# $class->_terminate_group($pid, %args):
#	The group form of terminate. Each signal goes to the process
#	group of $pid, with a negative pid on kill. The method returns
#	1 when no member answers kill 0 on the group. It returns 0
#	when a member still answers after the KILL.
#
#	The guard on $pid is a safety boundary. kill with the group id
#	0 signals the group of the caller, and kill with the group id
#	1 can reach far outside the caller. A bad $pid must therefore
#	signal nothing.
sub _terminate_group ( $class, $pid, %args )
{
	return 1 unless defined $pid && $pid =~ /^\d+$/ && $pid > 1;

	return 1 unless _group_alive($pid);

	my $grace_period = $args{grace_period} // 5;
	my $on_kill      = $args{on_kill};

	# Send SIGTERM to the whole group
	my $killed = kill 'TERM', -$pid;
	unless ($killed) {

		# Every member is already dead, or there is no
		# permission
		return _group_alive($pid) ? 0 : 1;
	}

	_wait_group_exit( $pid, $grace_period );

	# If a member is still alive, kill the group with force
	if ( _group_alive($pid) ) {
		kill 'KILL', -$pid;
		_wait_group_exit( $pid, 1 );

		# Final check
		return 0 if _group_alive($pid);
	}

	$on_kill->() if $on_kill;
	return 1;
}

# _group_alive($pid):
#	Report if a member of the process group of $pid still answers
#	kill 0. The check reaps each child member first, so a zombie
#	child of the caller does not count as a live member.
sub _group_alive ($pid)
{
	_reap_group($pid);

	return 1 if kill 0, -$pid;

	# A member can turn into a zombie between the reap above and
	# the check. Reap once more, so a zombie child never outlives
	# the answer "gone".
	_reap_group($pid);

	return 0;
}

# _reap_group($pid):
#	Reap each zombie child of the caller in the process group of
#	$pid. The leader comes first, by its own pid: the Darwin
#	kernel can detach a zombie from its process group, and the
#	group sweep below then misses it.
sub _reap_group ($pid)
{
	waitpid( $pid, WNOHANG );
	1 while waitpid( -$pid, WNOHANG ) > 0;

	return;
}

# _wait_group_exit($pid, $timeout):
#	Wait until no member of the process group of $pid answers, or
#	until the timeout ends. The method returns 1 when the group is
#	gone. It returns 0 on timeout.
sub _wait_group_exit ( $pid, $timeout )
{
	my $deadline = time + $timeout;
	while ( time < $deadline ) {
		return 1 unless _group_alive($pid);
		select undef, undef, undef, POLL_INTERVAL;
	}

	# Final check
	return _group_alive($pid) ? 0 : 1;
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

# _check_inherit($inherit):
#	Validate the inherit argument of a public method, before any
#	pipe and before the fork. A value that is not an array
#	reference, and a member with no descriptor, are programming
#	errors, so both die.
sub _check_inherit ($inherit)
{
	die 'inherit must be an array reference'
	    unless ref $inherit eq 'ARRAY';

	for my $fh (@$inherit) {
		my $fd = ref $fh ? fileno $fh : undef;
		die 'an inherit member has no descriptor'
		    unless defined $fd && $fd >= 0;
	}

	return;
}

# _occupy_fd($exec_w, $fh, $fd):
#	Put the descriptor of $fh on the number $fd, in the child. The
#	exec-failure pipe can already sit on that number, because the
#	parent can hold descriptor holes; the pipe then moves up
#	first. F_DUPFD clears the close-on-exec flag on the dup, and
#	the F_SETFD after the reopen sets it again.
sub _occupy_fd ( $exec_w, $fh, $fd )
{
	if ( fileno($exec_w) == $fd ) {
		my $moved = fcntl( $exec_w, F_DUPFD, $fd + 1 );
		defined $moved
		    or _fail( $exec_w, "Cannot move the exec pipe: $!" );

		# '&=' takes the number without a dup, so this open
		# cannot run out of descriptors. The reopen closes the
		# old number first, which frees $fd. A reopen that
		# fails must not leave an EOF that the parent reads as
		# a success, so the failure goes out over the moved
		# dup.
		unless ( open $exec_w, '>&=', $moved + 0 ) {
			my $message = "Cannot reopen the exec pipe: $!";
			POSIX::write( $moved, $message, length $message );
			POSIX::_exit(127);
		}
		fcntl( $exec_w, F_SETFD, FD_CLOEXEC )
		    or _fail( $exec_w, "Cannot flag the exec pipe: $!" );
	}

	if ( fileno($fh) == $fd ) {

		# The descriptor already sits on $fd, and perl set
		# FD_CLOEXEC on it, so clear the flag on the live
		# handle. The handle lives in the caller until the
		# exec, so nothing closes the descriptor early.
		fcntl( $fh, F_SETFD, 0 )
		    or _fail( $exec_w, "Cannot clear close-on-exec: $!" );
		return;
	}

	# dup2(2) puts the descriptor on $fd with FD_CLOEXEC clear,
	# and no perl handle owns the new number, so nothing closes it
	# before the exec.
	my $duped = POSIX::dup2( fileno($fh), $fd );
	unless ( defined $duped && $duped >= 0 ) {
		_fail( $exec_w, "Cannot dup2 to fd $fd: $!" );
	}
	close $fh;

	return;
}

# _child_fds($exec_w, $inherit, @keep):
#	The descriptor step of the child, between the fork and the
#	exec. Clear FD_CLOEXEC on each inherit member, so the
#	descriptor survives the exec: perl sets the flag on each
#	descriptor above $^F. Then close every other descriptor from 3
#	upward, and keep the standard three, the inherit members, the
#	extra @keep numbers, and the exec-failure pipe. A swept pipe
#	would read as a successful exec in the parent.
#
#	The open-descriptor list of /proc/self/fd or /dev/fd bounds
#	the sweep on Linux and Darwin, where a container can raise
#	_SC_OPEN_MAX to two to the twenty. OpenBSD keeps the range
#	loop: a /dev/fd read needs the rpath promise, the child holds
#	the pledge of the parent, and the OpenBSD soft limit is small.
#	An OpenBSD 7.8 guest measured 128 for the limit, and the full
#	loop under 3 ms. Core Perl wraps neither closefrom(3) nor
#	close_range(2), so the loop is the portable fallback, and it
#	ignores each EBADF: almost every number in the range names
#	nothing.
sub _child_fds ( $exec_w, $inherit, @keep )
{
	my %keep = map { $_ => 1 } fileno($exec_w), @keep;

	for my $fh (@$inherit) {
		fcntl( $fh, F_SETFD, 0 )
		    or _fail( $exec_w, "Cannot clear close-on-exec: $!" );
		$keep{ fileno $fh } = 1;
	}

	if ( $^O ne 'openbsd' ) {
		for my $dir ( '/proc/self/fd', '/dev/fd' ) {
			opendir my $dh, $dir or next;
			my @fds = grep { !/\D/ } readdir $dh;
			closedir $dh;

			for my $fd (@fds) {
				next if $fd < 3 || $keep{$fd};
				POSIX::close($fd);
			}

			return;
		}
	}

	my $max = POSIX::sysconf( POSIX::_SC_OPEN_MAX() );
	unless ( defined $max && $max > 0 ) {

		# A guessed bound would leave a higher descriptor open
		# behind the contract of LIB-PROCESS-3, so the child
		# fails instead.
		_fail( $exec_w, "Cannot read _SC_OPEN_MAX: $!" );
	}

	for my $fd ( 3 .. $max - 1 ) {
		next if $keep{$fd};
		POSIX::close($fd);
	}

	return;
}

# _fork_exec($cmd, $cwd, $env, $redirect):
#	The shared fork-and-exec step. Fork the child and run
#	$redirect in it to set up the standard handles; failures go
#	through _fail. Move the child into $cwd, and give it the
#	environment that $env names. Then exec the command over the
#	close-on-exec failure pipe. Return ($pid, undef) when the exec
#	resolved, or (undef, $error) when the machinery or the exec
#	failed - the child is already reaped in that case.
sub _fork_exec ( $cmd, $cwd, $env, $redirect )
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

		# Neither the redirect nor the chdir reads the
		# environment, so the assignment comes after both and
		# directly before the exec. An undefined $env keeps
		# the inherited environment in place.
		%ENV = %$env if defined $env;

		# The pipe is close-on-exec, so a successful exec closes
		# it and the parent reads EOF. The pipe carries the
		# exact reason, so the perl warning of a failed exec
		# would only repeat it on a stderr that a peer child
		# shares with the parent.
		local $SIG{__WARN__} = sub { };
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

# _check_env($env):
#	Validate the env argument of a public method. Return undef for
#	a valid argument, or the error message. Each public entry calls
#	this once, before any pipe and before the fork, so a bad
#	argument starts nothing.
sub _check_env ($env)
{
	return 'env must be a hashref' unless ref $env eq 'HASH';

	for my $name ( keys %$env ) {
		return 'env holds an empty variable name'
		    unless length $name;
		return 'env name holds an equals sign or a NUL byte'
		    if index( $name, '=' ) >= 0
		    || index( $name, "\0" ) >= 0;

		# A character above 255 cannot reach setenv(3) as one
		# byte. Perl would encode it behind the caller, warn on
		# the child's stderr, and export bytes the caller never
		# named. The boundary rejects it instead.
		return 'env name holds a character above 255'
		    if $name =~ tr/\x00-\xff//c;

		my $value = $env->{$name};
		return "env value of $name is not defined"
		    unless defined $value;
		return "env value of $name is a reference"
		    if ref $value;
		return "env value of $name holds a NUL byte"
		    if index( $value, "\0" ) >= 0;
		return "env value of $name holds a character above 255"
		    if $value =~ tr/\x00-\xff//c;
	}

	return;
}

# _drain($out, $err, $timeout, $pid, $group):
#	Read both pipes until they close. On a timeout, terminate the
#	child and stop. With $group true the terminate signals the
#	whole process group of $pid. Reading both at once matters: a
#	child that fills one pipe blocks until someone drains it, and
#	a reader that takes them in sequence would deadlock there.
sub _drain ( $out, $err, $timeout, $pid, $group = 0 )
{
	my %buffer   = ( $out => '', $err => '' );
	my $select   = IO::Select->new( $out, $err );
	my $deadline = defined $timeout ? time + $timeout : undef;

	while ( $select->count ) {
		my $wait = POLL_INTERVAL;
		if ( defined $deadline ) {
			my $left = $deadline - time;
			if ( $left <= 0 ) {
				Fugu::Process->terminate(
					$pid,
					grace_period => 1,
					group        => $group
				);
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
#	PERL5LIB. The default set is %DEFAULT_INC, read at compile
#	time.
sub _custom_inc_paths()
{
	# Return the @INC paths that are not in the default set.
	# Skip '.' and CODE refs.
	my @custom;
	for my $inc (@INC) {
		next if ref $inc;             # Skip CODE refs
		next if $inc eq '.';          # Skip the current directory
		next if $DEFAULT_INC{$inc};
		push @custom, $inc;
	}

	return @custom;
}

1;
