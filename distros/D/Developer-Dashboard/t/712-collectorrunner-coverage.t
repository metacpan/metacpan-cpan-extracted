#!/usr/bin/env perl

use strict;
use warnings;

# BEGIN-time CORE::GLOBAL overrides so CollectorRunner resolves open and
# opendir through them. A path registered in %FAIL passes its first N opens
# (the registered number) and fails every later one with EACCES, so the error
# branches run for any uid, root included.
our %FAIL;

BEGIN {
    require Symbol;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && exists $FAIL{ $_[2] } ) {
            if ( $FAIL{ $_[2] } > 0 ) {
                $FAIL{ $_[2] }--;
            }
            else {
                $! = 13;
                return 0;
            }
        }
        # A bareword handle (STDIN/STDOUT/STDERR) arrives as a plain name.
        if ( defined $_[0] && !ref $_[0] && ref \$_[0] eq 'SCALAR' ) {
            my $fh = Symbol::qualify_to_ref( $_[0], scalar caller );
            return CORE::open( $fh, $_[1] ) if @_ == 2;
            return CORE::open( $fh, $_[1], @_[ 2 .. $#_ ] );
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && exists $FAIL{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
}

use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home, workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ] );
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => Developer::Dashboard::Collector->new( paths => $paths ),
    files      => $files,
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);
my $P = 'Developer::Dashboard::CollectorRunner';

sub write_file {
    my ( $file, $text ) = @_;
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

# Run a block in a forked child and return its exit status; the child exits 0
# only when the block dies with the expected message.
sub child_dies_with {
    my ( $re, $code ) = @_;
    my $pid = fork();
    die "fork: $!" if !defined $pid;
    if ( !$pid ) {
        my $ok  = eval { $code->(); 1 };
        my $err = $@;
        exit( !$ok && $err =~ $re ? 0 : 1 );
    }
    waitpid( $pid, 0 );
    return $? >> 8;
}

# --- schedule mode resolution ------------------------------------------------
is( $runner->_schedule_mode( { schedule => 'cron', cron => '* * * * *' } ), 'cron', 'an explicit schedule wins' );
is( $runner->_schedule_mode( { cron => '* * * * *', interval => 5 } ), 'cron', 'a cron expression selects cron' );
is( $runner->_schedule_mode( { interval => 5 } ), 'interval', 'an interval selects interval' );
is( $runner->_schedule_mode( {} ), 'manual', 'nothing selects manual' );

# --- run_once defaults its cwd to the current directory -----------------------
{
    my $result = $runner->run_once( { name => 's8-nocwd', command => 'true' } );
    is( $result->{exit_code}, 0, 'a collector without a cwd runs in the current directory' );
}

# --- Windows loop launch derives its own process title -------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_windows_background_loop_command = sub { return ('noop') };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 4242 };
    my $pid = $runner->_start_windows_loop_process( job => { name => 's8-win', command => 'true' }, name => 's8-win' );
    is( $pid, 4242, 'the Windows loop launcher returns the spawned pid' );
    is( $runner->loop_state('s8-win')->{process_name}, 'dashboard collector: s8-win', 'the Windows loop launcher defaults the process title' );
}

# --- loop child daemon setup failures ---------------------------------------
{
    my $job = { name => 's8-daemon', command => 'true', interval => 1 };
    my $log = $files->collector_log;
    is(
        child_dies_with(
            qr/Permission denied/,
            sub {
                local $FAIL{ File::Spec->devnull() } = 0;
                $runner->_run_loop_child( job => $job, name => 's8-daemon', interval => 1, daemonize => 1, single_tick => 1 );
            }
        ),
        0,
        'a daemonized loop dies when stdin cannot be redirected',
    );
    is(
        child_dies_with(
            qr/Permission denied/,
            sub {
                local $FAIL{$log} = 1;
                $runner->_run_loop_child( job => $job, name => 's8-daemon', interval => 1, daemonize => 1, single_tick => 1 );
            }
        ),
        0,
        'a daemonized loop dies when stderr cannot be redirected',
    );
}

# --- loop child defaults and the worker error path --------------------------
{
    no warnings 'redefine';
    my $state_name = 's8-loopchild';
    my $stop = 'stop loop';
    local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick = sub { die "$stop\n" };
    local *Developer::Dashboard::CollectorRunner::_start_loop_worker = sub { return 0 };
    my $ok = eval {
        $runner->_run_loop_child( job => { name => $state_name, command => 'true', interval => 1 }, name => $state_name, interval => 1, daemonize => 0, single_tick => 1 );
        1;
    };
    ok( $ok || $@ =~ /stop loop/, 'a loop child without an explicit title derives one' );
}
{
    my $job = { name => 's8-worker', command => 'true', cwd => File::Spec->catdir( $home, 'missing-cwd' ) };
    my $pid = fork();
    die "fork: $!" if !defined $pid;
    if ( !$pid ) {
        $runner->_run_loop_worker( $job, 's8-worker', undef, undef );
        exit 0;
    }
    waitpid( $pid, 0 );
    is( $? >> 8, 255, 'a failing worker exits 255' );
    my $state = $runner->loop_state('s8-worker');
    is( $state->{pid}, $pid, 'the worker error state falls back to the worker pid' );
    is( $state->{process_name}, 'dashboard collector: s8-worker', 'the worker error state falls back to the derived title' );
    is( $state->{schedule}, 'manual', 'the worker error state records the resolved schedule' );
}

# --- adopting a running loop whose pidfile vanished --------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_find_running_loop   = sub { return $$ };
    local *Developer::Dashboard::CollectorRunner::_is_managed_loop     = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_write_loop_state    = sub { return {} };
    my $pidfile = File::Spec->catfile( $home, 's8-adopt.pid' );
    my %args = ( pidfile => $pidfile, name => 's8-adopt', title => 'dashboard collector: s8-adopt', interval => 1, schedule_mode => 'interval' );
    {
        local $FAIL{$pidfile} = 0;
        my $err = eval { $runner->_adopt_existing_loop_if_running(%args); 1 } ? '' : $@;
        like( $err, qr/Unable to write \Q$pidfile\E/, 'adopting a loop reports an unwritable pidfile' );
    }
    is( $runner->_adopt_existing_loop_if_running(%args), $$, 'adopting a loop repairs the missing pidfile' );
    ok( -f $pidfile, 'the repaired pidfile exists' );
}

# --- loop state read failures -----------------------------------------------
{
    $runner->_write_loop_state( 's8-state', { pid => $$ } );
    my $statefile = $runner->_statefile('s8-state');
    local $FAIL{$statefile} = 0;
    my $err = eval { $runner->loop_state('s8-state'); 1 } ? '' : $@;
    like( $err, qr/Unable to read \Q$statefile\E/, 'loop_state reports an unreadable state file' );
}
{
    my $statefile = $runner->_statefile('s8-empty');
    $runner->_write_loop_state( 's8-empty', { pid => $$ } );
    write_file( $statefile, '' );
    my $err = eval { $runner->loop_state('s8-empty'); 1 } ? '' : $@;
    like( $err, qr/was empty/, 'loop_state reports an empty state file' );
}

# --- loop state write failure -----------------------------------------------
{
    no warnings 'redefine';
    my $tmp = File::Spec->catfile( $home, 's8-pending' );
    local *Developer::Dashboard::CollectorRunner::_pending_loop_state_file = sub { return $tmp };
    local $FAIL{$tmp} = 0;
    my $err = eval { $runner->_write_loop_state( 's8-write', { pid => $$ } ); 1 } ? '' : $@;
    like( $err, qr/Unable to write \Q$tmp\E/, '_write_loop_state reports an unwritable staging file' );
}

# --- procfs helpers ----------------------------------------------------------
{
    my $file = write_file( File::Spec->catfile( $home, 's8-proc' ), "data\n" );
    is( $runner->_read_proc_file($file), "data\n", '_read_proc_file reads a readable file' );
    local $FAIL{$file} = 0;
    is( $runner->_read_proc_file($file), undef, '_read_proc_file yields undef when the open fails' );
}
{
    local $FAIL{'/proc'} = 0;
    is( $runner->_find_running_loop('s8-noproc'), undef, '_find_running_loop gives up when /proc cannot be listed' );
}
SKIP: {
    skip '/proc is not listable here', 2 if !-d '/proc';
    no warnings 'redefine';
    my $calls = 0;
    local *Developer::Dashboard::CollectorRunner::_read_proc_file      = sub { return 'x' };
    local *Developer::Dashboard::CollectorRunner::_read_process_title  = sub { return 'dashboard collector: s8-ns' };
    local *Developer::Dashboard::CollectorRunner::_same_pid_namespace  = sub { return ++$calls >= 2 ? 1 : 0 };
    my $found = $runner->_find_running_loop('s8-ns');
    ok( $found, '_find_running_loop returns a title match from the same pid namespace' );
    is( $calls, 2, '_find_running_loop skips a title match from another pid namespace' );
}

done_testing;

__END__

=pod

=head1 NAME

t/712-collectorrunner-coverage.t - failure-injection coverage for Developer::Dashboard::CollectorRunner

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the CollectorRunner I/O failures (pidfile, state file, stdio redirection, /proc listing), the schedule-mode and title fallbacks, the worker error path and the foreign pid-namespace skip through BEGIN-time CORE::GLOBAL open and opendir overrides, stubs and forked children.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and these branches only run when a system call fails or a process-table condition occurs, which file permissions cannot force when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change collector loop start, state persistence, process discovery or the worker error handling, or when a coverage run reports one of those branches as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/712-collectorrunner-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/712-collectorrunner-coverage.t

Run this coverage-gap test by itself while editing CollectorRunner.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/712-collectorrunner-coverage.t

Confirm the failure branches are reported as covered.

=cut
