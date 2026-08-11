#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(EBADF);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;

# Keep the Windows background-start readiness loop instant and hermetic.
$ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS} = 1;

{
    package Local::Runner;
    sub new           { return bless {}, shift }
    sub running_loops { return () }

    package Local::Server;
    sub new { my ( $class, %args ) = @_; return bless { %args }, $class }
    sub run { return 'foreground-ran' }
}

my $original_cwd = getcwd();
my $home         = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { return Local::Server->new(@_) },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => Local::Runner->new,
);

# ---------------------------------------------------------------------------
# _write_startup_pipe_message: the startup pipe writer closes cleanly.
#
# The shipped _close_startup_pipe_writer wrapper exists precisely so this seam
# can be driven from both sides. Every real invocation on this host reports a
# close failure that the caller then classifies via $!, so the "close reported
# success" arm of the guard is only reachable through the documented wrapper
# override. Drive it here so the success arm stays exercised and cannot rot
# into a silent die.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my @closed;
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub {
        my ( $self, $writer ) = @_;
        push @closed, $writer;
        return 1;
    };

    my $path = File::Spec->catfile( $home, 'startup-clean-close.txt' );
    open my $writer, '>', $path or die "Unable to open $path: $!";
    my $payload = "ok|4242|0.0.0.0|7890\n";
    ok(
        $manager->_write_startup_pipe_message( $writer, $payload ),
        '_write_startup_pipe_message succeeds when the startup pipe writer closes cleanly'
    );
    is( scalar @closed, 1, '_write_startup_pipe_message closes the startup pipe writer exactly once' );
    close $writer or die "Unable to close $path: $!";

    open my $reader, '<', $path or die "Unable to read $path: $!";
    my $written = do { local $/; <$reader> };
    close $reader or die "Unable to close $path: $!";
    is( $written, $payload, '_write_startup_pipe_message wrote the whole payload before the clean close' );
}

# The counterpart arm of the same guard: the writer reports a close failure and
# the caller tolerates it once it recognizes the expected errno value.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub {
        $! = EBADF;
        return 0;
    };

    my $path = File::Spec->catfile( $home, 'startup-tolerated-close.txt' );
    open my $writer, '>', $path or die "Unable to open $path: $!";
    ok(
        $manager->_write_startup_pipe_message( $writer, "ok|4243|0.0.0.0|7891\n" ),
        '_write_startup_pipe_message tolerates the expected startup pipe close failure'
    );
    close $writer or die "Unable to close $path: $!";
}

# ---------------------------------------------------------------------------
# _start_web_windows_background: both live sides of the persisted-pid choice.
#
# The confirmed listener pid wins when it is a usable process id, and the
# spawned background pid is the fallback when listener discovery yields a
# falsy pid for the port.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub {
        return ( 'perl.exe', 'dashboard', 'serve' );
    };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7100 };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections       = sub { return 1 };

    {
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (7301) };
        is(
            $manager->_start_web_windows_background( host => '127.0.0.1', port => 7890, workers => 2, ssl => 1 ),
            7301,
            '_start_web_windows_background persists the confirmed listener pid'
        );
        my $state = $manager->web_state;
        is( $state->{pid},     7301,        'the persisted Windows web state keeps the confirmed listener pid' );
        is( $state->{workers}, 2,           'the persisted Windows web state keeps the requested worker count' );
        is( $state->{ssl},     1,           'the persisted Windows web state keeps the requested ssl flag' );
        is( $state->{host},    '127.0.0.1', 'the persisted Windows web state keeps the requested host' );
        my $pidfile = $files->read('web_pid');
        chomp $pidfile if defined $pidfile;
        is( $pidfile, '7301', 'the Windows web pid file records the confirmed listener pid' );
    }

    {
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (0) };
        is(
            $manager->_start_web_windows_background( host => '127.0.0.1', port => 7890 ),
            7100,
            '_start_web_windows_background falls back to the spawned pid when the listener pid is falsy'
        );
        my $state = $manager->web_state;
        is( $state->{pid},     7100, 'the persisted Windows web state falls back to the spawned pid' );
        is( $state->{workers}, 1,    'the persisted Windows web state defaults the worker count' );
        is( $state->{ssl},     0,    'the persisted Windows web state defaults the ssl flag' );
        my $pidfile = $files->read('web_pid');
        chomp $pidfile if defined $pidfile;
        is( $pidfile, '7100', 'the Windows web pid file records the spawned fallback pid' );
    }
}

chdir $original_cwd or die "Unable to chdir to $original_cwd: $!";

done_testing;

__END__

=pod

=head1 NAME

t/119-runtimemanager-coverage-3.t - runtime manager startup-pipe and Windows background-start coverage

=head1 PURPOSE

This test closes the last two untested decision points in the runtime lifecycle
manager: the arm of the startup-pipe writer guard that is taken when the pipe
handle closes cleanly, and both live sides of the process-id choice that the
Windows background web start persists into runtime state.

=head1 WHY IT EXISTS

Both decisions are invisible to the rest of the suite. The startup-pipe close
wrapper always reports a failure that the caller classifies through the errno
value on this host, so the success arm was never executed and a future edit
could have turned it into an unconditional die without any test noticing. The
Windows background start similarly only ever ran with a usable listener pid in
the rest of the suite, leaving its documented fallback to the spawned pid
unproven. This file exists so both decisions stay executable and keep the
lifecycle manager at full branch and condition coverage.

=head1 WHEN TO USE

Use this file when changing how the background web child reports startup back
to its parent, how the startup pipe writer is closed and its errno classified,
or how the Windows background start resolves and persists the web service
process id, worker count, and ssl flag.

=head1 HOW TO USE

Run C<prove -lv t/119-runtimemanager-coverage-3.t> while iterating on the
runtime manager. Keep it green under C<prove -lr t> and inside the coverage
gate before release.

=head1 WHAT USES IT

Developers changing the runtime lifecycle manager, the repository test suite,
and the branch/condition coverage gate all rely on this file.

=head1 EXAMPLES

Example 1:

  prove -lv t/119-runtimemanager-coverage-3.t

Run the runtime-manager startup-pipe and Windows background-start checks alone.

Example 2:

  prove -lr t

Run them as part of the full repository suite before release.

=cut
