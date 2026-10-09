package Developer::Dashboard::CommandRunner;

our $VERSION = '5.73';

use strict;
use warnings;
use Capture::Tiny qw(capture);
use Cwd qw(cwd);
use File::Temp qw(tempfile);
use Time::HiRes qw(sleep time);
use Developer::Dashboard::PerlEnv ();
use Developer::Dashboard::Platform qw(is_windows shell_command_argv);

# DD-947: extracted from CollectorRunner.pm's command-execution cluster
# (run_command through exit_code_from_status) - confirmed zero instance-
# state ($self->{...}) dependency before extraction, so every function
# here takes its own explicit arguments and calls its own siblings
# directly (no $self), matching this project's own established pattern
# for a cohesive, low-coupling extraction (docs/oversized-module-
# extraction-cohesive-cluster-pattern.md). CollectorRunner.pm keeps
# thin one-line forwarder methods at every original call site, so no
# caller anywhere else in the codebase or test suite needed to change.

# run_command(%args)
# Executes a collector command as an owned child process with captured
# stdout/stderr, timeout handling, and complete subtree cleanup. POSIX hosts
# interrupt the blocking wait with SIGALRM; Windows cannot dispatch that signal
# while system() waits, so it spawns the command asynchronously and polls it.
# Input: command string, cwd path, env hash, and timeout_ms.
# Output: list of stdout, stderr, exit_code, and timed_out flag.
sub run_command {
    my (%args) = @_;

    # DD-597: system() below mutates the caller's global $? as a side effect;
    # without this guard that stays set in the caller's process after this
    # sub returns, regardless of the exit code already captured in this sub's
    # own return value.
    local $?;
    my $cmd        = $args{source};
    my $cwd        = $args{cwd};
    my $env        = ref( $args{env} ) eq 'HASH' ? $args{env} : {};
    my $timeout_ms = $args{timeout_ms} || 30_000;

    my $old = cwd();
    chdir $cwd or die "Unable to chdir to $cwd: $!";
    local @ENV{ keys %$env } = values %$env if %$env;
    my %dashboard_env = %{ Developer::Dashboard::PerlEnv->dashboard_child_env() };
    local @ENV{ keys %dashboard_env } = values %dashboard_env;
    my $timed_out = 0;
    my ( $pid_fh, $pidfile ) = tempfile( 'dashboard-collector-command-XXXXXX', TMPDIR => 1, UNLINK => 0 );
    CORE::close $pid_fh or die "Unable to close collector command pid file $pidfile: $!";
    my ( $stdout, $stderr, $exit_code ) = capture {
        my @argv = shell_command_argv( $cmd, login => 0 );

        local $SIG{TERM} = sub { forward_command_signal( $pidfile, 'TERM', 15 ) };
        local $SIG{INT}  = sub { forward_command_signal( $pidfile, 'INT',  2 ) };
        local $SIG{HUP}  = sub { forward_command_signal( $pidfile, 'HUP',  1 ) };
        local $ENV{PERL5OPT} = $ENV{PERL5OPT};
        local $ENV{HARNESS_PERL_SWITCHES} = $ENV{HARNESS_PERL_SWITCHES};
        delete @ENV{qw(PERL5OPT HARNESS_PERL_SWITCHES)};

        if ( is_windows() ) {
            my ( $windows_exit, $expired ) = await_windows_command( $pidfile, $timeout_ms, @argv );
            $timed_out = $expired;
            return $windows_exit;
        }

        my @launcher = command_launcher_argv( $pidfile, @argv );
        local $SIG{ALRM} = sub { die "__COLLECTOR_TIMEOUT__\n" };
        alarm( int( ( $timeout_ms + 999 ) / 1000 ) );
        my $ok = eval {
            system { $launcher[0] } @launcher;
            return exit_code_from_status($?);
        };
        if ($@) {
            die $@ if $@ !~ /__COLLECTOR_TIMEOUT__/;
            $timed_out = 1;
            alarm(0);
            terminate_command_process( await_command_pid($pidfile) );
            return 124;
        }
        alarm(0);
        return $ok;
    };
    alarm(0);
    unlink $pidfile;
    chdir $old or die "Unable to restore cwd to $old: $!";
    return ( $stdout, $stderr, $exit_code, $timed_out );
}

# await_windows_command($pidfile, $timeout_ms, @command_argv)
# Runs one collector command on native Windows without ever blocking inside
# system(). Windows dispatches Perl's alarm emulation only at operation
# boundaries, so the SIGALRM timeout that guards the POSIX path never interrupts
# a synchronous system() and a hung command outlives its timeout. The command
# shell is therefore spawned asynchronously, published through the same pid file
# the POSIX launcher writes for itself, so signal forwarding keeps one source
# of truth, and polled against a deadline. Expiry terminates the whole command
# subtree.
# Input: pid-file path, timeout in milliseconds, and the shell command argv.
# Output: list of the collector exit code and the timed-out flag.
sub await_windows_command {
    my ( $pidfile, $timeout_ms, @argv ) = @_;

    # DD-597: waitpid below reads $? into this sub's own return value, but
    # without this guard the raw $? from that reap stays set in the caller's
    # process after this sub returns.
    local $?;
    my $pid = spawn_windows_command(@argv);
    die "Unable to spawn collector command '$argv[0]': $!\n" if $pid < 1;
    record_command_pid( $pidfile, $pid );

    my $deadline = time() + ( $timeout_ms / 1000 );
    while (1) {
        my $reaped = waitpid( $pid, 1 );
        die "Unable to wait for collector command process $pid: $!\n" if $reaped < 0;
        return ( exit_code_from_status($?), 0 ) if $reaped > 0;
        if ( time() >= $deadline ) {
            terminate_command_process($pid);
            return ( 124, 1 );
        }
        sleep 0.02;
    }
}

# spawn_windows_command(@command_argv)
# Starts one collector command shell with the asynchronous form of system(),
# which returns the new process designator immediately instead of waiting for
# the command to exit. The command inherits the caller's already-redirected
# stdout and stderr, so its output is still captured.
# Input: shell command argv list.
# Output: process designator integer, or a value below one when the spawn fails.
sub spawn_windows_command {
    my (@argv) = @_;
    my $spawned = system 1, @argv;
    return 0 + $spawned;
}

# record_command_pid($pidfile, $pid)
# Publishes an asynchronously spawned command pid through the same pid-file
# contract the POSIX launcher writes for itself, so signal forwarding and
# subtree termination read one source of truth on every platform.
# Input: pid-file path and process id integer.
# Output: true value.
sub record_command_pid {
    my ( $pidfile, $pid ) = @_;
    open my $fh, '>', $pidfile or die "Unable to write collector command pid file $pidfile: $!";
    print {$fh} $pid;
    CORE::close($fh)
      or die "Unable to close collector command pid file $pidfile: $!";
    return 1;
}

# command_launcher_argv($pidfile, @command_argv)
# Builds a small uninstrumented Perl launcher that records its pid before
# becoming the collector command. This preserves system()'s fast native spawn
# path under Devel::Cover while making the command subtree addressable.
# Input: pid-file path followed by the shell command argv.
# Output: launcher argv list.
sub command_launcher_argv {
    my ( $pidfile, @argv ) = @_;
    my $launcher = <<'PERL';
use strict;
use warnings;
use POSIX ();
my $pidfile = shift @ARGV;
open my $pid_fh, '>', $pidfile or die "Unable to write collector command pid file $pidfile: $!";
print {$pid_fh} $$;
close $pid_fh or die "Unable to close collector command pid file $pidfile: $!";
POSIX::setsid() if $^O ne 'MSWin32';
exec { $ARGV[0] } @ARGV or die "Unable to exec collector command: $!";
PERL
    return ( $^X, '-e', $launcher, $pidfile, @argv );
}

# command_pid_from_file($pidfile)
# Reads and validates the direct command pid recorded by the launcher.
# Input: pid-file path.
# Output: positive pid integer or undef.
sub command_pid_from_file {
    my ($pidfile) = @_;
    return if !defined $pidfile || $pidfile eq '' || !-f $pidfile;
    open my $fh, '<', $pidfile or return;
    my $pid = <$fh>;
    close $fh;
    return if !defined $pid || $pid !~ /^(\d+)$/ || $pid < 1;
    return 0 + $pid;
}

# await_command_pid($pidfile)
# Waits briefly for the native-spawned launcher to record its pid. This closes
# the startup race where an immediate timeout or stop signal could otherwise
# arrive before the command subtree became addressable.
# Input: pid-file path.
# Output: positive pid integer or undef after a bounded wait.
sub await_command_pid {
    my ($pidfile) = @_;
    for ( 1 .. 100 ) {
        my $pid = command_pid_from_file($pidfile);
        return $pid if defined $pid;
        sleep 0.01;
    }
    return;
}

# forward_command_signal($pidfile, $signal, $number)
# Cleans up an executing command subtree before preserving the signal semantics
# of the CollectorRunner process that received the external stop request.
# Input: command pid-file path, signal name, and numeric POSIX signal value.
# Output: never returns.
sub forward_command_signal {
    my ( $pidfile, $signal, $number ) = @_;
    terminate_command_process( await_command_pid($pidfile) );
    unlink $pidfile if defined $pidfile && $pidfile ne '';
    if ( !is_windows() ) {
        $SIG{$signal} = 'DEFAULT';
        kill $signal, $$;
    }
    CORE::exit( 128 + $number );
}

# terminate_command_process($pid)
# Terminates and reaps one owned command process plus every descendant. POSIX
# commands are isolated session leaders, while Windows uses taskkill's tree mode.
# Input: direct command child pid integer.
# Output: true value after bounded TERM/KILL cleanup.
sub terminate_command_process {
    my ($pid) = @_;
    local $?;    # DD-1019: guard $? so this sub's own waitpid/system calls never leak a mutated exit status to whatever runs in the caller after it returns.
    return 1 if !defined $pid || $pid !~ /^\d+$/ || $pid < 1;

    if ( is_windows() ) {
        capture { system 'taskkill', '/PID', $pid, '/T', '/F' };
        waitpid( $pid, 0 );
        return 1;
    }

    kill 'TERM', -$pid;
    kill 'TERM', $pid;
    my $reaped = 0;
    for ( 1 .. 20 ) {
        my $waited = waitpid( $pid, 1 );
        if ( $waited == $pid || $waited == -1 ) {
            $reaped = 1;
            last;
        }
        sleep 0.01;
    }
    kill 'KILL', -$pid;
    kill 'KILL', $pid if !$reaped;
    waitpid( $pid, 0 ) if !$reaped;
    return 1;
}

# exit_code_from_status($status)
# Converts a raw child wait status into a collector exit code that stays
# non-zero when the command was terminated by a signal, so a crashed or killed
# run is never mistaken for a successful (exit 0) run.
# Input: raw $? style wait status integer (or undef).
# Output: non-negative exit code integer.
sub exit_code_from_status {
    my ($status) = @_;
    $status = 0 if !defined $status;
    my $signal = $status & 127;
    return 128 + $signal if $signal;
    return $status >> 8;
}

1;

__END__

=head1 NAME

Developer::Dashboard::CommandRunner - spawn, poll, signal, and terminate a
collector-owned external command process

=head1 PURPOSE

Runs one shell command as an owned child process with captured stdout/
stderr, a bounded timeout, and complete subtree cleanup on POSIX and
Windows, and provides the pid-file/signal-forwarding contract that keeps
that cleanup reachable from a signal handler.

=head1 WHY IT EXISTS

Extracted from lib/Developer/Dashboard/CollectorRunner.pm (DD-947, itself
part of DD-641's oversized-module finding): this cluster of ten functions
was confirmed to have zero dependency on CollectorRunner's own instance
state before the move, making it a safe, cohesive, low-coupling piece to
give its own module rather than leaving it inside an already 1963-line
file. CollectorRunner.pm keeps thin one-line forwarder methods at every
original call site, so nothing outside this module changed.

=head1 WHEN TO USE

Use this module directly (as plain function calls, no object) whenever
spawning an owned, timeout-bounded external command with reliable subtree
cleanup is needed - not only from CollectorRunner.

=head1 HOW TO USE

Call C<run_command(source =E<gt> $shell_cmd, cwd =E<gt> $dir, env =E<gt>
\%env, timeout_ms =E<gt> $ms)> for the whole spawn-capture-timeout-cleanup
flow. The other nine functions are its own internal building blocks,
exposed individually because CollectorRunner's forwarders and this
module's own test suite call them directly too.

=head1 WHAT USES IT

lib/Developer/Dashboard/CollectorRunner.pm's forwarder methods, and
t/199-commandrunner-coverage.t.

=head1 EXAMPLES

Example 1:

  my ( $stdout, $stderr, $exit, $timed_out ) = Developer::Dashboard::CommandRunner::run_command(
      source     => 'echo hi',
      cwd        => '/tmp',
      env        => {},
      timeout_ms => 5000,
  );

Example 2:

  Developer::Dashboard::CommandRunner::terminate_command_process($pid);

=cut
