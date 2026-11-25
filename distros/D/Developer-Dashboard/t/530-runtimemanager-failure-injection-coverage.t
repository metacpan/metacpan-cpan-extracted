#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL overrides below must be installed before the module under
# test is compiled. They only misbehave for exact, explicitly registered
# operations, so the failure paths run identically for root and non-root users
# (chmod-based failures are not reliable when the suite runs as root).
our ( %OPEN_FAIL, %OPEN_REDIRECT, %OPEN_AUTOFLUSH, $TIED_OPENED, $PIPE_FAIL, $SEEK_FAIL, $SYSREAD_UNDEF );

BEGIN {
    require Symbol;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            my $key = "$_[1] $_[2]";
            if ( $OPEN_FAIL{$key} && @{ $OPEN_FAIL{$key} } ) {
                my $verdict = shift @{ $OPEN_FAIL{$key} };
                if ( $verdict eq 'fail' ) {
                    $! = 13;
                    return 0;
                }
            }
            if ( my $redirect = $OPEN_REDIRECT{ $_[2] } ) {
                if ( $redirect->[0] eq 'TIED_CLOSE_FAIL' || $redirect->[0] eq 'TIED_PRINT_FAIL' ) {
                    $TIED_OPENED++;
                    $_[0] = Symbol::gensym() if !defined $_[0];
                    tie *{ $_[0] }, $redirect->[0] eq 'TIED_PRINT_FAIL'
                        ? 'Local::PidfilePrintFailure' : 'Local::PidfileCloseFailure';
                    return 1;
                }
                my $opened = CORE::open( $_[0], $redirect->[0], @{$redirect}[ 1 .. $#{$redirect} ] );
                if ( $opened && $OPEN_AUTOFLUSH{ $_[2] } ) {
                    my $selected = select( $_[0] );
                    $| = 1;
                    select($selected);
                }
                return $opened;
            }
        }
        my $handle;
        if ( !defined $_[0] ) {
            $_[0] = Symbol::gensym();
            $handle = $_[0];
        }
        elsif ( !ref $_[0] ) {
            $handle = Symbol::qualify_to_ref( $_[0], scalar caller );
        }
        else {
            $handle = $_[0];
        }
        return CORE::open( $handle, $_[1] ) if @_ == 2;
        return CORE::open( $handle, $_[1], @_[ 2 .. $#_ ] ) if @_ >= 3;
        return CORE::open( $_[0] );
    };
    *CORE::GLOBAL::pipe = sub (**) {
        if ($PIPE_FAIL) {
            $! = 24;
            return 0;
        }
        $_[0] = Symbol::gensym() if !defined $_[0];
        $_[1] = Symbol::gensym() if !defined $_[1];
        return CORE::pipe( $_[0], $_[1] );
    };
    *CORE::GLOBAL::seek = sub (*$$) {
        if ($SEEK_FAIL) {
            $SEEK_FAIL = 0;
            $! = 22;
            return 0;
        }
        return CORE::seek( $_[0], $_[1], $_[2] );
    };
    *CORE::GLOBAL::sysread = sub (*\$$;$) {
        if ($SYSREAD_UNDEF) {
            $SYSREAD_UNDEF = 0;
            $! = 5;
            return undef;
        }
        return CORE::sysread( $_[0], ${ $_[1] }, $_[2], $_[3] ) if @_ > 3;
        return CORE::sysread( $_[0], ${ $_[1] }, $_[2] );
    };
}

{
    package Local::PidfileCloseFailure;
    sub TIEHANDLE { return bless {}, shift }
    sub PRINT      { return 1 }
    sub CLOSE      { $! = 5; return 0 }
}

{
    package Local::PidfilePrintFailure;
    sub TIEHANDLE { return bless {}, shift }
    sub PRINT { $! = 5; return 0 }
    sub CLOSE { return 1 }
}

# A Perl-made full device: a PerlIO::via layer whose every write fails
# with ENOSPC, the way a write to Linux /dev/full does. Opened as
# '>:via(Local::FullDevice):perlio' it gives the code under test a real,
# untied filehandle with a buffer layer on top, so with autoflush on the
# print itself fails and CORE::close reports the failure quietly, on
# every platform, with no /dev/full needed.
{
    package Local::FullDevice;
    sub PUSHED { my ($class) = @_; return bless {}, $class }
    sub WRITE  { $! = 28; return -1 }
    sub FLUSH  { return 0 }
}

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Capture::Tiny qw(capture);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::GoRoutine ();

{
    package Local::FailRunner;
    sub new { return bless {}, shift }
    sub running_loops { return (); }
}

my $cwd = getcwd();
my $work = tempdir( CLEANUP => 1 );
chdir $work or die "Unable to chdir to $work: $!";
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $paths   = Developer::Dashboard::PathRegistry->new( home => $home );
my $files   = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config  = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my %new_args = (
    app_builder => sub { die "app builder must not run\n" },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => Local::FailRunner->new,
);
my $manager = Developer::Dashboard::RuntimeManager->new(%new_args);
my $stub_collectors = bless {}, 'Local::StubCollectors';
is( Developer::Dashboard::RuntimeManager->new( %new_args, collectors => $stub_collectors )->{collectors}, $stub_collectors, 'an injected collectors object is kept' );
isa_ok( $manager->{collectors}, 'Developer::Dashboard::Collector', 'a default collectors object is built when none is injected' );

# Runs one failure-injection block while capturing its output, then returns the
# exception text (empty string when it survives). Capture::Tiny restores the
# caller's standard handles before TAP output resumes.
sub capture_failure {
    my ($code) = @_;
    my $error = '';
    my ( $stdout, $stderr, $exit ) = capture {
        eval { $code->(); 1 } or $error = $@ || 'unknown failure';
    };
    return $error;
}

{
    no warnings 'redefine';

    # Windows background start where the listener pid is not truthy, so the
    # spawned pid is used as the fallback in the persisted state.
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { 1 };
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub { return ('noop') };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 4242 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (0) };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_stability_polls = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_runtime_poll_interval = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { return 0 };
    my $pid = $manager->_start_web_windows_background( host => '127.0.0.1', port => 47993, workers => 1, ssl => 0 );
    is( $pid, 4242, 'the Windows background start falls back to the spawned pid when the listener pid is not truthy' );
}

# GoRoutine collector-supervisor start failures.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    $manager->_write_collector_supervisor_state( { watched_names => ['alpha'] } );
    my $pidfile = $manager->_collector_supervisor_pidfile;

    {
        local *Developer::Dashboard::GoRoutine::spawn = sub { die "native spawn failure\n" };
        eval { $manager->_start_collector_supervisor };
        like( $@, qr/native spawn failure/, 'the collector supervisor reports native GoRoutine spawn failures' );
    }
    {
        local *Developer::Dashboard::GoRoutine::spawn = sub { return 5151 };
        local $OPEN_FAIL{"> $pidfile"} = ['fail'];
        eval { $manager->_start_collector_supervisor };
        like( $@, qr/Unable to write \Q$pidfile\E/, 'the supervisor start dies when its pidfile cannot be written' );
    }
    {
        my $full = File::Spec->catfile( $work, 'collector-supervisor-full-device' );
        my $sink = File::Spec->catfile( $work, 'collector-supervisor-full-device-sink' );
        local *Developer::Dashboard::RuntimeManager::_collector_supervisor_pidfile = sub { return $full };
        local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
        local *Developer::Dashboard::GoRoutine::spawn = sub { return 5152 };
        local $OPEN_REDIRECT{$full} = [ '>:via(Local::FullDevice):perlio', $sink ];
        local $OPEN_AUTOFLUSH{$full} = 1;
        my ( $write_error, $write_stderr );
        ( undef, $write_stderr ) = capture {
            eval { $manager->_start_collector_supervisor };
            $write_error = $@;
        };
        like( $write_error, qr/Unable to write collector supervisor pid to/, 'the supervisor start surfaces an immediate pidfile print failure' );
        is( $write_stderr, '', 'the supervisor closes a failed pidfile write without leaking a close warning' );
        $manager->_cleanup_collector_supervisor_files;

        $manager->_write_collector_supervisor_state( { watched_names => ['alpha'] } );
        $OPEN_REDIRECT{$full} = ['TIED_CLOSE_FAIL'];
        local $TIED_OPENED = 0;
        eval { $manager->_start_collector_supervisor };
        like( $@, qr/Unable to close collector supervisor pidfile/, 'the supervisor start surfaces a buffered pidfile close failure' );
        is( $TIED_OPENED, 1, 'the close-failure filehandle was opened through the deterministic tie' );
        $manager->_cleanup_collector_supervisor_files;
    }
}

# The same two failures again through tied handles, on all hosts.
# The test callback supplies a real tied handle to the unmodified production
# print and CORE::close operations, with the watched loop process stubbed.
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::GoRoutine::spawn = sub { return 5153 };
    $manager->_write_collector_supervisor_state( { watched_names => ['alpha'] } );
    my $pidfile = $manager->_collector_supervisor_pidfile;
    {
        local $OPEN_REDIRECT{$pidfile} = ['TIED_PRINT_FAIL'];
        my $error = capture_failure(sub { $manager->_start_collector_supervisor });
        like( $error, qr/Unable to write collector supervisor pid to/,
            'supervisor reports immediate pidfile print failure on all hosts' );
    }
    {
        local $OPEN_REDIRECT{$pidfile} = ['TIED_CLOSE_FAIL'];
        my $error = capture_failure(sub { $manager->_start_collector_supervisor });
        like( $error, qr/Unable to close collector supervisor pidfile/,
            'supervisor reports pidfile close failure on all hosts' );
    }
}

# stdio redirection failures in the supervisor and web children.
{
    my $null    = File::Spec->devnull;
    my $clog    = $files->collector_log;
    my $dlog    = $files->dashboard_log;
    my $writer;
    pipe( my $r, $writer ) or die "pipe: $!";

    for my $case (
        [ 'supervisor stdin',  sub { $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 1 ) }, "< $null",  ['fail'] ],
        [ 'supervisor stdout', sub { $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 1 ) }, ">> $clog", ['fail'] ],
        [ 'supervisor stderr', sub { $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 1 ) }, ">> $clog", [ 'pass', 'fail' ] ],
        [ 'web stdin',         sub { $manager->_run_web_child( $writer, '127.0.0.1', 47994, detach => 0, redirect => 1 ) }, "< $null",  ['fail'] ],
        [ 'web stdout',        sub { $manager->_run_web_child( $writer, '127.0.0.1', 47994, detach => 0, redirect => 1 ) }, ">> $dlog", ['fail'] ],
        [ 'web stderr',        sub { $manager->_run_web_child( $writer, '127.0.0.1', 47994, detach => 0, redirect => 1 ) }, ">> $dlog", [ 'pass', 'fail' ] ],
      )
    {
        my ( $label, $code, $key, $queue ) = @{$case};
        local $OPEN_FAIL{$key} = [ @{$queue} ];
        my $err = capture_failure($code);
        like( $err, qr/\S/, "$label redirect failure is reported" );
    }
}

# State file write failures.
{
    no warnings 'redefine';
    my $tmp = File::Spec->catfile( $work, 'pending-state.tmp' );
    local *Developer::Dashboard::RuntimeManager::_pending_collector_supervisor_state_file = sub { return $tmp };
    local *Developer::Dashboard::RuntimeManager::_pending_web_state_file = sub { return $tmp };
    local $OPEN_FAIL{">:raw $tmp"} = ['fail'];
    eval { $manager->_write_collector_supervisor_state( {} ) };
    like( $@, qr/Unable to write \Q$tmp\E/, 'the supervisor state write dies when the pending file cannot be opened' );
    local $OPEN_FAIL{">:raw $tmp"} = ['fail'];
    eval { $manager->_write_web_state( {} ) };
    like( $@, qr/Unable to write \Q$tmp\E/, 'the web state write dies when the pending file cannot be opened' );
}

# Startup pipe writer edge cases.
{
    CORE::open( my $closed, '>', File::Spec->catfile( $work, 'closed.out' ) ) or die $!;
    close $closed;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $manager->_write_startup_pipe_message( $closed, 'hello' ) };
    like( $@, qr/Unable to write startup pipe/, 'a closed startup handle fails the buffered print path' );

    local $SIG{PIPE} = 'IGNORE';
    pipe( my $reader, my $writer ) or die "pipe: $!";
    close $reader;
    eval { $manager->_write_startup_pipe_message( $writer, 'hello' ) };
    like( $@, qr/Unable to write startup pipe/, 'a broken startup pipe fails the syswrite path' );
}

# Log follow setup failures.
{
    my $log = File::Spec->catfile( $work, 'follow.log' );

    {
        local $OPEN_FAIL{">> $log"} = ['fail'];
        eval { $manager->_follow_log_file( file => $log ) };
        like( $@, qr/Unable to create \Q$log\E/, 'follow dies when the missing log cannot be created' );
    }
    {
        local $OPEN_FAIL{"< $log"} = [ 'pass', 'fail' ];
        eval { $manager->_follow_log_file( file => $log ) };
        like( $@, qr/Unable to read \Q$log\E/, 'follow dies when the freshly created log cannot be reopened' );
    }

    CORE::open( my $fh, '>', $log ) or die $!;
    print {$fh} "seed\n";
    close $fh;
    {
        local $SEEK_FAIL = 1;
        eval { $manager->_follow_log_file( file => $log, start_pos => 2 ) };
        like( $@, qr/Unable to seek \Q$log\E/, 'follow dies when seeking to the start offset fails' );
    }
    {
        local $SEEK_FAIL = 1;
        eval { $manager->_follow_log_file( file => $log ) };
        like( $@, qr/Unable to seek \Q$log\E/, 'follow dies when seeking to the end fails' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::sleep = sub { die "loop-finished\n" };
        local $SYSREAD_UNDEF = 1;
        eval { $manager->_follow_log_file( file => $log ) };
        like( $@, qr/loop-finished/, 'follow treats an undefined sysread result as no data and sleeps' );
    }
}

# Socket table and proc file open failures after the readability guard.
{
    no warnings 'redefine';
    my $table = File::Spec->catfile( $work, 'tcp-table' );
    CORE::open( my $fh, '>', $table ) or die $!;
    print {$fh} "header\n";
    close $fh;
    local *Developer::Dashboard::RuntimeManager::_listener_socket_table_paths = sub { return ($table) };
    local $OPEN_FAIL{"< $table"} = ['fail'];
    is_deeply( [ $manager->_listener_socket_inodes_for_port(8080) ], [], 'an unopenable socket table is skipped' );
    local $OPEN_FAIL{"< $table"} = ['fail'];
    is( $manager->_slurp_proc_file($table), undef, 'an unopenable proc file reads as undef' );
}

# procfs availability is decided from an overridable root.
{
    local $Developer::Dashboard::RuntimeManager::PROCFS_ROOT = File::Spec->catdir( $work, 'no-such-proc' );
    is( $manager->_procfs_available, 0, 'procfs is reported unavailable when the root does not exist' );
}
is( $manager->_procfs_available, -d '/proc' ? 1 : 0, 'procfs availability matches host' );

chdir $cwd;
done_testing;

__END__

=pod

=head1 NAME

t/530-runtimemanager-failure-injection-coverage.t - failure-injection coverage for Developer::Dashboard::RuntimeManager

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It drives the pipe, open, seek, sysread and syswrite failure paths of RuntimeManager through BEGIN-time CORE::GLOBAL overrides that fail only for exactly registered operations. Synchronous output capture keeps TAP isolated while failure exceptions are inspected.

=head1 WHY IT EXISTS

It exists because the lib/ coverage gate requires every branch to be genuinely executed with no uncoverable annotations, and these failure paths cannot be reached by chmod tricks when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change start_web, the collector supervisor start, the child stdio redirection, the state-file writers, the log follower, or the procfs readers in RuntimeManager.

On every host, the registered open redirect also checks immediate and
buffered supervisor pidfile write failures, through a Perl-made full
device (a PerlIO::via layer whose writes fail) in place of C</dev/full>.

=head1 HOW TO USE

Run it in the dev Docker container with C<d2 docker compose exec -T dev prove -lv t/530-runtimemanager-failure-injection-coverage.t>. The overrides are keyed by "mode path" and consume a queue of pass/fail verdicts, so a test can let the first open succeed and fail the second.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<d2 docker compose exec -T dev prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec -T dev prove -lv t/530-runtimemanager-failure-injection-coverage.t

Run the failure-injection tests by themselves.

Example 2:

  d2 docker compose exec -T -e HARNESS_PERL_SWITCHES=-MDevel::Cover dev prove -lv t/530-runtimemanager-failure-injection-coverage.t

Confirm the injected failure branches are reported as covered.

=cut
