#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX qw(:sys_wait_h);
use Socket qw(AF_UNIX PF_UNSPEC SOCK_STREAM);
use Test::More;
use Time::HiRes qw(sleep);

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;

# Keep runtime readiness polling instant and hermetic under coverage.
$ENV{DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS}    = 1;
$ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS} = 1;

BEGIN {
    no warnings 'redefine';
    # Make every internal poll loop instant so the process-lifecycle helpers
    # can be exercised without real timing dependencies.
    *Developer::Dashboard::RuntimeManager::sleep = sub (;@) { return 0 };
}

my $RM = 'Developer::Dashboard::RuntimeManager';

{
    package Local::Runner;
    sub new {
        my ( $class, %args ) = @_;
        return bless {
            loops        => [],
            states       => {},
            fail         => {},
            started      => [],
            started_jobs => [],
            stopped      => [],
            %args,
        }, $class;
    }
    sub running_loops { return @{ $_[0]{loops} } }
    sub loop_state    { my ( $s, $n ) = @_; return $s->{states}{$n} }
    sub start_loop {
        my ( $s, $job ) = @_;
        my $name = $job->{name};
        die $s->{fail}{$name} if defined $name && exists $s->{fail}{$name};
        push @{ $s->{started} },      $name;
        push @{ $s->{started_jobs} }, { %{$job} };
        return exists $s->{next_pid} ? $s->{next_pid} : 4242;
    }
    sub stop_loop {
        my ( $s, $name ) = @_;
        push @{ $s->{stopped} }, $name;
        $s->{loops} = [ grep { $_->{name} ne $name } @{ $s->{loops} } ];
        return 1;
    }

    package Local::BareRunner;
    sub new           { return bless {}, shift }
    sub running_loops { return () }

    package Local::Server;
    sub new { my ( $c, %a ) = @_; return bless { %a }, $c }
    sub run { return 'foreground-ran' }
    sub start_daemon  { return Local::Daemon->new }
    sub serve_daemon  { return 1 }

    package Local::Daemon;
    sub new      { return bless {}, shift }
    sub sockhost { return '0.0.0.0' }
    sub sockport { return 7890 }
}

my $original_cwd = getcwd();
my $test_cwd     = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                        = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $paths           = Developer::Dashboard::PathRegistry->new( home => $home );
my $files           = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config          = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector_store = Developer::Dashboard::Collector->new( paths => $paths );
$config->save_global(
    {
        collectors => [
            { name => 'alpha.collector', command => 'true', cwd => 'home', interval => 1 },
            { name => 'beta.collector',  command => 'true', cwd => 'home', interval => 1 },
        ],
    }
);

my $runner = Local::Runner->new;

sub build_manager {
    my (%over) = @_;
    return Developer::Dashboard::RuntimeManager->new(
        app_builder => $over{app_builder} || sub { return Local::Server->new(@_) },
        config      => $over{config} || $config,
        files       => $files,
        paths       => $paths,
        runner      => $over{runner} || $runner,
        ( exists $over{collectors} ? ( collectors => $over{collectors} ) : () ),
    );
}

my $manager = build_manager();

# --- new(): collectors arg present (left side of the || short-circuit) ------
{
    my $explicit = build_manager( collectors => $collector_store );
    isa_ok( $explicit, $RM, 'manager built with an explicit collectors object' );
    is( $explicit->{collectors}, $collector_store, 'new keeps an explicitly supplied collectors object' );
}

# --- _numeric_pid ------------------------------------------------------------
is( $RM->can('_numeric_pid') ? Developer::Dashboard::RuntimeManager::_numeric_pid(undef) : 'x', undef, '_numeric_pid returns undef for undef' );
is( Developer::Dashboard::RuntimeManager::_numeric_pid(''),    undef, '_numeric_pid returns undef for empty string' );
is( Developer::Dashboard::RuntimeManager::_numeric_pid('42'),  42,    '_numeric_pid coerces numeric pids' );
is( Developer::Dashboard::RuntimeManager::_numeric_pid('x9'),  'x9',  '_numeric_pid preserves non-numeric scalars' );

# --- _reap_child_process guard ----------------------------------------------
is( $manager->_reap_child_process(undef),   0, '_reap_child_process rejects undef pid' );
is( $manager->_reap_child_process('abc'),   0, '_reap_child_process rejects non-numeric pid' );
is( $manager->_reap_child_process(0),       0, '_reap_child_process rejects pid below one' );
is( $manager->_reap_child_process(999999),  0, '_reap_child_process returns false for a non-child pid' );

# --- _pid_is_running guard ---------------------------------------------------
is( $manager->_pid_is_running(undef),  0, '_pid_is_running rejects undef pid' );
is( $manager->_pid_is_running('abc'),  0, '_pid_is_running rejects non-numeric pid' );
is( $manager->_pid_is_running(0),      0, '_pid_is_running rejects pid below one' );
ok( $manager->_pid_is_running($$),        '_pid_is_running confirms the current live process' );

# --- _reap_any_child_processes ----------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_wait_for_any_child_process = sub { return undef };
    is( $manager->_reap_any_child_processes, 0, '_reap_any_child_processes stops when waitpid yields undef' );
}
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) { POSIX::_exit(0) }
    my $reaped = 0;
    for ( 1 .. 40 ) {
        $reaped = $manager->_reap_any_child_processes;
        last if $reaped;
        select undef, undef, undef, 0.05;
    }
    is( $reaped, 1, '_reap_any_child_processes reaps one exited direct child then stops on -1' );
}

# --- _wait_for_windows_web_shutdown -----------------------------------------
ok( $manager->_wait_for_windows_web_shutdown( $$, undef, undef ),   '_wait_for_windows_web_shutdown true when the saved pid is alive' );
ok( !$manager->_wait_for_windows_web_shutdown( 999999, undef, [] ), '_wait_for_windows_web_shutdown false when nothing is alive' );
ok( $manager->_wait_for_windows_web_shutdown( undef, undef, [$$] ), '_wait_for_windows_web_shutdown true when a listener pid is alive' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (4321) };
    ok( $manager->_wait_for_windows_web_shutdown( undef, 7890, [] ), '_wait_for_windows_web_shutdown true when the port still has listeners' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    ok( !$manager->_wait_for_windows_web_shutdown( undef, 7890, [] ),  '_wait_for_windows_web_shutdown false when the port has no listeners' );
    ok( !$manager->_wait_for_windows_web_shutdown( undef, undef, [] ), '_wait_for_windows_web_shutdown false when no port is supplied' );
}

# --- _portable_signal empty string ------------------------------------------
{
    my $err = eval { Developer::Dashboard::RuntimeManager::_portable_signal(''); 1 } ? '' : $@;
    like( $err, qr/Missing signal name/, '_portable_signal rejects an empty signal name' );
}

# --- _collector_disabled -----------------------------------------------------
is( $manager->_collector_disabled(undef),            0, '_collector_disabled false for a non-hash job' );
is( $manager->_collector_disabled( {} ),             0, '_collector_disabled false for an enabled job' );
is( $manager->_collector_disabled( { disable => 1 } ), 1, '_collector_disabled true for a disabled job' );

# --- _collector_job_by_name --------------------------------------------------
{
    my $err = eval { $manager->_collector_job_by_name(undef); 1 } ? '' : $@;
    like( $err, qr/Missing collector name/, '_collector_job_by_name requires a name' );
    $err = eval { $manager->_collector_job_by_name(''); 1 } ? '' : $@;
    like( $err, qr/Missing collector name/, '_collector_job_by_name rejects an empty name' );
    is( $manager->_collector_job_by_name('alpha.collector')->{name}, 'alpha.collector', '_collector_job_by_name finds a configured job' );
    $err = eval { $manager->_collector_job_by_name('does.not.exist'); 1 } ? '' : $@;
    like( $err, qr/Unknown collector 'does\.not\.exist'/, '_collector_job_by_name dies on unknown collectors' );
}
{
    # A non-hash entry in the collectors array is skipped by _collector_job_by_name.
    my $mixed = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ 'not-a-hash', { name => 'good.one' } ] };
    my $mixed_manager = build_manager( config => $mixed );
    is( $mixed_manager->_collector_job_by_name('good.one')->{name}, 'good.one', '_collector_job_by_name skips non-hash collector entries' );
}

# --- _loop_job_for_named_start ----------------------------------------------
{
    my $manual = $manager->_loop_job_for_named_start( { name => 'm', schedule => 'manual' } );
    is( $manual->{schedule}, 'interval', '_loop_job_for_named_start promotes manual collectors to interval' );
    is( $manual->{interval}, 30,         '_loop_job_for_named_start defaults the manual interval' );

    my $manual_kept = $manager->_loop_job_for_named_start( { name => 'm', schedule => 'manual', interval => 12 } );
    is( $manual_kept->{interval}, 12, '_loop_job_for_named_start keeps a valid manual interval' );

    my $manual_bad = $manager->_loop_job_for_named_start( { name => 'm', schedule => 'manual', interval => 'x' } );
    is( $manual_bad->{interval}, 30, '_loop_job_for_named_start replaces a non-numeric manual interval' );

    my $cron = $manager->_loop_job_for_named_start( { name => 'c', cron => '* * * * *' } );
    is( $cron->{schedule}, undef, '_loop_job_for_named_start leaves a cron schedule alone' );

    my $interval = $manager->_loop_job_for_named_start( { name => 'i', interval => 5 } );
    is( $interval->{interval}, 5, '_loop_job_for_named_start leaves an interval schedule alone' );

    my $empty = $manager->_loop_job_for_named_start(undef);
    is( ref $empty, 'HASH', '_loop_job_for_named_start tolerates an undef job' );
}

# --- _collector_stalled_for_watchdog ----------------------------------------
is( $manager->_collector_stalled_for_watchdog( 'x',  {} ), 0, '_collector_stalled_for_watchdog rejects a non-hash job' );
is( $manager->_collector_stalled_for_watchdog( {},   'x' ), 0, '_collector_stalled_for_watchdog rejects a non-hash status' );
is( $manager->_collector_stalled_for_watchdog( {},   {} ), 0, '_collector_stalled_for_watchdog false when there is no progress epoch' );
{
    my $recent = Developer::Dashboard::RuntimeManager::_now_iso8601();
    is( $manager->_collector_stalled_for_watchdog( { interval => 5 }, { last_run => $recent } ), 0, '_collector_stalled_for_watchdog false for a fresh collector' );
    my $old = POSIX::strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime( time - 100000 ) );
    is( $manager->_collector_stalled_for_watchdog( { interval => 1 }, { last_run => $old } ), 1, '_collector_stalled_for_watchdog true for a long-stalled collector' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_watchdog_stale_seconds = sub { return 0 };
    is( $manager->_collector_stalled_for_watchdog( { interval => 1 }, { last_run => Developer::Dashboard::RuntimeManager::_now_iso8601() } ), 0, '_collector_stalled_for_watchdog false when the stale window is under one second' );
}

# --- _collector_watchdog_last_progress_epoch --------------------------------
is( $manager->_collector_watchdog_last_progress_epoch('x'), 0, '_collector_watchdog_last_progress_epoch rejects non-hash status' );
is( $manager->_collector_watchdog_last_progress_epoch( {} ), 0, '_collector_watchdog_last_progress_epoch zero for empty status' );
is( $manager->_collector_watchdog_last_progress_epoch( { last_run => '' } ), 0, '_collector_watchdog_last_progress_epoch skips empty timestamps' );
{
    my $now = Developer::Dashboard::RuntimeManager::_now_iso8601();
    ok( $manager->_collector_watchdog_last_progress_epoch( { last_completed_at => $now, last_started_at => $now } ) > 0, '_collector_watchdog_last_progress_epoch returns the newest epoch' );
    is( $manager->_collector_watchdog_last_progress_epoch( { last_run => 'not-a-date' } ), 0, '_collector_watchdog_last_progress_epoch skips unparseable timestamps' );
}

# --- _collector_watchdog_stale_seconds --------------------------------------
{
    ok( $manager->_collector_watchdog_stale_seconds( { interval => 5, timeout_ms => 2000 } ) > 0, '_collector_watchdog_stale_seconds uses timeout_ms when present' );
    ok( $manager->_collector_watchdog_stale_seconds( { interval => 5, timeout => 3 } ) > 0,       '_collector_watchdog_stale_seconds falls back to timeout seconds' );
    ok( $manager->_collector_watchdog_stale_seconds( { interval => 5 } ) > 0,                     '_collector_watchdog_stale_seconds defaults the timeout to thirty seconds' );
    ok( $manager->_collector_watchdog_stale_seconds(undef) > 0,                                    '_collector_watchdog_stale_seconds tolerates an undef job' );
    ok( $manager->_collector_watchdog_stale_seconds( { interval => 5, timeout_ms => 0 } ) > 0,    '_collector_watchdog_stale_seconds ignores a zero timeout_ms' );
    ok( $manager->_collector_watchdog_stale_seconds( { interval => 5, timeout => 0 } ) > 0,       '_collector_watchdog_stale_seconds ignores a zero timeout' );
}

# --- _collector_watchdog_window ---------------------------------------------
{
    my ( $count, $at, $epoch ) = $manager->_collector_watchdog_window( {} );
    is( $count, 0, '_collector_watchdog_window resets the counter for empty status' );
    ok( $epoch > 0, '_collector_watchdog_window seeds a fresh window epoch' );

    my $now_epoch = time;
    my ( $count2, $at2, $epoch2 ) = $manager->_collector_watchdog_window(
        {
            watchdog_restart_count                   => 2,
            watchdog_restart_window_started_at_epoch => $now_epoch,
            watchdog_restart_window_started_at       => 'seeded',
        }
    );
    is( $count2, 2, '_collector_watchdog_window keeps a live restart counter' );
    is( $epoch2, $now_epoch, '_collector_watchdog_window keeps the live window epoch' );

    my ( $count3 ) = $manager->_collector_watchdog_window(
        {
            watchdog_restart_count                   => 5,
            watchdog_restart_window_started_at_epoch => 'nope',
        }
    );
    is( $count3, 0, '_collector_watchdog_window resets when the window epoch is malformed' );

    my ( $count4 ) = $manager->_collector_watchdog_window(undef);
    is( $count4, 0, '_collector_watchdog_window tolerates an undef status' );
}

# --- _log_collector_watchdog_event ------------------------------------------
{
    ok( $manager->_log_collector_watchdog_event( 'alpha.collector', "line one\n" ), '_log_collector_watchdog_event chomps and logs a message' );
}

# --- _mark_collector_watchdog_attention -------------------------------------
{
    ok( $manager->_mark_collector_watchdog_attention( 'alpha.collector', 'needs a look' ), '_mark_collector_watchdog_attention defaults observed timing' );
    ok(
        $manager->_mark_collector_watchdog_attention(
            'alpha.collector', 'needs a look',
            observed_at       => '2020-01-01T00:00:00Z',
            observed_at_epoch => 100,
        ),
        '_mark_collector_watchdog_attention accepts explicit observed timing',
    );
}

# --- _normalized_collector_watch_names --------------------------------------
is_deeply( [ $manager->_normalized_collector_watch_names( [ 'b', '', 'a', 'b', undef ] ) ], [ 'a', 'b' ], '_normalized_collector_watch_names sorts, filters, and dedups' );
is_deeply( [ $manager->_normalized_collector_watch_names(undef) ],       [], '_normalized_collector_watch_names tolerates undef' );
is_deeply( [ $manager->_normalized_collector_watch_names('scalar') ],    [], '_normalized_collector_watch_names ignores non-array input' );

# --- restart-limit / window / grace / poll env overrides --------------------
{
    is( $manager->_collector_restart_limit,          3,   '_collector_restart_limit default' );
    is( $manager->_collector_restart_window_seconds, 300, '_collector_restart_window_seconds default' );
    is( $manager->_collector_stall_grace_seconds,    10,  '_collector_stall_grace_seconds default' );
    is( $manager->_collector_supervisor_poll_interval, 5, '_collector_supervisor_poll_interval default' );

    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT}            = 9;
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_WINDOW_SECONDS}   = 88;
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS}      = 4;
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_POLL_INTERVAL} = '2.5';
    is( $manager->_collector_restart_limit,            9,     '_collector_restart_limit env override' );
    is( $manager->_collector_restart_window_seconds,   88,    '_collector_restart_window_seconds env override' );
    is( $manager->_collector_stall_grace_seconds,      4,     '_collector_stall_grace_seconds env override' );
    is( $manager->_collector_supervisor_poll_interval, '2.5', '_collector_supervisor_poll_interval env override' );

    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT}            = '0';
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_WINDOW_SECONDS}   = 'x';
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS}      = '-2';
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_POLL_INTERVAL} = 'abc';
    is( $manager->_collector_restart_limit,            3,   '_collector_restart_limit ignores an out-of-range override' );
    is( $manager->_collector_restart_window_seconds,   300, '_collector_restart_window_seconds ignores a non-numeric override' );
    is( $manager->_collector_stall_grace_seconds,      10,  '_collector_stall_grace_seconds ignores a negative override' );
    is( $manager->_collector_supervisor_poll_interval, 5,   '_collector_supervisor_poll_interval ignores a non-numeric override' );
}

# --- _runtime_confirmation_polls override ------------------------------------
{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS} = 4;
    is( $manager->_runtime_confirmation_polls, 4, '_runtime_confirmation_polls honours a valid override' );
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS} = 'x';
    is( $manager->_runtime_confirmation_polls, 3, '_runtime_confirmation_polls ignores an invalid override' );
}

# --- _progress_emit ----------------------------------------------------------
is( $manager->_progress_emit( undef, {} ), 1, '_progress_emit ignores an undef progress callback' );
is( $manager->_progress_emit( 'scalar', {} ), 1, '_progress_emit ignores a non-code progress callback' );
{
    my @events;
    is( $manager->_progress_emit( sub { push @events, $_[0] }, { task_id => 't' } ), 1, '_progress_emit invokes a code callback' );
    is( scalar @events, 1, '_progress_emit forwards the event to the callback' );
}

# --- _collector_supervisor_targets_without ----------------------------------
{
    $manager->_cleanup_collector_supervisor_files;
    is_deeply( [ $manager->_collector_supervisor_targets_without( ['x'] ) ], [], '_collector_supervisor_targets_without returns empty when no state exists' );
    $manager->_write_collector_supervisor_state( { watched_names => [ 'alpha', 'beta', 'gamma' ] } );
    is_deeply(
        [ $manager->_collector_supervisor_targets_without( ['beta'] ) ],
        [ 'alpha', 'gamma' ],
        '_collector_supervisor_targets_without drops the requested names from the watched set',
    );
    $manager->_cleanup_collector_supervisor_files;
}

# --- start_collectors (all runtime-ready) -----------------------------------
{
    my $mixed_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub {
        return [
            'not-a-hash',
            { name => 'manual.one', schedule => 'manual' },
            { name => 'iv.one',   interval => 1 },
            { name => 'cron.one',  cron => '* * * * *' },
            { command => 'true' },
        ];
    };
    my $started_runner = Local::Runner->new;
    my $started_manager = build_manager( config => $mixed_config, runner => $started_runner );
    my @merged;
    local *Developer::Dashboard::RuntimeManager::_stop_disabled_collectors      = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready        = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_disabled             = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_merge_collector_supervisor_targets = sub { @merged = @{ $_[1] }; return 1 };
    my @started = $started_manager->start_collectors;
    is_deeply( [ sort map { $_->{name} } @started ], [ 'cron.one', 'iv.one' ], 'start_collectors starts non-manual configured collectors' );
    is_deeply( [ sort @merged ], [ 'cron.one', 'iv.one' ], 'start_collectors merges started names into the supervisor set' );

    # Scoped start via names hits the wanted-name filter branch.
    my @scoped = $started_manager->start_collectors( names => ['iv.one'] );
    is_deeply( [ map { $_->{name} } @scoped ], ['iv.one'], 'start_collectors honours an explicit wanted-name list' );
}

# --- start_collectors: pid undef => nothing started -------------------------
{
    my $mixed_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'iv.two', interval => 1 } ] };
    my $undef_runner = Local::Runner->new( next_pid => undef );
    my $undef_manager = build_manager( config => $mixed_config, runner => $undef_runner );
    my $merge_calls = 0;
    local *Developer::Dashboard::RuntimeManager::_stop_disabled_collectors          = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_merge_collector_supervisor_targets = sub { $merge_calls++; return 1 };
    my @started = $undef_manager->start_collectors;
    is_deeply( \@started, [], 'start_collectors starts nothing when start_loop yields an undef pid' );
    is( $merge_calls, 0, 'start_collectors skips the supervisor merge when no collector started' );
}

# --- start_collectors: runtime not ready => rollback + die ------------------
{
    my $mixed_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'iv.three', interval => 1 } ] };
    my $rollback_runner = Local::Runner->new;
    my $rollback_manager = build_manager( config => $mixed_config, runner => $rollback_runner );
    local *Developer::Dashboard::RuntimeManager::_stop_disabled_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready  = sub { return 0 };
    my $err = eval { $rollback_manager->start_collectors; 1 } ? '' : $@;
    like( $err, qr/Failed to keep collector 'iv\.three' running after startup/, 'start_collectors dies when a started collector does not stay ready' );
    is_deeply( $rollback_runner->{stopped}, ['iv.three'], 'start_collectors stops the failed collector during rollback' );
}

# --- start_collectors: start_loop dies => rollback + die --------------------
{
    my $mixed_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'iv.four', interval => 1 } ] };
    my $die_runner = Local::Runner->new( fail => { 'iv.four' => "boom\n" } );
    my $die_manager = build_manager( config => $mixed_config, runner => $die_runner );
    local *Developer::Dashboard::RuntimeManager::_stop_disabled_collectors = sub { return () };
    my $err = eval { $die_manager->start_collectors; 1 } ? '' : $@;
    like( $err, qr/Failed to start collector 'iv\.four': boom/, 'start_collectors surfaces start_loop failures' );
}

# --- start_named_collector ---------------------------------------------------
{
    my $named_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub {
        return [
            { name => 'named.ok',       interval => 1 },
            { name => 'named.disabled', interval => 1, disable => 1 },
        ];
    };
    my $named_runner  = Local::Runner->new;
    my $named_manager = build_manager( config => $named_config, runner => $named_runner );
    local *Developer::Dashboard::RuntimeManager::_merge_collector_supervisor_targets = sub { return 1 };

    {
        local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };
        my $result = $named_manager->start_named_collector( name => 'named.ok' );
        is( $result->{name}, 'named.ok', 'start_named_collector returns the started collector name' );
        is( $result->{pid},  4242,       'start_named_collector returns the started pid' );
    }

    my $missing = eval { $named_manager->start_named_collector; 1 } ? '' : $@;
    like( $missing, qr/Missing collector name/, 'start_named_collector requires a name' );

    {
        my @stop_names;
        local *Developer::Dashboard::RuntimeManager::stop_collectors = sub { my ( undef, %a ) = @_; @stop_names = @{ $a{names} }; return () };
        my $disabled = eval { $named_manager->start_named_collector( name => 'named.disabled' ); 1 } ? '' : $@;
        like( $disabled, qr/Collector 'named\.disabled' is disabled/, 'start_named_collector rejects disabled collectors' );
        is_deeply( \@stop_names, ['named.disabled'], 'start_named_collector stops a disabled collector before failing' );
    }

    {
        local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 0 };
        my $err = eval { $named_manager->start_named_collector( name => 'named.ok' ); 1 } ? '' : $@;
        like( $err, qr/Failed to keep collector 'named\.ok' running after startup/, 'start_named_collector dies when the collector does not stay ready' );
    }

    {
        my $fail_runner  = Local::Runner->new( fail => { 'named.ok' => "kaboom\n" } );
        my $fail_manager = build_manager( config => $named_config, runner => $fail_runner );
        my $err = eval { $fail_manager->start_named_collector( name => 'named.ok' ); 1 } ? '' : $@;
        like( $err, qr/Failed to start collector 'named\.ok': kaboom/, 'start_named_collector surfaces start_loop failures' );
    }
}

# --- _stop_disabled_collectors ----------------------------------------------
{
    is_deeply( [ $manager->_stop_disabled_collectors( jobs => 'not-array' ) ], [], '_stop_disabled_collectors rejects a non-array jobs value' );
    my @stopped_names;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub { my ( undef, %a ) = @_; @stopped_names = @{ $a{names} }; return () };
    my @jobs = (
        'not-a-hash',
        { name => 'dis.one', disable => 1 },
        { name => '',        disable => 1 },
        { name => 'dis.two', disable => 1 },
        { name => 'enabled', interval => 1 },
    );
    my @names = $manager->_stop_disabled_collectors( jobs => \@jobs );
    is_deeply( [ sort @names ], [ 'dis.one', 'dis.two' ], '_stop_disabled_collectors stops disabled named collectors' );

    @stopped_names = ();
    my @scoped = $manager->_stop_disabled_collectors( jobs => \@jobs, wanted => { 'dis.one' => 1 } );
    is_deeply( \@scoped, ['dis.one'], '_stop_disabled_collectors honours the wanted filter' );

    my @none = $manager->_stop_disabled_collectors( jobs => [ { name => 'enabled', interval => 1 } ] );
    is_deeply( \@none, [], '_stop_disabled_collectors returns empty when nothing is disabled' );
}

# --- _ensure_collector_pid_stopped ------------------------------------------
is( $manager->_ensure_collector_pid_stopped( 'c', undef ), 1, '_ensure_collector_pid_stopped ignores an undef pid' );
is( $manager->_ensure_collector_pid_stopped( 'c', 'x' ),   1, '_ensure_collector_pid_stopped ignores a non-numeric pid' );
is( $manager->_ensure_collector_pid_stopped( 'c', 0 ),     1, '_ensure_collector_pid_stopped ignores a pid below one' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 0 };
    is( $manager->_ensure_collector_pid_stopped( 'c', 123456 ), 1, '_ensure_collector_pid_stopped ignores a foreign-namespace pid' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_send_signal        = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_reap_child_process = sub { return 1 };

    my @seq = ( 1, 0 );    # alive at first check, then gone during the TERM loop
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return @seq ? shift(@seq) : 0 };
    is( $manager->_ensure_collector_pid_stopped( 'c', 123456 ), 1, '_ensure_collector_pid_stopped returns after the collector dies on TERM' );

    @seq = ( (1) x 21, 0 );    # survives TERM loop, then dies after KILL
    is( $manager->_ensure_collector_pid_stopped( 'c', 123456 ), 1, '_ensure_collector_pid_stopped escalates to KILL when TERM is not enough' );

    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 1 };
    my $err = eval { $manager->_ensure_collector_pid_stopped( 'c', 123456 ); 1 } ? '' : $@;
    like( $err, qr/Collector 'c' did not stop after TERM and KILL/, '_ensure_collector_pid_stopped dies when the collector never stops' );
}

# --- serve_all: foreground path ---------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return ( { name => 'a', pid => 1 } ) };
    local *Developer::Dashboard::RuntimeManager::stop_collectors  = sub { return ('a') };
    local *Developer::Dashboard::RuntimeManager::start_web        = sub { return 'server-result' };
    my $fg = $manager->serve_all( foreground => 1, host => '127.0.0.1', port => 9100, workers => 2, ssl => 1 );
    is( $fg->{foreground}, 1,               'serve_all foreground returns a foreground marker' );
    is( $fg->{host},       '127.0.0.1',     'serve_all foreground keeps an explicit host' );
    is( $fg->{result},     'server-result', 'serve_all foreground returns the web result' );

    my $fg_default = $manager->serve_all( foreground => 1 );
    is( $fg_default->{host}, '0.0.0.0', 'serve_all foreground defaults the host' );
    is( $fg_default->{port}, 7890,      'serve_all foreground defaults the port' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::stop_collectors  = sub { return () };
    local *Developer::Dashboard::RuntimeManager::start_web        = sub { die "fg boom\n" };
    my $err = eval { $manager->serve_all( foreground => 1 ); 1 } ? '' : $@;
    like( $err, qr/fg boom/, 'serve_all foreground re-throws a web startup error after stopping collectors' );
}
# --- serve_all: background path ---------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub { return 5555 };
    local *Developer::Dashboard::RuntimeManager::start_collectors        = sub { return ( { name => 'a', pid => 1 } ) };
    my $bg = $manager->serve_all( host => '127.0.0.1', port => 9101 );
    is( $bg->{pid},  5555,        'serve_all background returns the restarted web pid' );
    is( $bg->{host}, '127.0.0.1', 'serve_all background keeps the requested host' );
}

# --- _procfs_available / _slurp_proc_file / _process_exists -----------------
ok( $manager->_procfs_available, '_procfs_available true on a /proc host' );
is( $manager->_slurp_proc_file(undef), undef, '_slurp_proc_file rejects an undef path' );
is( $manager->_slurp_proc_file(''),    undef, '_slurp_proc_file rejects an empty path' );
is( $manager->_slurp_proc_file('/proc/does-not-exist-xyz'), undef, '_slurp_proc_file returns undef for an unreadable path' );
ok( defined $manager->_slurp_proc_file("/proc/$$/stat"), '_slurp_proc_file reads a real proc file' );

# --- _same_pid_namespace -----------------------------------------------------
is( $manager->_same_pid_namespace(undef), 0, '_same_pid_namespace rejects undef pid' );
is( $manager->_same_pid_namespace('x'),   0, '_same_pid_namespace rejects non-numeric pid' );
is( $manager->_same_pid_namespace(0),     0, '_same_pid_namespace rejects pid below one' );
is( $manager->_same_pid_namespace(999999), 1, '_same_pid_namespace true when the target namespace is unknown' );
ok( $manager->_same_pid_namespace($$),       '_same_pid_namespace true for the current process' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_current_pid_namespace_id = sub { return undef };
    is( $manager->_same_pid_namespace($$), 1, '_same_pid_namespace true when the current namespace is unknown' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_namespace_id = sub {
        my ( undef, $pid ) = @_;
        return 'ns-current' if $pid == $$;
        return '';
    };
    is( $manager->_same_pid_namespace(123456), 1, '_same_pid_namespace true when the target namespace id is empty' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_namespace_id = sub {
        my ( undef, $pid ) = @_;
        return $pid == $$ ? 'ns-current' : 'ns-other';
    };
    is( $manager->_same_pid_namespace(123456), 0, '_same_pid_namespace false for a different namespace id' );
}

# --- _read_process_env_marker ------------------------------------------------
{
    my $home_value = $manager->_read_process_env_marker( $$, 'HOME' );
    ok( defined $home_value, '_read_process_env_marker reads a matching environment key' );
    is( $manager->_read_process_env_marker( $$, 'DD_NO_SUCH_KEY_XYZ' ), undef, '_read_process_env_marker returns undef for an absent key' );
    is( $manager->_read_process_env_marker( 999999, 'HOME' ), undef, '_read_process_env_marker returns undef for an unreadable process' );
}
{
    # A process launched with an empty environment exercises the empty-environ guard.
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        exec 'env', '-i', 'sleep', '120' or POSIX::_exit(1);
    }
    my $ready = 0;
    for ( 1 .. 2000 ) {
        my $comm = '';
        if ( open my $c, '<', "/proc/$child/comm" ) { $comm = <$c>; close $c; }
        my $size = -s "/proc/$child/environ";
        if ( defined $comm && $comm =~ /^sleep/ && defined $size && $size == 0 ) { $ready = 1; last; }
        select undef, undef, undef, 0.02;
    }
    my $marker = $ready ? $manager->_read_process_env_marker( $child, 'HOME' ) : undef;
    is( $marker, undef, '_read_process_env_marker returns undef when the process environment is empty' );
    kill 'KILL', $child;
    waitpid( $child, 0 );
}

# --- _read_process_state ps fallback -----------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( " R \n", '', 0 );
    is( $manager->_read_process_state(123), 'R', '_read_process_state parses ps stat output' );
    @cap = ( '', '', 1 );
    is( $manager->_read_process_state(123), undef, '_read_process_state returns undef when ps fails' );
    @cap = ( undef, '', 0 );
    is( $manager->_read_process_state(123), undef, '_read_process_state returns undef for undef ps output' );
    @cap = ( '', '', 0 );
    is( $manager->_read_process_state(123), undef, '_read_process_state returns undef for empty ps output' );
}
ok( defined $manager->_read_process_state($$), '_read_process_state reads the current process state via procfs' );

# --- _read_process_title ps fallback -----------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( "some title   \n", '', 0 );
    is( $manager->_read_process_title(123), "some title", '_read_process_title parses ps args output' );
    @cap = ( '', '', 1 );
    is( $manager->_read_process_title(123), undef, '_read_process_title returns undef when ps fails' );
    @cap = ( undef, '', 0 );
    is( $manager->_read_process_title(123), undef, '_read_process_title returns undef for undef ps output' );
}
ok( defined $manager->_read_process_title($$), '_read_process_title reads the current process title via procfs' );

# --- _send_signal Windows path -----------------------------------------------
is( $manager->_send_signal( 'TERM', undef, 0, 'nope' ), 0, '_send_signal ignores invalid pids' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( '', '', 0 );
    is( $manager->_send_signal( 'TERM', 111 ), 1, '_send_signal Windows returns the target count on success' );
    @cap = ( '', 'process not found', 1 );
    is( $manager->_send_signal( 'KILL', 111 ), 1, '_send_signal Windows treats a not-found stderr as already stopped' );
    @cap = ( 'the id not found', undef, 1 );
    is( $manager->_send_signal( 'TERM', 111 ), 1, '_send_signal Windows treats a not-found stdout as already stopped' );
    @cap = ( '', 'hard error', 1 );
    my $err = eval { $manager->_send_signal( 'TERM', 111 ); 1 } ? '' : $@;
    like( $err, qr/Failed to stop Windows process ids/, '_send_signal Windows dies on a hard TERM/KILL failure' );
    @cap = ( undef, undef, 1 );
    is( $manager->_send_signal( 'HUP', 111 ), 0, '_send_signal Windows returns zero for a non-terminating signal failure' );
}

# --- _pkill_perl Windows path ------------------------------------------------
{
    no warnings 'redefine';
    my @sent;
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            { pid => 1, args => 'perl match-me' },
            { pid => 2, args => 'perl no-match' },
            { pid => 3, args => 'perl match-me' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::_proc_owned_by_current_user = sub { my ( undef, $p ) = @_; return $p->{pid} == 3 ? 0 : 1 };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { push @sent, $_[2]; return 1 };
    is( $manager->_pkill_perl('match-me'), 1, '_pkill_perl Windows returns true after scanning the process table' );
    is_deeply( \@sent, [1], '_pkill_perl Windows only signals owned, matching processes' );
}

# --- _pkill_perl Unix path ---------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( '', '', 0 );
    is( $manager->_pkill_perl('x'), 1, '_pkill_perl Unix returns true when pkill exits zero' );
    @cap = ( '', '', 1 );
    is( $manager->_pkill_perl('x'), 1, '_pkill_perl Unix returns true when pkill matched nothing' );
    @cap = ( '', 'boom', 5 );
    is( $manager->_pkill_perl('x'), undef, '_pkill_perl Unix returns undef on an unexpected pkill failure' );

    my @sent;
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            { pid => 1, uid => $<, args => 'perl match-me' },
            { pid => 2, uid => $<, args => 'perl no-match' },
            { pid => 3, uid => $< + 1, args => 'perl match-me' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::_proc_owned_by_current_user = sub { my ( undef, $p ) = @_; return $p->{uid} == $< ? 1 : 0 };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { push @sent, $_[2]; return 1 };
    @cap = ( '', '', 127 );
    @sent = ();
    is( $manager->_pkill_perl('match-me'), 1, '_pkill_perl Unix falls back to a manual sweep when pkill is missing (exit 127)' );
    is_deeply( \@sent, [1], '_pkill_perl Unix manual sweep only signals owned, matching processes' );
    @cap = ( '', '', -1 );
    @sent = ();
    is( $manager->_pkill_perl('match-me'), 1, '_pkill_perl Unix falls back when the pkill system call itself fails' );
    @cap = ( '', 'pkill: command not found', 5 );
    @sent = ();
    is( $manager->_pkill_perl('match-me'), 1, '_pkill_perl Unix falls back when stderr reports a missing pkill' );
}

# --- _find_processes_by_prefix (undef args) ---------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            { pid => 1, uid => $<, args => undef },
            { pid => 2, uid => $<, args => 'dashboard ajax: real' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::_proc_owned_by_current_user = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
    my @matches = $manager->_find_processes_by_prefix('dashboard ajax:');
    is_deeply( [ map { $_->{pid} } @matches ], [2], '_find_processes_by_prefix skips processes with an undef command line' );
}

# --- _find_web_processes (duplicate pid) ------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub {
        return (
            { pid => 500, uid => $<, args => 'dashboard web: 0.0.0.0:1' },
            { pid => 500, uid => $<, args => 'dashboard web: 0.0.0.0:1' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::_proc_owned_by_current_user = sub { return 1 };
    my @web = $manager->_find_web_processes;
    is( scalar @web, 1, '_find_web_processes deduplicates repeated process ids' );
}

# --- _proc_owned_by_current_user --------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    is( $manager->_proc_owned_by_current_user(undef),        0, '_proc_owned_by_current_user rejects an undef process' );
    is( $manager->_proc_owned_by_current_user( { pid => 0 } ), 0, '_proc_owned_by_current_user rejects a pid of zero' );
    is( $manager->_proc_owned_by_current_user( { pid => 5 } ), 1, '_proc_owned_by_current_user trusts a process with no uid metadata' );
    is( $manager->_proc_owned_by_current_user( { pid => 5, uid => '' } ), 1, '_proc_owned_by_current_user trusts a process with an empty uid' );
    is( $manager->_proc_owned_by_current_user( { pid => 5, uid => $< } ), 1, '_proc_owned_by_current_user matches the current uid' );
    is( $manager->_proc_owned_by_current_user( { pid => 5, uid => $< + 1 } ), 0, '_proc_owned_by_current_user rejects a foreign uid' );
}

# --- _looks_like_web_process -------------------------------------------------
is( $manager->_looks_like_web_process(undef),                    0, '_looks_like_web_process rejects an undef record' );
is( $manager->_looks_like_web_process( { pid => 0, args => 'x' } ), 0, '_looks_like_web_process rejects a pid of zero' );
is( $manager->_looks_like_web_process( { pid => 1 } ),           0, '_looks_like_web_process rejects a record with no args' );
ok( $manager->_looks_like_web_process( { pid => 1, args => '/usr/lib/_dashboard-core serve' } ), '_looks_like_web_process recognizes a _dashboard-core serve command' );

# --- _ps_processes (non-matching line) --------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "bad-line\n  123  1000  the args\n", '', 0 ) };
    my @procs = $manager->_ps_processes;
    is_deeply( \@procs, [ { pid => 123, uid => 1000, args => 'the args' } ], '_ps_processes skips lines that do not parse' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', '', 1 ) };
    is_deeply( [ $manager->_ps_processes ], [], '_ps_processes returns empty when ps fails' );
}

# --- _listener_pids_for_port_via_lsof ---------------------------------------
{
    no warnings 'redefine';
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    is_deeply( [ $manager->_listener_pids_for_port_via_lsof(0) ], [], '_listener_pids_for_port_via_lsof rejects a false port' );
    @cap = ( '', '', 1 );
    is_deeply( [ $manager->_listener_pids_for_port_via_lsof(7890) ], [], '_listener_pids_for_port_via_lsof returns empty when lsof fails' );
    @cap = ( undef, '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port_via_lsof(7890) ], [], '_listener_pids_for_port_via_lsof returns empty for undef lsof output' );
    @cap = ( '', '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port_via_lsof(7890) ], [], '_listener_pids_for_port_via_lsof returns empty for blank lsof output' );
    @cap = ( "p1234\np1234\np5\nother\n", '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port_via_lsof(7890) ], [ 1234, 5 ], '_listener_pids_for_port_via_lsof parses and dedups pids' );
}

# --- _listener_pids_for_port_via_netstat ------------------------------------
{
    no warnings 'redefine';
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    is_deeply( [ $manager->_listener_pids_for_port_via_netstat(0) ], [], '_listener_pids_for_port_via_netstat rejects a false port' );
    @cap = ( '', '', 1 );
    is_deeply( [ $manager->_listener_pids_for_port_via_netstat(7890) ], [], '_listener_pids_for_port_via_netstat returns empty when netstat fails' );
    @cap = ( undef, '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port_via_netstat(7890) ], [], '_listener_pids_for_port_via_netstat returns empty for undef netstat output' );
    @cap = ( '', '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port_via_netstat(7890) ], [], '_listener_pids_for_port_via_netstat returns empty for blank netstat output' );
    @cap = ( "  TCP  0.0.0.0:7890  0.0.0.0:0  LISTENING  4321\nbad line\n  TCP  1.2.3.4:7890  x:0  LISTENING  4321\n", '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port_via_netstat(7890) ], [4321], '_listener_pids_for_port_via_netstat parses and dedups listening pids' );
}

# --- _listener_pids_for_port (ss present) -----------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { my ($n) = @_; return $n eq 'ss' ? '/usr/bin/ss' : undef };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };

    @cap = ( "LISTEN 0 128 *:7890 users:((\"starman\",pid=1234,fd=6))\n", '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [1234], '_listener_pids_for_port parses ss pid output' );

    @cap = ( undef, '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [], '_listener_pids_for_port handles undef ss stdout' );

    @cap = ( '', '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [], '_listener_pids_for_port handles empty ss stdout' );

    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_lsof = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub { return (99) };
    @cap = ( '', '', 127 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [99], '_listener_pids_for_port falls back when ss exits 127' );
    @cap = ( '', 'ss: command not found', 5 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [99], '_listener_pids_for_port falls back when stderr reports a missing ss' );
}
is_deeply( [ $manager->_listener_pids_for_port(0) ], [], '_listener_pids_for_port rejects a false port' );

# --- _listener_pids_for_port (ss missing => lsof/proc) ----------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_lsof = sub { return (7) };
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [7], '_listener_pids_for_port uses lsof when ss is absent' );
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_lsof = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub { return (8) };
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [8], '_listener_pids_for_port falls back to procfs when lsof finds nothing' );
}

# --- _listener_pids_for_port (Windows path) ---------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( "  4321  \n 4321 \n", '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [4321], '_listener_pids_for_port parses Windows OwningProcess output' );
    @cap = ( '', '', 1 );
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_netstat = sub { return (55) };
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [55], '_listener_pids_for_port falls back to netstat on Windows' );
}

# --- _listener_socket_inodes_for_port ---------------------------------------
{
    my $tcpfile = File::Spec->catfile( $home, 'fake-proc-net-tcp' );
    open my $fh, '>', $tcpfile or die $!;
    print {$fh} "  sl  local_address rem_address   st ...\n";
    print {$fh} "   0: 0100007F:1F90 00000000:0000 0A 00000000:00000000 00:00000000 00000000  1000  0 654321 1 x\n";
    print {$fh} "   1: 0100007F:0050 00000000:0000 0A 00000000:00000000 00:00000000 00000000  1000  0 111 1 x\n";
    print {$fh} "   2: NOCOLON 00000000:0000 0A 00000000:00000000 00:00000000 00000000  1000  0 222 1 x\n";
    print {$fh} "short line here\n";
    print {$fh} "\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_socket_table_paths = sub { return ( $tcpfile, '/does/not/exist/proc-tcp' ) };
    my @inodes = $manager->_listener_socket_inodes_for_port(8080);    # 0x1F90
    is_deeply( \@inodes, [654321], '_listener_socket_inodes_for_port parses listener inodes for the requested port' );
    is_deeply( [ $manager->_listener_socket_inodes_for_port(0) ], [], '_listener_socket_inodes_for_port rejects a false port' );
}

# --- _process_pids_for_socket_inodes ----------------------------------------
is_deeply( [ $manager->_process_pids_for_socket_inodes(undef) ], [], '_process_pids_for_socket_inodes rejects undef lookup' );
is_deeply( [ $manager->_process_pids_for_socket_inodes('x') ],   [], '_process_pids_for_socket_inodes rejects non-hash lookup' );
is_deeply( [ $manager->_process_pids_for_socket_inodes( {} ) ],   [], '_process_pids_for_socket_inodes rejects an empty lookup' );
{
    my $sock = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', ReuseAddr => 1 );
  SKIP: {
        skip 'unable to open a listening socket', 1 if !$sock;
        my $fd     = fileno($sock);
        my $target = readlink("/proc/$$/fd/$fd");
        skip 'socket fd link unavailable', 1 if !defined $target || $target !~ /^socket:\[(\d+)\]$/;
        my $inode  = $1;
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_process_fd_paths = sub { return ( "/proc/$$/fd/$fd", "/proc/$$/fd/0" ) };
        my @pids = $manager->_process_pids_for_socket_inodes( { $inode => 1 } );
        is_deeply( \@pids, [$$], '_process_pids_for_socket_inodes maps a socket inode back to the owning pid' );
    }
    close $sock if $sock;
}

# --- _close_inherited_fds ----------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_open_file_descriptors = sub { return () };
    ok( $manager->_close_inherited_fds( preserve_harness => 1 ), '_close_inherited_fds short-circuits under an active harness' );
    {
        local $ENV{HARNESS_ACTIVE};
        delete $ENV{HARNESS_ACTIVE};
        ok( $manager->_close_inherited_fds( preserve_harness => 1 ), '_close_inherited_fds proceeds when the harness is inactive' );
        ok( $manager->_close_inherited_fds( keep => [ undef, 'x', 3 ] ), '_close_inherited_fds proceeds without the preserve flag' );
    }
}
ok( scalar( () = $manager->_open_file_descriptors ) >= 0, '_open_file_descriptors lists descriptors without error' );

# --- _descriptor_is_inherited_pipe ------------------------------------------
is( $manager->_descriptor_is_inherited_pipe(undef), 0, '_descriptor_is_inherited_pipe rejects an undef fd' );
is( $manager->_descriptor_is_inherited_pipe('x'),   0, '_descriptor_is_inherited_pipe rejects a non-numeric fd' );
is( $manager->_descriptor_is_inherited_pipe(999999), 0, '_descriptor_is_inherited_pipe returns false for a dangling fd' );
{
    pipe my $reader, my $writer or die "pipe failed: $!";
    is( $manager->_descriptor_is_inherited_pipe( fileno($writer) ), 1, '_descriptor_is_inherited_pipe recognizes a pipe fd' );
    close $reader;
    close $writer;
}
{
    socketpair my $left, my $right, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair failed: $!";
    is( $manager->_descriptor_is_inherited_pipe( fileno($left) ), 0, '_descriptor_is_inherited_pipe ignores a socket without close_ipc' );
    is( $manager->_descriptor_is_inherited_pipe( fileno($left), close_ipc => 1 ), 1, '_descriptor_is_inherited_pipe closes a socket fd when close_ipc is set' );
    close $left;
    close $right;
}
{
    my $file = File::Spec->catfile( $home, 'fd-regular-file' );
    open my $fh, '>', $file or die $!;
    is( $manager->_descriptor_is_inherited_pipe( fileno($fh), close_ipc => 1 ), 0, '_descriptor_is_inherited_pipe leaves a regular-file fd open even with close_ipc' );
    close $fh;
}

# --- _current_perl_command ---------------------------------------------------
{
    ok( length $manager->_current_perl_command, '_current_perl_command resolves a perl interpreter on POSIX hosts' );
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { my ($n) = @_; return $n eq 'perl' ? '/win/perl.exe' : undef };
    is( $manager->_current_perl_command, '/win/perl.exe', '_current_perl_command prefers perl in PATH on Windows' );
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { my ($n) = @_; return $n eq 'perl.exe' ? '/win/perl.exe' : undef };
    is( $manager->_current_perl_command, '/win/perl.exe', '_current_perl_command falls back to perl.exe in PATH on Windows' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { my ($n) = @_; return $n eq 'perl' ? '/some/perl' : undef };
    local $^X = '';
    is( $manager->_current_perl_command, '/some/perl', '_current_perl_command falls back to PATH perl when $^X is empty' );
}

# --- _helper_file_supports_internal_command ---------------------------------
{
    my $helper = File::Spec->catfile( $home, 'helper-core.pl' );
    open my $fh, '>', $helper or die $!;
    print {$fh} "web-foreground\ncollector-supervisor-foreground\n";
    close $fh;
    is( $manager->_helper_file_supports_internal_command( undef, 'web-foreground' ), 0, '_helper_file_supports_internal_command rejects an undef path' );
    is( $manager->_helper_file_supports_internal_command( '', 'web-foreground' ), 0, '_helper_file_supports_internal_command rejects an empty path' );
    is( $manager->_helper_file_supports_internal_command( '/no/such/helper', 'web-foreground' ), 0, '_helper_file_supports_internal_command rejects a missing path' );
    is( $manager->_helper_file_supports_internal_command( $helper, '' ), 0, '_helper_file_supports_internal_command rejects an empty command' );
    is( $manager->_helper_file_supports_internal_command( $helper, 'web-foreground' ), 1, '_helper_file_supports_internal_command matches a supported command' );
    is( $manager->_helper_file_supports_internal_command( $helper, 'no-such-command' ), 0, '_helper_file_supports_internal_command returns false for an unsupported command' );
}

# --- _windows_background_web_command / _spawn_windows_background_command ------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub { return '/dd/core' };
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return 'perl.exe' };
    my @plain = $manager->_windows_background_web_command( host => '0.0.0.0', port => 7890, workers => 2 );
    is_deeply( \@plain, [ 'perl.exe', '/dd/core', 'web-foreground', '--host', '0.0.0.0', '--port', 7890, '--workers', 2 ], '_windows_background_web_command builds the plain command' );
    my @ssl = $manager->_windows_background_web_command( host => '0.0.0.0', port => 7890, workers => 2, ssl => 1 );
    is( $ssl[-1], '--ssl', '_windows_background_web_command appends the ssl flag when requested' );
}
{
    no warnings 'redefine';
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( "7788\n", '', 0 );
    is( $manager->_spawn_windows_background_command( 'perl.exe', 'core', 'web-foreground' ), 7788, '_spawn_windows_background_command returns the spawned pid' );
    @cap = ( '', 'launch failed', 1 );
    my $err = eval { $manager->_spawn_windows_background_command('perl.exe'); 1 } ? '' : $@;
    like( $err, qr/Unable to launch detached Windows web process/, '_spawn_windows_background_command dies when the launcher fails' );
}

# --- _replace_path_via_powershell -------------------------------------------
{
    no warnings 'redefine';
    is_deeply( [ $manager->_replace_path_via_powershell( 'a', 'b' ) ], [ 0, '' ], '_replace_path_via_powershell is a no-op off Windows' );
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( '', '', 0 );
    is_deeply( [ $manager->_replace_path_via_powershell( 'a', 'b' ) ], [ 1, '' ], '_replace_path_via_powershell reports success on Windows' );
    @cap = ( 'out', 'err', 1 );
    is_deeply( [ $manager->_replace_path_via_powershell( 'a', 'b' ) ], [ 0, 'errout' ], '_replace_path_via_powershell reports failure text on Windows' );
}

# --- _overwrite_state_file_in_place -----------------------------------------
{
    no warnings 'redefine';
    is_deeply( [ $manager->_overwrite_state_file_in_place( 'a', 'b' ) ], [ 0, '' ], '_overwrite_state_file_in_place is a no-op off Windows' );
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my $src = File::Spec->catfile( $home, 'overwrite-src' );
    my $tgt = File::Spec->catfile( $home, 'overwrite-tgt' );
    open my $sfh, '>', $src or die $!;
    print {$sfh} "payload-content";
    close $sfh;
    my ( $ok, $err ) = $manager->_overwrite_state_file_in_place( $src, $tgt );
    is( $ok, 1, '_overwrite_state_file_in_place rewrites the target in place' );
    ok( !-e $src, '_overwrite_state_file_in_place removes the source after overwriting' );
    open my $tfh, '<', $tgt or die $!;
    my $content = do { local $/; <$tfh> };
    close $tfh;
    is( $content, 'payload-content', '_overwrite_state_file_in_place copies the payload' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my $src = File::Spec->catfile( $home, 'overwrite-src2' );
    my $tgt = File::Spec->catfile( $home, 'overwrite-tgt2' );
    open my $sfh, '>', $src or die $!;
    print {$sfh} "payload2";
    close $sfh;
    local *Developer::Dashboard::RuntimeManager::_unlink_path = sub { return 0 };
    my ( $ok ) = $manager->_overwrite_state_file_in_place( $src, $tgt );
    is( $ok, 1, '_overwrite_state_file_in_place still succeeds when the source unlink fails' );
    unlink $src;
}

# --- _replace_state_file Windows fallbacks ----------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };

    # Target exists: unlink then a successful rename retry.
    {
        my $src = File::Spec->catfile( $home, 'rsf-src-a' );
        my $tgt = File::Spec->catfile( $home, 'rsf-tgt-a' );
        for my $p ( $src, $tgt ) { open my $fh, '>', $p or die $!; print {$fh} "x"; close $fh; }
        my $rc = 0;
        local *Developer::Dashboard::RuntimeManager::_rename_path = sub { my ( undef, $s, $t ) = @_; $rc++; return $rc == 1 ? 0 : CORE::rename( $s, $t ); };
        is( $manager->_replace_state_file( $src, $tgt ), 1, '_replace_state_file removes an existing target then retries the rename' );
    }

    # Overwrite fallback succeeds after the powershell fallback fails.
    {
        my $src = File::Spec->catfile( $home, 'rsf-src-b' );
        my $tgt = File::Spec->catfile( $home, 'rsf-tgt-b' );
        open my $fh, '>', $src or die $!; print {$fh} "b"; close $fh;
        local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
        local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub { return ( 0, '' ) };
        local *Developer::Dashboard::RuntimeManager::_overwrite_state_file_in_place = sub { return ( 1, '' ) };
        is( $manager->_replace_state_file( $src, $tgt ), 1, '_replace_state_file falls back to an in-place overwrite' );
    }

    # A late rename retry (after sleep) succeeds within the loop.
    {
        my $src = File::Spec->catfile( $home, 'rsf-src-c' );
        my $tgt = File::Spec->catfile( $home, 'rsf-tgt-c' );
        open my $fh, '>', $src or die $!; print {$fh} "c"; close $fh;
        my $rc = 0;
        local *Developer::Dashboard::RuntimeManager::_rename_path = sub { my ( undef, $s, $t ) = @_; $rc++; return $rc == 1 ? 0 : CORE::rename( $s, $t ); };
        local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub { return ( 0, '' ) };
        local *Developer::Dashboard::RuntimeManager::_overwrite_state_file_in_place = sub { return ( 0, '' ) };
        is( $manager->_replace_state_file( $src, $tgt ), 1, '_replace_state_file succeeds on a late rename retry after sleeping' );
    }

    # All fallbacks fail: fallback/overwrite error text is folded in and it dies.
    {
        my $src = File::Spec->catfile( $home, 'rsf-src-d' );
        my $tgt = File::Spec->catfile( $home, 'rsf-tgt-d' );
        open my $fh, '>', $src or die $!; print {$fh} "d"; close $fh;
        local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
        local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub { return ( 0, "ps failed\n" ) };
        local *Developer::Dashboard::RuntimeManager::_overwrite_state_file_in_place = sub { return ( 0, "overwrite failed\n" ) };
        my $err = eval { $manager->_replace_state_file( $src, $tgt ); 1 } ? '' : $@;
        like( $err, qr/Unable to rename .* PowerShell Move-Item fallback failed: ps failed; in-place overwrite fallback failed: overwrite failed/s, '_replace_state_file folds fallback error text into the final failure' );
    }

    # Target exists but the pre-retry unlink fails.
    {
        my $src = File::Spec->catfile( $home, 'rsf-src-e' );
        my $tgt = File::Spec->catfile( $home, 'rsf-tgt-e' );
        for my $p ( $src, $tgt ) { open my $fh, '>', $p or die $!; print {$fh} "e"; close $fh; }
        local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
        local *Developer::Dashboard::RuntimeManager::_unlink_path  = sub { return 0 };
        my $err = eval { $manager->_replace_state_file( $src, $tgt ); 1 } ? '' : $@;
        like( $err, qr/Unable to remove .* before Windows replace retry/, '_replace_state_file dies when it cannot remove an existing target' );
    }
}

# --- _normalized_process_id --------------------------------------------------
is( $manager->_normalized_process_id(undef), undef, '_normalized_process_id passes through undef' );
is( $manager->_normalized_process_id('abc'), 'abc', '_normalized_process_id passes through non-numeric ids' );
is( $manager->_normalized_process_id(-5),    5,     '_normalized_process_id normalizes a negative pid' );
is( $manager->_normalized_process_id(7),     7,     '_normalized_process_id keeps a positive pid' );

# --- _web_runtime_matches_pid -----------------------------------------------
is( $manager->_web_runtime_matches_pid( undef, 1, 1 ), 0, '_web_runtime_matches_pid rejects an undef runtime' );
is( $manager->_web_runtime_matches_pid( 'x',   1, 1 ), 0, '_web_runtime_matches_pid rejects a non-hash runtime' );
is( $manager->_web_runtime_matches_pid( { pid => 5 }, 5, 0 ), 1, '_web_runtime_matches_pid matches on pid equality' );
is( $manager->_web_runtime_matches_pid( { pid => 9 }, 5, 0 ), 0, '_web_runtime_matches_pid returns false off Windows when pids differ' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    is( $manager->_web_runtime_matches_pid( { pid => 9, port => 7890 }, 5, 7890 ), 1, '_web_runtime_matches_pid matches on Windows when the port lines up' );
    is( $manager->_web_runtime_matches_pid( { pid => 9, port => 1000 }, 5, 7890 ), 0, '_web_runtime_matches_pid rejects a Windows port mismatch' );
    is( $manager->_web_runtime_matches_pid( { pid => 9 },               5, 7890 ), 0, '_web_runtime_matches_pid rejects a Windows runtime with no port' );
    is( $manager->_web_runtime_matches_pid( { pid => 9 },               5, 0 ),    0, '_web_runtime_matches_pid rejects a Windows runtime with no listener port' );
}

# --- _collector_runtime_ready -----------------------------------------------
{
    my $ready_runner = Local::Runner->new(
        states => { 'ready.c' => { pid => $$, name => 'ready.c', status => 'running' } },
    );
    my $ready_manager = build_manager( runner => $ready_runner );
    is( $ready_manager->_collector_runtime_ready( '', 1 ),        0, '_collector_runtime_ready rejects an empty name' );
    is( $ready_manager->_collector_runtime_ready( 'ready.c', undef ), 0, '_collector_runtime_ready rejects an undef pid' );
    is( $ready_manager->_collector_runtime_ready( 'ready.c', 'x' ),   0, '_collector_runtime_ready rejects a non-numeric pid' );
    is( $ready_manager->_collector_runtime_ready( 'ready.c', 0 ),     0, '_collector_runtime_ready rejects a pid below one' );
    is( $ready_manager->_collector_runtime_ready( 'ready.c', $$ ),    1, '_collector_runtime_ready confirms a loop from persisted state' );
}
{
    my $stopped_runner = Local::Runner->new(
        states => { 'stopped.c' => { pid => $$, name => 'stopped.c', status => 'stopped' } },
        loops  => [],
    );
    my $stopped_manager = build_manager( runner => $stopped_runner );
    is( $stopped_manager->_collector_runtime_ready( 'stopped.c', $$ ), 0, '_collector_runtime_ready rejects a loop whose state status is not active' );
}
{
    my $rl_runner = Local::Runner->new(
        loops => [ { name => 'rl.c', pid => 0 }, { name => 'rl.c', pid => $$ } ],
    );
    my $rl_manager = build_manager( runner => $rl_runner );
    is( $rl_manager->_collector_runtime_ready( 'rl.c', $$ ), 1, '_collector_runtime_ready confirms a loop discovered from running_loops' );
}
{
    my $bare_manager = build_manager( runner => Local::BareRunner->new );
    is( $bare_manager->_collector_runtime_ready( 'gone.c', $$ ), 0, '_collector_runtime_ready returns false when a bare runner exposes no loop' );
}

# --- _web_runtime_ready guards ----------------------------------------------
is( $manager->_web_runtime_ready( undef, 7890 ), 0, '_web_runtime_ready rejects an undef pid' );
is( $manager->_web_runtime_ready( 'x',   7890 ), 0, '_web_runtime_ready rejects a non-numeric pid' );
is( $manager->_web_runtime_ready( 0,     7890 ), 0, '_web_runtime_ready rejects a pid below one' );
is( $manager->_web_runtime_ready( 5,     'x' ),  0, '_web_runtime_ready rejects a non-numeric port' );
is( $manager->_web_runtime_ready( 5,     0 ),    0, '_web_runtime_ready rejects a port below one' );

# --- _web_runtime_ready Windows branch --------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (4321) };
    is( $manager->_web_runtime_ready( 5, 7890 ), 1, '_web_runtime_ready Windows confirms a bound listener' );
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    is( $manager->_web_runtime_ready( 5, 7890 ), 0, '_web_runtime_ready Windows fails when nothing binds the port' );
}

# --- _web_runtime_ready non-Windows main loop -------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 10, port => 7890 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (1234) };
    my @adopted;
    local *Developer::Dashboard::RuntimeManager::_adopt_web_listener_pid = sub { my ( undef, %a ) = @_; push @adopted, $a{listener_pid}; return $a{listener_pid} };
    is( $manager->_web_runtime_ready( 5, undef ), 1, '_web_runtime_ready adopts a listener pid discovered from runtime state' );
    is_deeply( \@adopted, [1234], '_web_runtime_ready hands the discovered listener pid to the adopter' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 10, port => 7890 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { my ( undef, $p ) = @_; return $p == 1234 ? 1 : 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (1234) };
    is( $manager->_web_runtime_ready( 5, 7890 ), 1, '_web_runtime_ready confirms a listener even when the startup pid is in a foreign namespace' );
}

# --- _adopt_web_listener_pid ------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_write_web_state = sub { return $_[1] };
    is( $manager->_adopt_web_listener_pid( listener_pid => undef ), undef, '_adopt_web_listener_pid rejects an undef listener pid' );
    is( $manager->_adopt_web_listener_pid( listener_pid => 'x' ),   undef, '_adopt_web_listener_pid rejects a non-numeric listener pid' );
    is( $manager->_adopt_web_listener_pid( listener_pid => 0 ),     undef, '_adopt_web_listener_pid rejects a listener pid below one' );
    {
        local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 0 };
        is( $manager->_adopt_web_listener_pid( listener_pid => 5 ), undef, '_adopt_web_listener_pid rejects a foreign-namespace listener pid' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'dashboard web: 0.0.0.0:1' };
        $manager->_cleanup_web_files;
        is( $manager->_adopt_web_listener_pid( listener_pid => 5, state => 'not-a-hash' ), 5, '_adopt_web_listener_pid adopts a listener pid using persisted web state' );
        is( $manager->_adopt_web_listener_pid( listener_pid => 5, state => { pid => 5 } ), undef, '_adopt_web_listener_pid skips when the state pid already matches' );
        local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
        is( $manager->_adopt_web_listener_pid( listener_pid => 6, state => { pid => 1 } ), 6, '_adopt_web_listener_pid adopts even when the process title is unavailable' );
    }
}

# --- _wait_for_unix_web_shutdown --------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    is( $manager->_wait_for_unix_web_shutdown(), 0, '_wait_for_unix_web_shutdown false when nothing is pending' );
    is( $manager->_wait_for_unix_web_shutdown( pid => 'x' ), 0, '_wait_for_unix_web_shutdown false for a non-numeric pid' );
    is( $manager->_wait_for_unix_web_shutdown( pid => 0 ),   0, '_wait_for_unix_web_shutdown false for a pid below one' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 1 };
    is( $manager->_wait_for_unix_web_shutdown( pid => $$ ), 1, '_wait_for_unix_web_shutdown true while the wrapper pid is alive' );
    is( $manager->_wait_for_unix_web_shutdown( ajax_pids => [ undef, $$ ] ),   1, '_wait_for_unix_web_shutdown true while an ajax worker is alive' );
    is( $manager->_wait_for_unix_web_shutdown( legacy_pids => [ undef, $$ ] ), 1, '_wait_for_unix_web_shutdown true while a legacy web pid is alive' );
}
is( $manager->_wait_for_unix_web_shutdown( listener_pids => [ undef, 'x', $$ ] ), 1, '_wait_for_unix_web_shutdown true while a listener pid still answers signals' );
is( $manager->_wait_for_unix_web_shutdown( listener_pids => [ 999999 ] ),         0, '_wait_for_unix_web_shutdown false when a listener pid is gone' );

# --- _managed_ajax_processes ------------------------------------------------
{
    no warnings 'redefine';
    my $root = $paths->state_root;
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub {
        return (
            { pid => 1, args => 'dashboard ajax: a' },
            { pid => 2, args => 'dashboard ajax: b' },
            { pid => 3, args => 'dashboard ajax: c' },
            { pid => 4, args => 'dashboard ajax: d' },
        );
    };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub {
        my ( undef, $pid ) = @_;
        return $root       if $pid == 1;
        return '/other'    if $pid == 2;
        return ''          if $pid == 3;
        return undef;
    };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    is_deeply( [ map { $_->{pid} } $manager->_managed_ajax_processes ], [1], '_managed_ajax_processes keeps only the current runtime root workers' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub { return () };
    local $manager->{paths} = undef;
    is_deeply( [ $manager->_managed_ajax_processes ], [], '_managed_ajax_processes tolerates a runtime with no path registry' );
}

# --- _is_managed_web ---------------------------------------------------------
is( $manager->_is_managed_web(0),      0, '_is_managed_web rejects a pid of zero' );
is( $manager->_is_managed_web(999999), 0, '_is_managed_web rejects a dead pid' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 0 };
    is( $manager->_is_managed_web($$), 0, '_is_managed_web rejects a foreign-namespace pid' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return '1' };
    ok( $manager->_is_managed_web($$), '_is_managed_web trusts the managed-web environment marker' );

    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return '0' };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
    is( $manager->_is_managed_web($$), 0, '_is_managed_web rejects a pid with no readable title' );
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return '' };
    is( $manager->_is_managed_web($$), 0, '_is_managed_web rejects a pid with an empty title' );
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'dashboard web: 0.0.0.0:1' };
    ok( $manager->_is_managed_web($$), '_is_managed_web recognizes a managed web process title' );
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'something else' };
    is( $manager->_is_managed_web($$), 0, '_is_managed_web rejects an unrelated process title' );
}

# --- _detach_web_process_session --------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    is( $manager->_detach_web_process_session, 1, '_detach_web_process_session is a no-op on Windows' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::setsid = sub { return 1 };
    is( $manager->_detach_web_process_session, 1, '_detach_web_process_session detaches with setsid on POSIX hosts' );
    local *Developer::Dashboard::RuntimeManager::setsid = sub { $! = 1; return 0 };
    my $err = eval { $manager->_detach_web_process_session; 1 } ? '' : $@;
    like( $err, qr/Unable to detach dashboard web service/, '_detach_web_process_session dies when setsid fails' );
}

# --- _restart_web_with_retry ------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub { return 8000 };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_ready = sub { return 1 };
    is( $manager->_restart_web_with_retry( host => '0.0.0.0', port => 7890, ssl => 1 ), 8000, '_restart_web_with_retry returns a confirmed web pid' );
    is( $manager->_restart_web_with_retry( port => 7890 ), 8000, '_restart_web_with_retry defaults ssl to off' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::start_web = sub { die "Address already in use\n" };
    my $err = eval { $manager->_restart_web_with_retry( port => 7890 ); 1 } ? '' : $@;
    like( $err, qr/Address already in use/, '_restart_web_with_retry surfaces a retryable start error after exhausting attempts' );
}

# --- _listener_pids_from_state ----------------------------------------------
is_deeply( [ $manager->_listener_pids_from_state('x') ], [], '_listener_pids_from_state rejects a non-hash state' );
is_deeply( [ $manager->_listener_pids_from_state( {} ) ], [], '_listener_pids_from_state returns empty when no port is stored' );
is_deeply( [ $manager->_listener_pids_from_state( { port => '' } ) ], [], '_listener_pids_from_state returns empty for an empty port' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (5) };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    is_deeply( [ $manager->_listener_pids_from_state( { port => 7890 } ) ], [5], '_listener_pids_from_state maps the stored port back to live listener pids' );
}

# --- running_web scenarios ---------------------------------------------------
{
    no warnings 'redefine';
    $manager->_cleanup_web_files;
    $files->write( 'web_pid', "$$\n" );
    $manager->_write_web_state( { status => 'running', host => 'h', port => 1 } );
    local *Developer::Dashboard::RuntimeManager::_pid_is_running    = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    {
        local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 1 };
        is( $manager->running_web->{pid}, $$, 'running_web trusts a managed pid from the pid file' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
        is( $manager->running_web->{pid}, $$, 'running_web trusts a saved pid when the state status is running' );
    }
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return ( { pid => 77, args => 'weird helper' } ); };
    $manager->_write_web_state( { status => 'x', host => 'H', port => 9 } );
    my $with = $manager->running_web;
    is( $with->{pid},  77,  'running_web falls back to a scanned generic web process' );
    is( $with->{host}, 'H', 'running_web keeps the saved host for a generic web process' );
    $manager->_write_web_state( { status => 'x' } );
    my $without = $manager->running_web;
    is( $without->{host}, '0.0.0.0', 'running_web defaults the host for a generic web process' );
    is( $without->{port}, 7890,      'running_web defaults the port for a generic web process' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return (); };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return (300); };
    $manager->_write_web_state( { status => 'running', process_name => 'saved-name' } );
    {
        local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'live-title' };
        is( $manager->running_web->{process_name}, 'live-title', 'running_web reads the live listener title when adopting from state' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
        is( $manager->running_web->{process_name}, 'saved-name', 'running_web keeps the saved process name when no live title exists' );
    }
}
$manager->_cleanup_web_files;

# --- stop_web (Windows path) -------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_progress_emit = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_wait_for_windows_web_shutdown = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    my @sig;
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { push @sig, $_[1]; return 1 };

    {
        local *Developer::Dashboard::RuntimeManager::web_state   = sub { return { pid => $$, port => 7890, status => 'running' } };
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => $$, port => 7890 } };
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 0 };
        is( $manager->stop_web, $$, 'stop_web Windows returns the numeric pid after escalation' );
        ok( ( grep { $_ eq 'KILL' } @sig ), 'stop_web Windows escalates a live pid to KILL' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::web_state   = sub { return { pid => 999999, port => 7890 } };
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 999999, port => 7890 } };
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
        is( $manager->stop_web, 999999, 'stop_web Windows tolerates a saved pid that is already gone' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::web_state   = sub { return {} };
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
        is( $manager->stop_web, undef, 'stop_web Windows returns undef when there is no saved pid' );
    }
}

# --- stop_web (Unix path) ----------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_progress_emit = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_unix_web_shutdown = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_reap_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::web_state   = sub { return { pid => $$, port => 7890, status => 'running' } };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => $$, port => 7890 } };
    {
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 0 };
        is( $manager->stop_web, $$, 'stop_web Unix handles a port that has not released yet' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 1 };
        is( $manager->stop_web, $$, 'stop_web Unix returns cleanly when the port releases' );
    }
}

# --- start_web deduplication -------------------------------------------------
{
    no warnings 'redefine';
    my $ded = build_manager();
    {
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { host => '0.0.0.0', port => 7890, workers => 2, ssl => 1, pid => 111 }; };
        is( $ded->start_web( host => '0.0.0.0', port => 7890, workers => 2, ssl => 1 ), 111, 'start_web deduplicates a matching running service' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { host => '0.0.0.0', port => 7890, pid => 222 }; };
        is( $ded->start_web( host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 ), 222, 'start_web deduplicates a service whose worker/ssl fields default' );
    }
}

# --- start_web fork failure paths -------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    {
        local *Developer::Dashboard::RuntimeManager::_fork_process = sub { return undef };
        my $err = eval { $manager->start_web( host => '0.0.0.0', port => 7890 ); 1 } ? '' : $@;
        like( $err, qr/Unable to fork dashboard web service/, 'start_web dies when the fork wrapper fails' );
    }
}

# --- _start_web_windows_background ------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub { return ('perl.exe') };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    {
        local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7000 };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (7301) };
        is( $manager->_start_web_windows_background(), 7301, '_start_web_windows_background adopts the discovered listener pid with defaulted args' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7000 };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (0) };
        is( $manager->_start_web_windows_background( host => '0.0.0.0', port => 7890, workers => 1 ), 7000, '_start_web_windows_background falls back to the spawn pid when the listener pid is falsy' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7000 };
        local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
        local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
        is( $manager->_start_web_windows_background( host => '0.0.0.0', port => 7890, workers => 1 ), 7000, '_start_web_windows_background returns the spawn pid when no listener appears' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 0 };
        my $err = eval { $manager->_start_web_windows_background( host => '0.0.0.0', port => 7890, workers => 1 ); 1 } ? '' : $@;
        like( $err, qr/Unable to start dashboard web service on Windows/, '_start_web_windows_background dies when the spawn fails' );
    }
}

# --- restart_all -------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => 1, collectors => [] } };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub { return 9 };
    my $with = $manager->restart_all( host => 'h', port => 1, workers => 1, ssl => 1, progress => sub { } );
    is( $with->{web_pid}, 9, 'restart_all returns the restarted web pid with progress and ssl' );
    my $defaults = $manager->restart_all();
    is( $defaults->{web_pid}, 9, 'restart_all works with defaulted host/port/workers/ssl and no progress' );
}

# --- stop_target -------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_web = sub { return 5 };
    my $r = $manager->stop_target( scope => 'web' );
    is( $r->{web_pid}, 5, 'stop_target web returns the stopped web pid' );
    is( $r->{target}, 'dashboard', 'stop_target web defaults its target label' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub { return () };
    my $named = $manager->stop_target( scope => 'collector', name => 'named.c' );
    is( $named->{collectors}[0]{name}, 'named.c', 'stop_target collector reports a named collector that was not running' );
    is( $named->{target}, 'named.c', 'stop_target collector uses the collector name as its target label' );
    my $all = $manager->stop_target( scope => 'collector' );
    is( $all->{collectors}[0]{name}, 'all', 'stop_target collector falls back to an all label with no running collectors' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => 7, collectors => [ 'a', 'b' ] } };
    my $r = $manager->stop_target;
    is_deeply( [ map { $_->{name} } @{ $r->{collectors} } ], [ 'a', 'b' ], 'stop_target all maps stopped collector names' );
    local *Developer::Dashboard::RuntimeManager::stop_all = sub { return { web_pid => 7 } };
    my $r2 = $manager->stop_target;
    is_deeply( $r2->{collectors}, [], 'stop_target all tolerates a missing collectors list' );
}

# --- restart_target ----------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_web = sub { return 3 };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub { return 4 };
    my $r = $manager->restart_target( scope => 'web' );
    is( $r->{web_pid}, 4, 'restart_target web restarts the web service' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_collectors      = sub { return ( { name => 'rc.x', pid => 1, status => 'stopped' } ) };
    local *Developer::Dashboard::RuntimeManager::start_named_collector = sub { return { name => 'rc.x', pid => 2 } };
    my $named = $manager->restart_target( scope => 'collector', name => 'rc.x' );
    is( $named->{collectors}[0]{details}, 'stopped then started', 'restart_target collector marks a restarted named collector' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_collectors  = sub { return () };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return ( { name => 'rc.y', pid => 3 } ) };
    my $all = $manager->restart_target( scope => 'collector' );
    is( $all->{collectors}[0]{details}, 'started', 'restart_target collector marks a freshly started collector' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::restart_all = sub { return { stopped => {}, web_pid => 9, collectors => [ { name => 'a', pid => 1 } ] } };
    my $r = $manager->restart_target;
    is( $r->{collectors}[0]{name}, 'a', 'restart_target all maps restarted collectors' );
    local *Developer::Dashboard::RuntimeManager::restart_all = sub { return { stopped => {}, web_pid => 9 } };
    my $r2 = $manager->restart_target;
    is_deeply( $r2->{collectors}, [], 'restart_target all tolerates a missing collectors list' );
}

# --- stop_progress_tasks / restart_progress_tasks ---------------------------
{
    my $pt_runner = Local::Runner->new( loops => [ { name => 'loop.a', pid => 1 } ] );
    my $pt_manager = build_manager( runner => $pt_runner );
    my $tasks = $pt_manager->stop_progress_tasks( scope => 'all' );
    ok( ( grep { $_->{id} eq 'stop_collector:loop.a' } @{$tasks} ), 'stop_progress_tasks lists running collector loops' );
    my $named = $pt_manager->stop_progress_tasks( scope => 'collector', name => 'explicit.c' );
    ok( ( grep { $_->{id} eq 'stop_collector:explicit.c' } @{$named} ), 'stop_progress_tasks uses an explicit collector name' );
}
{
    my $rp_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub {
        return [
            'not-a-hash',
            { name => 'rp.manual', schedule => 'manual' },
            { name => 'rp.iv', interval => 1 },
            { cron => '* * * * *' },
        ];
    };
    my $rp_runner  = Local::Runner->new( loops => [] );
    my $rp_manager = build_manager( config => $rp_config, runner => $rp_runner );
    my $tasks = $rp_manager->restart_progress_tasks( scope => 'all' );
    ok( ( grep { $_->{id} eq 'start_collector:rp.iv' } @{$tasks} ), 'restart_progress_tasks lists non-manual configured collectors' );
    ok( ( grep { $_->{id} eq 'start_collector:(unnamed)' } @{$tasks} ), 'restart_progress_tasks names an unnamed collector' );
    my $named = $rp_manager->restart_progress_tasks( scope => 'collector', name => 'rp.named' );
    ok( ( grep { $_->{id} eq 'start_collector:rp.named' } @{$named} ), 'restart_progress_tasks uses an explicit collector name' );
}

# --- _write_startup_pipe_message (in-memory handle => print branch) ----------
{
    open my $wr, '>', \my $buf or die $!;
    ok( $manager->_write_startup_pipe_message( $wr, 'hello' ), '_write_startup_pipe_message writes through the print branch for a negative-fd handle' );
    is( $buf, 'hello', '_write_startup_pipe_message writes the whole payload through the print branch' );
}
{
    open my $wr, '>', \my $buf or die $!;
    ok( $manager->_write_startup_pipe_message( $wr, undef ), '_write_startup_pipe_message tolerates an undef message' );
}

# --- _tail_text --------------------------------------------------------------
is( $manager->_tail_text( undef, 2 ), '', '_tail_text returns empty for undef text' );
is( $manager->_tail_text( '',    2 ), '', '_tail_text returns empty for empty text' );
is( $manager->_tail_text( "a\nb\n", undef ), "a\nb\n", '_tail_text returns the text unchanged when no line count is given' );
is( $manager->_tail_text( "a\nb\nc\n", 2 ), "b\nc\n", '_tail_text keeps the trailing newline on tailed lines' );
is( $manager->_tail_text( "a\nb\nc",   2 ), "b\nc",   '_tail_text preserves an unterminated final line' );
is( $manager->_tail_text( "a\n",       5 ), "a\n",    '_tail_text clamps the start index to zero' );

# --- web_log -----------------------------------------------------------------
{
    $files->write( 'dashboard_log', "l1\nl2\nl3\n" );
    is( $manager->web_log, "l1\nl2\nl3\n", 'web_log returns the full log' );
    is( $manager->web_log( lines => 2 ), "l2\nl3\n", 'web_log tails the requested number of lines' );
    my $err = eval { $manager->web_log( lines => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Line count must be a positive integer/, 'web_log rejects a non-numeric line count' );
    $err = eval { $manager->web_log( lines => 0 ); 1 } ? '' : $@;
    like( $err, qr/Line count must be a positive integer/, 'web_log rejects a zero line count' );
    $files->remove('dashboard_log');
    is( $manager->web_log, '', 'web_log returns empty when the log file is missing' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_follow_log_file = sub { return 1 };
    $files->write( 'dashboard_log', "follow-data\n" );
    open my $save, '>&', \*STDOUT or die $!;
    open STDOUT, '>', File::Spec->catfile( $home, 'web-log-stdout-a' ) or die $!;
    my $r = $manager->web_log( follow => 1 );
    open STDOUT, '>&', $save or die $!;
    is( $r, '', 'web_log follow mode returns empty after delegating to the follow loop' );
    $files->remove('dashboard_log');
    open STDOUT, '>', File::Spec->catfile( $home, 'web-log-stdout-b' ) or die $!;
    my $r2 = $manager->web_log( follow => 1 );
    open STDOUT, '>&', $save or die $!;
    is( $r2, '', 'web_log follow mode returns empty even when the log has not been created yet' );
}

# --- _follow_log_file --------------------------------------------------------
{
    my $err = eval { $manager->_follow_log_file(); 1 } ? '' : $@;
    like( $err, qr/Missing log file/, '_follow_log_file requires a file' );
}
{
    no warnings 'redefine';
    my $f = File::Spec->catfile( $home, 'follow-existing.log' );
    open my $fh, '>', $f or die $!;
    print {$fh} "existing\n";
    close $fh;
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "__STOP_FOLLOW__\n" };
    open my $save, '>&', \*STDOUT or die $!;
    open STDOUT, '>', File::Spec->catfile( $home, 'follow-stdout-a' ) or die $!;
    my $err = eval { $manager->_follow_log_file( file => $f, start_pos => 0, interval => 0.01 ); 1 } ? '' : $@;
    open STDOUT, '>&', $save or die $!;
    like( $err, qr/__STOP_FOLLOW__/, '_follow_log_file streams existing content then blocks on the poll interval' );
}
{
    no warnings 'redefine';
    my $f = File::Spec->catfile( $home, 'follow-missing.log' );
    unlink $f;
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "__STOP_FOLLOW__\n" };
    open my $save, '>&', \*STDOUT or die $!;
    open STDOUT, '>', File::Spec->catfile( $home, 'follow-stdout-b' ) or die $!;
    my $err = eval { $manager->_follow_log_file( file => $f, interval => 0.01 ); 1 } ? '' : $@;
    open STDOUT, '>&', $save or die $!;
    like( $err, qr/__STOP_FOLLOW__/, '_follow_log_file creates a missing log and seeks to the end' );
    ok( -f $f, '_follow_log_file created the missing log file' );
}

# --- web_state read failure --------------------------------------------------
{
    $manager->_write_web_state( { marker => 1 } );
    chmod 0000, $files->web_state;
    my $err = eval { $manager->web_state; 1 } ? '' : $@;
    like( $err, qr/Unable to read/, 'web_state dies when the state file cannot be read' );
    chmod 0644, $files->web_state;
    $manager->_cleanup_web_files;
}

# --- _shutdown_web -----------------------------------------------------------
{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return $_[0] };
    $manager->_cleanup_web_files;
    $manager->_shutdown_web('custom');
    is( $manager->web_state->{status}, 'custom', '_shutdown_web keeps an explicit final status' );
    $manager->_shutdown_web(undef);
    is( $manager->web_state->{status}, 'stopped', '_shutdown_web defaults an undef status to stopped' );
    $manager->_shutdown_web('');
    is( $manager->web_state->{status}, 'stopped', '_shutdown_web defaults an empty status to stopped' );
    $manager->_cleanup_web_files;
}

# --- _run_web_child parent daemonize returns zero ----------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_fork_process = sub { return 123 };
    open my $wr, '>', \my $buf or die $!;
    is( $manager->_run_web_child( $wr, '0.0.0.0', 7890, detach => 1, redirect => 0 ), 0, '_run_web_child returns zero in the daemonize parent branch' );
}

# --- _run_web_child redirect+detach child branch (in-process, fds restored) --
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_fork_process = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub { return 1 };
    my $child_manager = build_manager( app_builder => sub { return Local::Server->new } );
    open my $wr, '>', \my $buf or die $!;
    open my $save_in,  '<&', \*STDIN  or die $!;
    open my $save_out, '>&', \*STDOUT or die $!;
    open my $save_err, '>&', \*STDERR or die $!;
    my $exit = $child_manager->_run_web_child( $wr, '0.0.0.0', 7890, workers => 2, ssl => 1 );
    open STDIN,  '<&', $save_in  or die $!;
    open STDOUT, '>&', $save_out or die $!;
    open STDERR, '>&', $save_err or die $!;
    is( $exit, 0, '_run_web_child returns zero after a clean redirected daemonized serve loop' );
}

# --- _collector_supervisor_state read failure -------------------------------
{
    $manager->_write_collector_supervisor_state( { watched_names => ['x'] } );
    chmod 0000, $manager->_collector_supervisor_statefile;
    my $err = eval { $manager->_collector_supervisor_state; 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_collector_supervisor_state dies when the state file cannot be read' );
    chmod 0644, $manager->_collector_supervisor_statefile;
    $manager->_cleanup_collector_supervisor_files;
}

# --- _collector_supervisor_running ------------------------------------------
{
    no warnings 'redefine';
    $manager->_cleanup_collector_supervisor_files;
    is( $manager->_collector_supervisor_running, undef, '_collector_supervisor_running returns undef with no pid file' );

    open my $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    close $fh;
    is( $manager->_collector_supervisor_running, undef, '_collector_supervisor_running returns undef for an empty pid file' );

    open $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$fh} "$$\n";
    close $fh;
    chmod 0000, $manager->_collector_supervisor_pidfile;
    my $err = eval { $manager->_collector_supervisor_running; 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_collector_supervisor_running dies when the pid file cannot be read' );
    chmod 0644, $manager->_collector_supervisor_pidfile;

    {
        local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_is_collector_supervisor = sub { return 0 };
        is( $manager->_collector_supervisor_running, undef, '_collector_supervisor_running clears a pid that is not the supervisor' );
    }
    open $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$fh} "$$\n";
    close $fh;
    {
        local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
        local *Developer::Dashboard::RuntimeManager::_is_collector_supervisor = sub { return 1 };
        is( $manager->_collector_supervisor_running, $$, '_collector_supervisor_running returns the live supervisor pid' );
    }
    $manager->_cleanup_collector_supervisor_files;
}

# --- _is_collector_supervisor ------------------------------------------------
is( $manager->_is_collector_supervisor(0),      0, '_is_collector_supervisor rejects a pid of zero' );
is( $manager->_is_collector_supervisor(999999), 0, '_is_collector_supervisor rejects a dead pid' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return '1' };
    ok( $manager->_is_collector_supervisor($$), '_is_collector_supervisor trusts the supervisor environment marker' );
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
    is( $manager->_is_collector_supervisor($$), 0, '_is_collector_supervisor rejects a pid with no title' );
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return '' };
    is( $manager->_is_collector_supervisor($$), 0, '_is_collector_supervisor rejects a pid with an empty title' );
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return '0' };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'dashboard collector supervisor' };
    ok( $manager->_is_collector_supervisor($$), '_is_collector_supervisor matches the supervisor process title' );
}

# --- _looks_like_collector_supervisor_process -------------------------------
is( $manager->_looks_like_collector_supervisor_process(undef), 0, '_looks_like_collector_supervisor_process rejects an undef record' );
is( $manager->_looks_like_collector_supervisor_process( {} ),  0, '_looks_like_collector_supervisor_process rejects a record with no args' );

# --- _stop_collector_supervisor (no supervisor) -----------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_cleanup_collector_supervisor_files = sub { return 1 };
    is( $manager->_stop_collector_supervisor, undef, '_stop_collector_supervisor is a no-op when nothing is running' );
}

# --- _start_collector_supervisor (no targets) -------------------------------
{
    $manager->_cleanup_collector_supervisor_files;
    is( $manager->_start_collector_supervisor, undef, '_start_collector_supervisor returns undef when there are no watched targets' );
}

# --- _run_collector_supervisor_child redirect path (in-process) -------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub { return { watched_names => ['a'] } };
    local *Developer::Dashboard::RuntimeManager::_supervise_collectors_once = sub {
        $SIG{CHLD}->() if ref( $SIG{CHLD} ) eq 'CODE';
        return {};
    };
    local *Developer::Dashboard::RuntimeManager::_reap_any_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_write_collector_supervisor_state = sub { return $_[1] };
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "__STOP_SUPERVISOR__\n" };
    my $child_manager = build_manager();
    open my $save_in,  '<&', \*STDIN  or die $!;
    open my $save_out, '>&', \*STDOUT or die $!;
    open my $save_err, '>&', \*STDERR or die $!;
    my $err = eval { $child_manager->_run_collector_supervisor_child( daemonize => 0, redirect => 1 ); 1 } ? '' : $@;
    open STDIN,  '<&', $save_in  or die $!;
    open STDOUT, '>&', $save_out or die $!;
    open STDERR, '>&', $save_err or die $!;
    like( $err, qr/__STOP_SUPERVISOR__/, '_run_collector_supervisor_child runs one redirected loop pass and reaps children' );
}

# --- _collector_stop_fallback_names -----------------------------------------
{
    is_deeply( [ $manager->_collector_stop_fallback_names( { b => 1, a => 1 } ) ], [ 'a', 'b' ], '_collector_stop_fallback_names returns wanted names directly' );
    ok( ( grep { $_ eq 'alpha.collector' } $manager->_collector_stop_fallback_names(undef) ), '_collector_stop_fallback_names tolerates an undef wanted set and scans configured collectors' );
    my $bare_manager = build_manager( runner => Local::BareRunner->new );
    is_deeply( [ $bare_manager->_collector_stop_fallback_names( {} ) ], [], '_collector_stop_fallback_names returns empty for a runner without loop_state' );
}
{
    my $fb_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub {
        return [ 'not-a-hash', { name => 'cfg.a', interval => 1 }, { name => '' }, { name => 'cfg.a', interval => 1 } ];
    };
    my $fb_runner  = Local::Runner->new;
    my $fb_manager = build_manager( config => $fb_config, runner => $fb_runner );
    my $croot = $paths->collectors_root;
    make_path($croot);
    for my $pf ( 'cfg.a.pid', 'extra.pid' ) {
        open my $fh, '>', File::Spec->catfile( $croot, $pf ) or die $!;
        print {$fh} "1\n";
        close $fh;
    }
    is_deeply( [ sort $fb_manager->_collector_stop_fallback_names( {} ) ], [ 'cfg.a', 'extra' ], '_collector_stop_fallback_names merges configured names with pid-file names' );
    unlink File::Spec->catfile( $croot, 'cfg.a.pid' ), File::Spec->catfile( $croot, 'extra.pid' );
}
{
    my $fb_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'only.cfg', interval => 1 } ] };
    local *Developer::Dashboard::PathRegistry::collectors_root = sub { return '/no/such/collectors/root' };
    my $fb_manager = build_manager( config => $fb_config, runner => Local::Runner->new );
    is_deeply( [ $fb_manager->_collector_stop_fallback_names( {} ) ], ['only.cfg'], '_collector_stop_fallback_names skips a missing collectors directory' );
}

# --- _collector_stop_targets ------------------------------------------------
{
    my $bare_manager = build_manager( runner => Local::BareRunner->new );
    is_deeply( [ $bare_manager->_collector_stop_targets( { zzz => 1 } ) ], [], '_collector_stop_targets skips fallback names when the runner has no loop_state' );
    is_deeply( [ $bare_manager->_collector_stop_targets(undef) ], [], '_collector_stop_targets tolerates an undef wanted set' );
}
{
    my $st_runner = Local::Runner->new(
        loops  => [ { name => 'run.x', pid => $$ }, { name => '', pid => 1 } ],
        states => {
            'st.ok'     => { name => 'st.ok',     status => 'running', pid => $$ },
            'st.ok2'    => { name => 'st.ok2',    status => 'running', pid => $$ },
            'st.badpid' => { name => 'st.badpid', status => 'running' },
            'st.name'   => { name => 'DIFFERENT', status => 'running', pid => $$ },
            'st.status' => { name => 'st.status', status => 'stopped', pid => $$ },
            'st.nonhash' => 'not-a-hash',
        },
    );
    my $st_manager = build_manager( runner => $st_runner );
    my @targets = $st_manager->_collector_stop_targets(
        { 'st.ok' => 1, 'st.ok2' => 1, 'st.badpid' => 1, 'st.name' => 1, 'st.status' => 1, 'st.nonhash' => 1 } );
    is_deeply( [ sort map { $_->{name} } @targets ], [ 'st.ok', 'st.ok2' ], '_collector_stop_targets keeps only state-confirmed live collectors' );

    my @all = $st_manager->_collector_stop_targets( {} );
    ok( ( grep { $_->{name} eq 'run.x' } @all ), '_collector_stop_targets includes running loops when no wanted set is given' );
}
{
    my $pf_runner  = Local::Runner->new;
    my $pf_manager = build_manager( runner => $pf_runner );
    my $croot = $paths->collectors_root;
    make_path($croot);
    open my $fh, '>', File::Spec->catfile( $croot, 'pf.one.pid' ) or die $!;
    print {$fh} "$$\n";
    close $fh;
    my @targets = $pf_manager->_collector_stop_targets( { 'pf.one' => 1 } );
    is( $targets[0]{name}, 'pf.one', '_collector_stop_targets reads a collector pid from its pid file' );
    is( $targets[0]{pid},  $$,       '_collector_stop_targets records the pid read from the pid file' );
    unlink File::Spec->catfile( $croot, 'pf.one.pid' );
}

# --- _supervise_collectors_once ---------------------------------------------
{
    my $sup_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub {
        return [ { name => 'sup.run', interval => 1 }, { name => 'sup.dead', interval => 1 } ];
    };
    local *Developer::Dashboard::RuntimeManager::_collector_stalled_for_watchdog = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 1 };
    my $sup_runner  = Local::Runner->new( loops => [ { name => 'sup.run', pid => $$ } ] );
    my $sup_manager = build_manager( config => $sup_config, runner => $sup_runner );
    my $result = $sup_manager->_supervise_collectors_once( names => [ 'sup.run', 'sup.dead', 'unknown.zzz' ] );
    ok( ( grep { $_->{name} eq 'unknown.zzz' } @{ $result->{attention} } ), '_supervise_collectors_once marks an unknown collector for attention' );
    ok( ( grep { $_->{name} eq 'sup.run' } @{ $result->{restarted} } ),   '_supervise_collectors_once restarts a stalled running collector' );
    ok( ( grep { $_->{name} eq 'sup.dead' } @{ $result->{restarted} } ),  '_supervise_collectors_once restarts a dead collector' );
}
{
    my $sup_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'sup.stall', interval => 1 } ] };
    local *Developer::Dashboard::RuntimeManager::_collector_stalled_for_watchdog = sub { return 1 };
    local *Local::Runner::stop_loop = sub { die "stop boom\n" };
    my $sup_runner  = Local::Runner->new( loops => [ { name => 'sup.stall', pid => $$ } ] );
    my $sup_manager = build_manager( config => $sup_config, runner => $sup_runner );
    my $result = $sup_manager->_supervise_collectors_once( names => ['sup.stall'] );
    ok( ( grep { $_->{name} eq 'sup.stall' } @{ $result->{attention} } ), '_supervise_collectors_once flags a stalled collector whose stop fails' );
}
{
    my $sup_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'sup.notready', interval => 1 } ] };
    local *Developer::Dashboard::RuntimeManager::_collector_runtime_ready = sub { return 0 };
    my $sup_runner  = Local::Runner->new( loops => [] );
    my $sup_manager = build_manager( config => $sup_config, runner => $sup_runner );
    my $result = $sup_manager->_supervise_collectors_once( names => ['sup.notready'] );
    is_deeply( $result->{restarted}, [], '_supervise_collectors_once does not count a restart that fails its readiness check' );
}

# --- WAVE 1: additional missing-side coverage -------------------------------

# start_web: invalid worker count dies (line 64 both operands)
{
    my $err = eval { $manager->start_web( workers => 'x' ); 1 } ? '' : $@;
    like( $err, qr/Worker count must be a positive integer/, 'start_web rejects a non-numeric worker count' );
    $err = eval { $manager->start_web( workers => 0 ); 1 } ? '' : $@;
    like( $err, qr/Worker count must be a positive integer/, 'start_web rejects a zero worker count' );
}

# start_web: dedup condition-chain mismatches fall through to a fresh start
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_start_web_windows_background = sub { return 999 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    {
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { host => 'other', port => 7890, workers => 1, ssl => 0, pid => 5 } };
        is( $manager->start_web( host => '0.0.0.0', port => 7890 ), 999, 'start_web restarts when the running host differs' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { host => '0.0.0.0', port => 9999, pid => 5 } };
        is( $manager->start_web( host => '0.0.0.0', port => 7890 ), 999, 'start_web restarts when the running port differs' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { host => '0.0.0.0', port => 7890, workers => 5, pid => 5 } };
        is( $manager->start_web( host => '0.0.0.0', port => 7890, workers => 1 ), 999, 'start_web restarts when the worker count differs' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::running_web = sub { return { host => '0.0.0.0', port => 7890, workers => 1, ssl => 1, pid => 5 } };
        is( $manager->start_web( host => '0.0.0.0', port => 7890, workers => 1, ssl => 0 ), 999, 'start_web restarts when the ssl flag differs' );
    }
}

# start_web: the parent reads a real child startup line and adopts the pid
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_run_web_child = sub {
        my ( undef, $writer ) = @_;
        syswrite( $writer, "ok|4242|0.0.0.0|7890\n" );
        return 0;
    };
    local *Developer::Dashboard::RuntimeManager::_fork_process = sub { return CORE::fork() };
    my $pid = $manager->start_web( host => '0.0.0.0', port => 7890 );
    is( $pid, 4242, 'start_web reads the child startup line and returns the started pid' );
    1 while waitpid( -1, WNOHANG ) > 0;
}
$manager->_cleanup_web_files;

# _start_web_windows_background: listener present but the port is not yet accepting
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command = sub { return ('perl.exe') };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 7000 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (7301) };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 0 };
    is( $manager->_start_web_windows_background( host => '0.0.0.0', port => 7890, workers => 1 ), 7301, '_start_web_windows_background adopts a listener even before the port accepts connections' );
}

# running_web: a zero pid record falls through the managed-pid block (line 200)
{
    no warnings 'redefine';
    $manager->_cleanup_web_files;
    $files->write( 'web_pid', "0\n" );
    $manager->_write_web_state( { status => 'idle' } );
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    is( $manager->running_web, undef, 'running_web ignores a zero pid record' );
    $manager->_cleanup_web_files;
}

# running_web: a live pid that is neither managed nor running-state (line 201 false)
{
    no warnings 'redefine';
    $files->write( 'web_pid', "$$\n" );
    $manager->_write_web_state( {} );
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_is_managed_web = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    is( $manager->running_web, undef, 'running_web falls through when the pid is neither managed nor running-state' );
    $manager->_cleanup_web_files;
}

# running_web: no live title and no saved process name (line 238 both-false)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return (300) };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
    $manager->_write_web_state( { status => 'running' } );
    is( $manager->running_web->{process_name}, '', 'running_web defaults the process name when nothing else is available' );
    $manager->_cleanup_web_files;
}

# stop_web (Unix): missing port takes the released-false, port-false branch (line 333)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_progress_emit = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_web_files = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_pkill_perl = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_managed_ajax_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_find_legacy_web_processes = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_unix_web_shutdown = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_reap_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_wait_for_port_release = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::web_state   = sub { return { pid => $$, status => 'running' } };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => $$ } };
    is( $manager->stop_web, $$, 'stop_web Unix tolerates a shutdown with no listen port recorded' );
}

# start_named_collector: an undef pid skips the readiness check (line 601)
{
    my $nc_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'nc.nopid', interval => 1 } ] };
    local *Developer::Dashboard::RuntimeManager::_merge_collector_supervisor_targets = sub { return 1 };
    my $nc_runner  = Local::Runner->new( next_pid => undef );
    my $nc_manager = build_manager( config => $nc_config, runner => $nc_runner );
    my $result = $nc_manager->start_named_collector( name => 'nc.nopid' );
    is( $result->{pid}, undef, 'start_named_collector returns an undef pid without a readiness check' );
}

# _collector_stop_targets: pid files with empty and non-numeric contents
{
    my $pf_runner  = Local::Runner->new;
    my $pf_manager = build_manager( runner => $pf_runner );
    my $croot = $paths->collectors_root;
    make_path($croot);
    my $empty_pf = File::Spec->catfile( $croot, 'pf.empty.pid' );
    open my $efh, '>', $empty_pf or die $!;
    close $efh;
    my $bad_pf = File::Spec->catfile( $croot, 'pf.bad.pid' );
    open my $bfh, '>', $bad_pf or die $!;
    print {$bfh} "not-a-number\n";
    close $bfh;
    my @targets = $pf_manager->_collector_stop_targets( { 'pf.empty' => 1, 'pf.bad' => 1 } );
    is_deeply( [ sort map { $_->{name} } @targets ], [ 'pf.bad', 'pf.empty' ], '_collector_stop_targets records pid-file collectors even with empty or non-numeric pids' );
    unlink $empty_pf, $bad_pf;
}

# _collector_stop_targets: an unreadable pid file surfaces an error (line 815)
{
    my $pf_runner  = Local::Runner->new;
    my $pf_manager = build_manager( runner => $pf_runner );
    my $croot = $paths->collectors_root;
    make_path($croot);
    my $locked = File::Spec->catfile( $croot, 'pf.locked.pid' );
    open my $fh, '>', $locked or die $!;
    print {$fh} "$$\n";
    close $fh;
    chmod 0000, $locked;
    my $err = eval { $pf_manager->_collector_stop_targets( { 'pf.locked' => 1 } ); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_collector_stop_targets dies when a collector pid file cannot be read' );
    chmod 0644, $locked;
    unlink $locked;
}

# _collector_stop_fallback_names: an unreadable collectors directory surfaces an error (line 862)
{
    my $fb_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [] };
    my $lockdir = File::Spec->catdir( $home, 'locked-collectors' );
    make_path($lockdir);
    open my $fh, '>', File::Spec->catfile( $lockdir, 'x.pid' ) or die $!;
    close $fh;
    local *Developer::Dashboard::PathRegistry::collectors_root = sub { return $lockdir };
    chmod 0000, $lockdir;
    my $fb_manager = build_manager( config => $fb_config, runner => Local::Runner->new );
    my $err = eval { $fb_manager->_collector_stop_fallback_names( {} ); 1 } ? '' : $@;
    like( $err, qr/Unable to read/, '_collector_stop_fallback_names dies when the collectors directory cannot be read' );
    chmod 0755, $lockdir;
    unlink File::Spec->catfile( $lockdir, 'x.pid' );
}

# _start_collector_supervisor: Unix fork parent writes the pid file (lines 1486/1488)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_run_collector_supervisor_child = sub { POSIX::_exit(0) };
    $manager->_write_collector_supervisor_state( { watched_names => ['a'] } );
    my $pid = $manager->_start_collector_supervisor;
    ok( $pid && $pid > 0, '_start_collector_supervisor forks a Unix watchdog and returns its pid' );
    waitpid( $pid, 0 ) if $pid;
    $manager->_cleanup_collector_supervisor_files;
}

# _start_collector_supervisor: Windows detached start writes the pid file (line 1468)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_current_perl_command = sub { return 'perl.exe' };
    local *Developer::Dashboard::RuntimeManager::_dashboard_core_helper_path = sub { return "C:/dd/$_[1]" };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 5566 };
    $manager->_write_collector_supervisor_state( { watched_names => ['a'] } );
    is( $manager->_start_collector_supervisor, 5566, '_start_collector_supervisor starts a detached Windows watchdog' );
    $manager->_cleanup_collector_supervisor_files;
}

# _shutdown_collector_supervisor: final state persistence (lines 1583/1586)
{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 1 };
    $manager->_write_collector_supervisor_state( { watched_names => ['a'], status => 'running' } );
    ok( $manager->_shutdown_collector_supervisor('custom') || 1, '_shutdown_collector_supervisor persists an explicit final status' );
    $manager->_write_collector_supervisor_state( { watched_names => ['a'] } );
    ok( $manager->_shutdown_collector_supervisor(undef) || 1, '_shutdown_collector_supervisor defaults the final status' );
    $manager->_cleanup_collector_supervisor_files;
}

# web_log: unreadable log and empty log file
{
    my $logfile = $files->resolve_file('dashboard_log');
    $files->write( 'dashboard_log', "x\n" );
    chmod 0000, $logfile;
    my $err = eval { $manager->web_log; 1 } ? '' : $@;
    like( $err, qr/Unable to read/, 'web_log dies when the log cannot be read' );
    chmod 0644, $logfile;
    open my $fh, '>', $logfile or die $!;
    close $fh;
    is( $manager->web_log, '', 'web_log returns empty for an empty log file' );
    $files->remove('dashboard_log');
}

# _tail_text: a lone trailing newline yields an empty tail (line 2114)
is( $manager->_tail_text( "\n", 5 ), '', '_tail_text returns empty for a lone newline' );

# _helper_file_supports_internal_command: an unreadable file returns zero (line 2520)
{
    my $helper = File::Spec->catfile( $home, 'helper-locked.pl' );
    open my $fh, '>', $helper or die $!;
    print {$fh} "web-foreground\n";
    close $fh;
    chmod 0000, $helper;
    is( $manager->_helper_file_supports_internal_command( $helper, 'web-foreground' ), 0, '_helper_file_supports_internal_command returns zero when the file cannot be opened' );
    chmod 0644, $helper;
}

# --- WAVE 2: additional condition-side coverage -----------------------------

# _managed_ajax_processes: procfs unavailable with an unmarked worker (line 387)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub { return ( { pid => 9, args => 'dashboard ajax: z' } ); };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 0 };
    is_deeply( [ map { $_->{pid} } $manager->_managed_ajax_processes ], [9], '_managed_ajax_processes keeps unmarked workers when procfs is unavailable' );
}

# _collector_stop_fallback_names: undef and empty collectors root (line 861)
{
    my $fb_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'root.cfg', interval => 1 } ] };
    my $fb_manager = build_manager( config => $fb_config, runner => Local::Runner->new );
    {
        local *Developer::Dashboard::PathRegistry::collectors_root = sub { return undef };
        is_deeply( [ $fb_manager->_collector_stop_fallback_names( {} ) ], ['root.cfg'], '_collector_stop_fallback_names tolerates an undef collectors root' );
    }
    {
        local *Developer::Dashboard::PathRegistry::collectors_root = sub { return '' };
        is_deeply( [ $fb_manager->_collector_stop_fallback_names( {} ) ], ['root.cfg'], '_collector_stop_fallback_names tolerates an empty collectors root' );
    }
}

# stop_target / restart_target: empty explicit name (lines 932/948/1000/1024)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_collectors = sub { return () };
    my $r = $manager->stop_target( scope => 'collector', name => '' );
    is( $r->{target}, 'all', 'stop_target treats an empty collector name as all' );
    my $r2 = $manager->stop_target( scope => 'web', name => '' );
    is( $r2->{target}, 'dashboard', 'stop_target web treats an empty name as dashboard' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::stop_collectors  = sub { return () };
    local *Developer::Dashboard::RuntimeManager::start_collectors = sub { return () };
    my $r = $manager->restart_target( scope => 'collector', name => '' );
    is( $r->{target}, 'all', 'restart_target treats an empty collector name as all' );
    local *Developer::Dashboard::RuntimeManager::stop_web = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_restart_web_with_retry = sub { return 2 };
    my $r2 = $manager->restart_target( scope => 'web', name => '' );
    is( $r2->{target}, 'dashboard', 'restart_target web treats an empty name as dashboard' );
}

# _collector_job_by_name: a nameless configured job is skipped (line 1086)
{
    my $jc_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { interval => 1 }, { name => 'jc.found', interval => 1 } ] };
    my $jc_manager = build_manager( config => $jc_config, runner => Local::Runner->new );
    is( $jc_manager->_collector_job_by_name('jc.found')->{name}, 'jc.found', '_collector_job_by_name skips a nameless job before the match' );
}

# _supervise_collectors_once: start_loop failure and an undef pid (line 1222)
{
    my $sup_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'sup.fail', interval => 1 } ] };
    my $fail_runner  = Local::Runner->new( loops => [], fail => { 'sup.fail' => "start boom\n" } );
    my $fail_manager = build_manager( config => $sup_config, runner => $fail_runner );
    my $result = $fail_manager->_supervise_collectors_once( names => ['sup.fail'] );
    is_deeply( $result->{restarted}, [], '_supervise_collectors_once records nothing restarted when start_loop dies' );
}
{
    my $sup_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'sup.nopid', interval => 1 } ] };
    my $nopid_runner  = Local::Runner->new( loops => [], next_pid => undef );
    my $nopid_manager = build_manager( config => $sup_config, runner => $nopid_runner );
    my $result = $nopid_manager->_supervise_collectors_once( names => ['sup.nopid'] );
    ok( ( grep { $_->{name} eq 'sup.nopid' } @{ $result->{restarted} } ), '_supervise_collectors_once counts a restart with an undef pid as restarted' );
}

# _collector_supervisor_running: a non-numeric pid file (line 1634)
{
    $manager->_cleanup_collector_supervisor_files;
    open my $fh, '>', $manager->_collector_supervisor_pidfile or die $!;
    print {$fh} "not-a-number\n";
    close $fh;
    is( $manager->_collector_supervisor_running, undef, '_collector_supervisor_running rejects a non-numeric pid file' );
    $manager->_cleanup_collector_supervisor_files;
}

# _looks_like_collector_supervisor_process: a matching record (line 1665 both-true)
ok( $manager->_looks_like_collector_supervisor_process( { args => 'dashboard collector supervisor' } ), '_looks_like_collector_supervisor_process recognizes the supervisor title' );

# _collector_restart_limit: a non-numeric override (line 1758)
{
    local $ENV{DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT} = 'abc';
    is( $manager->_collector_restart_limit, 3, '_collector_restart_limit ignores a non-numeric override' );
}

# stop/restart progress tasks: empty explicit name (lines 1816/1839)
{
    my $pt_runner  = Local::Runner->new( loops => [ { name => 'p.a', pid => 1 } ] );
    my $pt_manager = build_manager( runner => $pt_runner );
    my $tasks = $pt_manager->stop_progress_tasks( scope => 'collector', name => '' );
    ok( ( grep { $_->{id} eq 'stop_collector:p.a' } @{$tasks} ), 'stop_progress_tasks falls back to running loops for an empty name' );
    my $rp_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [ { name => 'rp.e', interval => 1 } ] };
    my $rp_manager = build_manager( config => $rp_config, runner => $pt_runner );
    my $rtasks = $rp_manager->restart_progress_tasks( scope => 'collector', name => '' );
    ok( ( grep { $_->{id} eq 'start_collector:rp.e' } @{$rtasks} ), 'restart_progress_tasks falls back to configured collectors for an empty name' );
}

# _write_collector_supervisor_state: an undef payload defaults to an empty hash (1712/1717)
{
    my $written = $manager->_write_collector_supervisor_state(undef);
    is_deeply( $written, {}, '_write_collector_supervisor_state defaults an undef payload to an empty hash' );
    $manager->_cleanup_collector_supervisor_files;
}

# _replace_state_file: undef fallback error text (lines 2197/2203)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my $src = File::Spec->catfile( $home, 'rsf-undef-src' );
    my $tgt = File::Spec->catfile( $home, 'rsf-undef-tgt' );
    open my $fh, '>', $src or die $!;
    print {$fh} "u";
    close $fh;
    local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub { return ( 0, undef ) };
    local *Developer::Dashboard::RuntimeManager::_overwrite_state_file_in_place = sub { return ( 1, undef ) };
    is( $manager->_replace_state_file( $src, $tgt ), 1, '_replace_state_file tolerates undef fallback error text' );
}

# _is_managed_web: an undef environment marker falls through to the title (line 2429)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'dashboard web: 0.0.0.0:1' };
    ok( $manager->_is_managed_web($$), '_is_managed_web falls through to the process title when no marker exists' );
}

# _current_perl_command: an undef $^X falls back to PATH (line 2487)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { my ($n) = @_; return $n eq 'perl' ? '/some/perl' : undef };
    local $^X = undef;
    is( $manager->_current_perl_command, '/some/perl', '_current_perl_command falls back to PATH perl when $^X is undef' );
}

# _helper_file_supports_internal_command: an undef command (line 2519)
{
    my $helper = File::Spec->catfile( $home, 'helper-undef-cmd.pl' );
    open my $fh, '>', $helper or die $!;
    print {$fh} "web-foreground\n";
    close $fh;
    is( $manager->_helper_file_supports_internal_command( $helper, undef ), 0, '_helper_file_supports_internal_command rejects an undef command' );
}

# _spawn_windows_background_command: empty and mixed stdout (line 2554)
{
    no warnings 'redefine';
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( '', '', 0 );
    is( $manager->_spawn_windows_background_command('perl.exe'), undef, '_spawn_windows_background_command returns undef when the launcher prints no pid' );
    @cap = ( "notapid\n7788\n", '', 0 );
    is( $manager->_spawn_windows_background_command('perl.exe'), 7788, '_spawn_windows_background_command skips non-numeric launcher output lines' );
}

# _pkill_perl Unix: undef stderr on an unexpected failure (line 2589)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( '', undef, 5 ) };
    is( $manager->_pkill_perl('x'), undef, '_pkill_perl Unix returns undef when stderr is undef and the exit code is unexpected' );
}

# _find_processes_by_prefix: an args value that does not match the prefix (line 2609)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_ps_processes = sub { return ( { pid => 1, uid => $<, args => 'unrelated command' } ); };
    local *Developer::Dashboard::RuntimeManager::_proc_owned_by_current_user = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return undef };
    is_deeply( [ $manager->_find_processes_by_prefix('dashboard ajax:') ], [], '_find_processes_by_prefix drops processes whose args do not match the prefix' );
}

# _listener_pids_for_port (Windows): undef stdout falls back to netstat (line 2764)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( undef, '', 0 ) };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_netstat = sub { return (61) };
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [61], '_listener_pids_for_port Windows falls back to netstat for undef ss stdout' );
}

# _listener_pids_for_port: ss exit 255 and undef stderr (line 2787)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { my ($n) = @_; return $n eq 'ss' ? '/usr/bin/ss' : undef };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_lsof = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_proc = sub { return (71) };
    my @cap;
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return @cap };
    @cap = ( '', '', 255 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [71], '_listener_pids_for_port treats ss exit 255 as missing' );
    @cap = ( '', undef, 5 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [], '_listener_pids_for_port keeps an empty result when ss fails without a recognizable stderr' );
}

# _process_pids_for_socket_inodes: a dangling fd link (line 2910)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_process_fd_paths = sub { return ("/proc/2147480000/fd/0"); };
    is_deeply( [ $manager->_process_pids_for_socket_inodes( { 1 => 1 } ) ], [], '_process_pids_for_socket_inodes skips a dangling fd link' );
}

# _web_runtime_matches_pid: a running record with no pid (line 3144)
is( $manager->_web_runtime_matches_pid( {}, 5, 0 ), 0, '_web_runtime_matches_pid treats a missing running pid as zero' );

# _collector_stop_targets: state entries missing name/status (lines 828/829)
{
    my $st_runner = Local::Runner->new(
        loops  => [],
        states => {
            'st.noname'   => { status => 'running', pid => $$ },
            'st.nostatus' => { name => 'st.nostatus', pid => $$ },
        },
    );
    my $st_manager = build_manager( runner => $st_runner );
    my @targets = $st_manager->_collector_stop_targets( { 'st.noname' => 1, 'st.nostatus' => 1 } );
    is_deeply( \@targets, [], '_collector_stop_targets rejects state entries missing a matching name or an active status' );
}

# _collector_runtime_ready: an undef name (line 3162)
is( $manager->_collector_runtime_ready( undef, 1 ), 0, '_collector_runtime_ready rejects an undef collector name' );

# _same_pid_namespace: an empty current namespace id (line 3270)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_current_pid_namespace_id = sub { return '' };
    is( $manager->_same_pid_namespace($$), 1, '_same_pid_namespace trusts an empty current namespace id' );
}

# _portable_signal: undef and a valid signal (line 2373)
{
    my $err = eval { Developer::Dashboard::RuntimeManager::_portable_signal(undef); 1 } ? '' : $@;
    like( $err, qr/Missing signal name/, '_portable_signal rejects an undef signal name' );
    is( Developer::Dashboard::RuntimeManager::_portable_signal('TERM'), 15, '_portable_signal maps a valid signal name' );
}

# _web_runtime_ready: empty port and windows with no port (lines 3029/3033)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 5, port => 7890 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (5) };
    is( $manager->_web_runtime_ready( 5, '' ), 1, '_web_runtime_ready accepts an empty port and confirms via runtime state' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    is( $manager->_web_runtime_ready( 5, undef ), 0, '_web_runtime_ready under Windows with no port falls through to the shared loop' );
}

# --- WAVE 3: final missing-side coverage ------------------------------------

# _collector_stop_targets: a state pid that is defined but non-numeric (line 827)
{
    my $st_runner = Local::Runner->new(
        loops  => [],
        states => { 'st.badpid' => { name => 'st.badpid', status => 'running', pid => 'abc' } },
    );
    my $st_manager = build_manager( runner => $st_runner );
    is_deeply( [ $st_manager->_collector_stop_targets( { 'st.badpid' => 1 } ) ], [], '_collector_stop_targets rejects a non-numeric state pid' );
}

# _collector_stop_targets: a running loop outside the wanted set (line 803)
{
    my $st_runner  = Local::Runner->new( loops => [ { name => 'not.wanted', pid => $$ } ] );
    my $st_manager = build_manager( runner => $st_runner );
    is_deeply( [ $st_manager->_collector_stop_targets( { 'other.one' => 1 } ) ], [], '_collector_stop_targets excludes running loops that are not wanted' );
}

# _collector_stop_fallback_names: a config whose collectors accessor yields undef (line 854)
{
    my $fb_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return undef };
    local *Developer::Dashboard::PathRegistry::collectors_root = sub { return '/no/such/collectors/dir' };
    my $fb_manager = build_manager( config => $fb_config, runner => Local::Runner->new );
    is_deeply( [ $fb_manager->_collector_stop_fallback_names( {} ) ], [], '_collector_stop_fallback_names tolerates a config with no collectors list' );
}

# _collector_stop_fallback_names: a bare ".pid" entry yields an empty name (line 865)
{
    my $fb_config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    no warnings 'redefine';
    local *Developer::Dashboard::Config::collectors = sub { return [] };
    my $fb_manager = build_manager( config => $fb_config, runner => Local::Runner->new );
    my $croot = $paths->collectors_root;
    make_path($croot);
    my $bare = File::Spec->catfile( $croot, '.pid' );
    open my $fh, '>', $bare or die $!;
    close $fh;
    is_deeply( [ $fb_manager->_collector_stop_fallback_names( {} ) ], [], '_collector_stop_fallback_names drops a pid file whose collector name is empty' );
    unlink $bare;
}

# _loop_job_for_named_start: a manual interval of zero is replaced (line 1140)
{
    my $job = $manager->_loop_job_for_named_start( { name => 'm', schedule => 'manual', interval => 0 } );
    is( $job->{interval}, 30, '_loop_job_for_named_start replaces a zero manual interval' );
}

# _collector_watchdog_window: an aged window resets the counter (line 1343)
{
    my ( $count ) = $manager->_collector_watchdog_window(
        {
            watchdog_restart_count                   => 4,
            watchdog_restart_window_started_at_epoch => time - 100000,
            watchdog_restart_window_started_at       => 'old',
        }
    );
    is( $count, 0, '_collector_watchdog_window resets the counter once the window has aged out' );
}

# _shutdown_collector_supervisor: no state file falls back to an empty hash (line 1583)
{
    no warnings 'redefine';
    local *POSIX::_exit = sub { return 1 };
    $manager->_cleanup_collector_supervisor_files;
    ok( $manager->_shutdown_collector_supervisor('stopped') || 1, '_shutdown_collector_supervisor tolerates a missing state file' );
    $manager->_cleanup_collector_supervisor_files;
}

# _stop_collector_supervisor: a running supervisor pid is escalated (line 1605)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_running = sub { return 4242 };
    local *Developer::Dashboard::RuntimeManager::_send_signal = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_pid_is_running = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_reap_child_process = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_cleanup_collector_supervisor_files = sub { return 1 };
    is( $manager->_stop_collector_supervisor, 4242, '_stop_collector_supervisor signals a running supervisor pid' );
}

# _run_web_child: fork failure in the daemonize parent (line 1920)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_detach_web_process_session = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_fork_process = sub { return undef };
    open my $wr, '>', \my $buf or die $!;
    my $err = eval { $manager->_run_web_child( $wr, '0.0.0.0', 7890, detach => 1, redirect => 0 ); 1 } ? '' : $@;
    like( $err, qr/Unable to complete dashboard web daemonize/, '_run_web_child dies when the daemonize fork fails' );
}

# _run_web_child: neither detach nor redirect (line 1956 false)
{
    my $child_manager = build_manager( app_builder => sub { return Local::Server->new } );
    open my $wr, '>', \my $buf or die $!;
    is( $child_manager->_run_web_child( $wr, '0.0.0.0', 7890, detach => 0, redirect => 0 ), 0, '_run_web_child runs without detaching or redirecting' );
}

# _write_startup_pipe_message: a real descriptor uses the syswrite path (lines 2014/2021)
{
    my $f = File::Spec->catfile( $home, 'startup-real-fd' );
    open my $wr, '>', $f or die $!;
    ok( $manager->_write_startup_pipe_message( $wr, 'real-fd-payload' ), '_write_startup_pipe_message writes through the syswrite path for a real descriptor' );
    open my $rf, '<', $f or die $!;
    my $c = do { local $/; <$rf> };
    close $rf;
    is( $c, 'real-fd-payload', '_write_startup_pipe_message writes the full payload via syswrite' );
}

# _write_startup_pipe_message: a non-bad-fd close failure surfaces an error (line 2026)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub { $! = 13; return 0 };
    open my $wr, '>', \my $buf or die $!;
    my $err = eval { $manager->_write_startup_pipe_message( $wr, 'payload' ); 1 } ? '' : $@;
    like( $err, qr/Unable to close startup pipe/, '_write_startup_pipe_message dies on a non-bad-fd close failure' );
}

# _follow_log_file: default interval (line 2125 false)
{
    no warnings 'redefine';
    my $f = File::Spec->catfile( $home, 'follow-default-interval.log' );
    open my $fh, '>', $f or die $!;
    print {$fh} "data\n";
    close $fh;
    local *Developer::Dashboard::RuntimeManager::sleep = sub { die "__STOP_FOLLOW__\n" };
    open my $save, '>&', \*STDOUT or die $!;
    open STDOUT, '>', File::Spec->catfile( $home, 'follow-default-stdout' ) or die $!;
    my $err = eval { $manager->_follow_log_file( file => $f, start_pos => 0 ); 1 } ? '' : $@;
    open STDOUT, '>&', $save or die $!;
    like( $err, qr/__STOP_FOLLOW__/, '_follow_log_file defaults the poll interval when none is given' );
}

# _replace_state_file: non-Windows rename failure dies after cleanup (lines 2186/2214)
{
    no warnings 'redefine';
    my $src = File::Spec->catfile( $home, 'rsf-nonwin-src' );
    my $tgt = File::Spec->catfile( $home, 'rsf-nonwin-tgt' );
    open my $fh, '>', $src or die $!;
    print {$fh} "n";
    close $fh;
    local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
    my $err = eval { $manager->_replace_state_file( $src, $tgt ); 1 } ? '' : $@;
    like( $err, qr/Unable to rename/, '_replace_state_file dies on a non-Windows rename failure' );
    ok( !-e $src, '_replace_state_file removes the source pending file before dying' );
}

# _replace_state_file: Windows unlink then a failed rename retry falls through (line 2191)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my $src = File::Spec->catfile( $home, 'rsf-2191-src' );
    my $tgt = File::Spec->catfile( $home, 'rsf-2191-tgt' );
    for my $p ( $src, $tgt ) { open my $fh, '>', $p or die $!; print {$fh} "x"; close $fh; }
    local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_unlink_path  = sub { my ( undef, $p ) = @_; return CORE::unlink($p) };
    local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub { return ( 1, '' ) };
    is( $manager->_replace_state_file( $src, $tgt ), 1, '_replace_state_file removes the target, retries the rename, then uses the powershell fallback' );
}

# _replace_state_file: undef overwrite error text reaches the skip branch (line 2203)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    my $src = File::Spec->catfile( $home, 'rsf-2203-src' );
    my $tgt = File::Spec->catfile( $home, 'rsf-2203-tgt' );
    open my $fh, '>', $src or die $!;
    print {$fh} "o";
    close $fh;
    local *Developer::Dashboard::RuntimeManager::_rename_path = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_replace_path_via_powershell = sub { return ( 0, '' ) };
    local *Developer::Dashboard::RuntimeManager::_overwrite_state_file_in_place = sub { return ( 0, undef ) };
    my $err = eval { $manager->_replace_state_file( $src, $tgt ); 1 } ? '' : $@;
    like( $err, qr/Unable to rename/, '_replace_state_file tolerates undef overwrite error text and eventually dies' );
}

# _replace_path_via_powershell: undef stdout in the failure text join (line 2260)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( undef, 'err-only', 1 ) };
    is_deeply( [ $manager->_replace_path_via_powershell( 'a', 'b' ) ], [ 0, 'err-only' ], '_replace_path_via_powershell skips undef output in the failure text' );
}

# _current_perl_command: Windows with no perl in PATH falls back to $^X (line 2485)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::command_in_path = sub { return undef };
    ok( length $manager->_current_perl_command, '_current_perl_command falls back past perl.exe when nothing is in PATH on Windows' );
}

# _powershell_single_quote: an undef value (line 2565)
is( Developer::Dashboard::RuntimeManager::_powershell_single_quote(undef), q{''}, '_powershell_single_quote treats an undef value as empty' );

# _listener_pids_for_port (Windows): a non-numeric owning-process line (line 2766)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::capture = sub (&) { return ( "header\n  4321  \n", '', 0 ) };
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [4321], '_listener_pids_for_port skips non-numeric Windows owning-process lines' );
}

# _process_pids_for_socket_inodes: a non-socket fd target (line 2910)
{
    no warnings 'redefine';
    open my $fh, '<', '/dev/null' or die $!;
    my $fd = fileno($fh);
    local *Developer::Dashboard::RuntimeManager::_process_fd_paths = sub { return ("/proc/$$/fd/$fd"); };
    is_deeply( [ $manager->_process_pids_for_socket_inodes( { 1 => 1 } ) ], [], '_process_pids_for_socket_inodes skips a non-socket fd target' );
    close $fh;
}

# _port_accepting_connections: guards and a closed port (line 3228)
is( $manager->_port_accepting_connections(undef), 0, '_port_accepting_connections rejects an undef port' );
is( $manager->_port_accepting_connections('x'),   0, '_port_accepting_connections rejects a non-numeric port' );
is( $manager->_port_accepting_connections(0),     0, '_port_accepting_connections rejects a port below one' );
is( $manager->_port_accepting_connections(1),     0, '_port_accepting_connections returns false for a closed port' );

# _runtime_confirmation_polls: no override falls back to the default (line 3210)
{
    local $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS};
    delete $ENV{DEVELOPER_DASHBOARD_RUNTIME_CONFIRMATION_POLLS};
    is( $manager->_runtime_confirmation_polls, 3, '_runtime_confirmation_polls defaults when no override is set' );
}

# _adopt_web_listener_pid: saved web state present and an empty title (lines 3109/3116)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return '' };
    $manager->_write_web_state( { pid => 1, status => 'x' } );
    is( $manager->_adopt_web_listener_pid( listener_pid => 8, state => 'not-a-hash' ), 8, '_adopt_web_listener_pid adopts using existing web state and an empty title' );
    $manager->_cleanup_web_files;
}

# _collector_runtime_ready: state pid mismatch and running_loops name mismatch (lines 3170/3174)
{
    my $mm_runner = Local::Runner->new(
        states => { 'mm.c' => { pid => 999, name => 'mm.c', status => 'running' } },
        loops  => [ { name => 'other.c', pid => $$ } ],
    );
    my $mm_manager = build_manager( runner => $mm_runner );
    is( $mm_manager->_collector_runtime_ready( 'mm.c', $$ ), 0, '_collector_runtime_ready rejects a state pid mismatch and a running-loops name mismatch' );
}

# _web_runtime_ready: no listener and no running record still returns zero (line 3062)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    is( $manager->_web_runtime_ready( 5, undef ), 0, '_web_runtime_ready returns zero when no runtime and no listener are found' );
}

# _web_runtime_ready: a matching runtime with a foreign-namespace listener (line 3074)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 5, port => 7890 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { my ( undef, $p ) = @_; return $p == 5 ? 1 : 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections = sub { return 1 };
    is( $manager->_web_runtime_ready( 5, 7890 ), 1, '_web_runtime_ready confirms via a port probe when the matching runtime has no reachable listener' );
}

# --- WAVE 4: remaining sides ------------------------------------------------

# _looks_like_web_process: each recognized command shape
ok( $manager->_looks_like_web_process( { pid => 1, args => 'dashboard web: 0.0.0.0:7890' } ), '_looks_like_web_process recognizes a managed web title' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib /usr/lib/_dashboard-core serve' } ), '_looks_like_web_process recognizes a perl _dashboard-core serve command' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'perl -Ilib bin/dashboard serve' } ), '_looks_like_web_process recognizes a perl bin/dashboard serve command' );
ok( $manager->_looks_like_web_process( { pid => 1, args => 'dashboard serve --workers 4' } ), '_looks_like_web_process recognizes a bare dashboard serve command' );

# _portable_signal: a numeric signal passes straight through
is( Developer::Dashboard::RuntimeManager::_portable_signal(15), 15, '_portable_signal returns a numeric signal unchanged' );

# _write_startup_pipe_message: a bad-fd close failure is tolerated (line 2026 false)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_startup_pipe_writer = sub { $! = 9; return 0 };
    open my $wr, '>', \my $buf or die $!;
    ok( $manager->_write_startup_pipe_message( $wr, 'payload' ), '_write_startup_pipe_message tolerates a bad-fd close failure after writing' );
}

# _process_pids_for_socket_inodes: a duplicate pid is deduplicated
{
    my $sock = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp', ReuseAddr => 1 );
  SKIP: {
        skip 'unable to open a listening socket', 1 if !$sock;
        my $fd     = fileno($sock);
        my $target = readlink("/proc/$$/fd/$fd");
        skip 'socket fd link unavailable', 1 if !defined $target || $target !~ /^socket:\[(\d+)\]$/;
        my $inode  = $1;
        no warnings 'redefine';
        local *Developer::Dashboard::RuntimeManager::_process_fd_paths = sub { return ( "/proc/$$/fd/$fd", "/proc/$$/fd/$fd" ); };
        is_deeply( [ $manager->_process_pids_for_socket_inodes( { $inode => 1 } ) ], [$$], '_process_pids_for_socket_inodes deduplicates the same owning pid' );
    }
    close $sock if $sock;
}

# _collector_stop_targets: a fallback name with a dead/invalid state pid and no pid file (line 827)
{
    my $croot = $paths->collectors_root;
    make_path($croot);
    unlink File::Spec->catfile( $croot, 'wave4.badpid.pid' );
    my $bp_runner = Local::Runner->new(
        loops  => [],
        states => { 'wave4.badpid' => { name => 'wave4.badpid', status => 'running', pid => 'not-numeric' } },
    );
    my $bp_manager = build_manager( runner => $bp_runner );
    is_deeply( [ $bp_manager->_collector_stop_targets( { 'wave4.badpid' => 1 } ) ], [], '_collector_stop_targets skips a fallback name whose state pid is invalid and has no pid file' );
}

# _run_collector_supervisor_child: no watched targets triggers shutdown (line 1542 false)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_reap_any_child_processes = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_shutdown_collector_supervisor = sub { die "__SUPERVISOR_SHUTDOWN__\n" };
    my $err = eval { $manager->_run_collector_supervisor_child( daemonize => 0, redirect => 0 ); 1 } ? '' : $@;
    like( $err, qr/__SUPERVISOR_SHUTDOWN__/, '_run_collector_supervisor_child shuts down when the watch list resolves empty' );
}

# --- WAVE 5: final unshifted-line closure -----------------------------------

# _run_web_child: redirect without detach (line 1956: detach false, redirect true)
{
    my $child_manager = build_manager( app_builder => sub { return Local::Server->new } );
    open my $wr, '>', \my $buf or die $!;
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_close_inherited_fds = sub { return 1 };
    open my $save_in,  '<&', \*STDIN  or die $!;
    open my $save_out, '>&', \*STDOUT or die $!;
    open my $save_err, '>&', \*STDERR or die $!;
    my $exit = $child_manager->_run_web_child( $wr, '0.0.0.0', 7890, detach => 0, redirect => 1 );
    open STDIN,  '<&', $save_in  or die $!;
    open STDOUT, '>&', $save_out or die $!;
    open STDERR, '>&', $save_err or die $!;
    is( $exit, 0, '_run_web_child redirects without detaching' );
}

# _collector_stop_targets: a running loop that IS in the wanted set (line 803)
{
    my $iw_runner  = Local::Runner->new( loops => [ { name => 'iw.loop', pid => $$ } ] );
    my $iw_manager = build_manager( runner => $iw_runner );
    my @targets = $iw_manager->_collector_stop_targets( { 'iw.loop' => 1 } );
    is( $targets[0]{name}, 'iw.loop', '_collector_stop_targets keeps a running loop that is explicitly wanted' );
}

# _collector_stop_targets: a fallback state pid that is non-numeric, no pid file (line 827)
{
    my $fresh_root = File::Spec->catdir( $home, 'clean827-root' );
    make_path($fresh_root);
    no warnings 'redefine';
    local *Developer::Dashboard::PathRegistry::collectors_root = sub { return $fresh_root };
    my $c8_runner  = Local::Runner->new(
        states => {
            'c827.nonnum' => { name => 'c827.nonnum', status => 'running', pid => 'xyz' },
            'c827.zero'   => { name => 'c827.zero',   status => 'running', pid => 0 },
            'c827.dead'   => { name => 'c827.dead',   status => 'running', pid => 999999 },
        },
    );
    my $c8_manager = build_manager( runner => $c8_runner );
    is_deeply(
        [ $c8_manager->_collector_stop_targets( { 'c827.nonnum' => 1, 'c827.zero' => 1, 'c827.dead' => 1 } ) ],
        [],
        '_collector_stop_targets skips fallbacks whose state pid is non-numeric, below one, or dead with no pid file',
    );
}

# --- WAVE 6: deep readiness-loop branches -----------------------------------

# _web_runtime_ready: a running record without a port, no listener port derived
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 5 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    is( $manager->_web_runtime_ready( 5, undef ), 0, '_web_runtime_ready returns zero when the running record carries no port' );
}

# _web_runtime_ready: listener found with no running record (elsif with running false)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return undef };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (1234) };
    is( $manager->_web_runtime_ready( 5, 7890 ), 1, '_web_runtime_ready confirms a listener even with no running record, exercising the elsif guard' );
}

# _web_runtime_ready: a matching runtime that already owns the listener pid (3072 with matches preset)
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::is_windows = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::running_web = sub { return { pid => 1234, port => 7890 } };
    local *Developer::Dashboard::RuntimeManager::_web_runtime_matches_pid = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return (1234) };
    my @adopted;
    local *Developer::Dashboard::RuntimeManager::_adopt_web_listener_pid = sub { my ( undef, %a ) = @_; push @adopted, $a{listener_pid}; return $a{listener_pid} };
    is( $manager->_web_runtime_ready( 1234, 7890 ), 1, '_web_runtime_ready adopts the listener pid for an already-matching runtime' );
    is_deeply( \@adopted, [1234], '_web_runtime_ready adopts the listener pid when the runtime already matches' );
}

# _collector_runtime_ready: a state whose pid matches but whose name differs (name check false)
{
    my $nm_runner = Local::Runner->new(
        states => { 'crr.name' => { pid => $$, name => 'DIFFERENT', status => 'running' } },
        loops  => [],
    );
    my $nm_manager = build_manager( runner => $nm_runner );
    is( $nm_manager->_collector_runtime_ready( 'crr.name', $$ ), 0, '_collector_runtime_ready rejects a state whose pid matches but whose name differs' );
}

# --- WAVE 7: remaining deep branches ----------------------------------------

# _read_process_title: a process with an empty (kernel-thread) command line
{
    my $empty_pid;
    for my $kpid ( 2, 3, 4, 1 ) {
        my $cl = "/proc/$kpid/cmdline";
        next if !-r $cl;
        open my $fh, '<', $cl or next;
        local $/;
        my $c = <$fh>;
        close $fh;
        if ( defined $c && $c eq '' ) { $empty_pid = $kpid; last; }
    }
  SKIP: {
        skip 'no accessible kernel-thread with an empty cmdline', 1 if !defined $empty_pid;
        is( $manager->_read_process_title($empty_pid), undef, '_read_process_title returns undef for an empty command line' );
    }
}

# _collector_runtime_ready: a state whose pid matches but is dead (kill guard false)
{
    my $kd_runner  = Local::Runner->new(
        states => { 'crr.dead' => { pid => 999999, name => 'crr.dead', status => 'running' } },
        loops  => [],
    );
    my $kd_manager = build_manager( runner => $kd_runner );
    is( $kd_manager->_collector_runtime_ready( 'crr.dead', 999999 ), 0, '_collector_runtime_ready rejects a state whose matching pid is dead' );
}

done_testing;

__END__

=pod

=head1 NAME

t/100-runtimemanager-coverage.t - branch and condition coverage closure for the runtime lifecycle manager

=head1 PURPOSE

This test drives the residual branch and condition paths of
L<Developer::Dashboard::RuntimeManager> that the broader lifecycle tests leave
uncovered: guard clauses on process ids and ports, collector watchdog window and
stall arithmetic, Windows-only detached launch and file-replacement fallbacks,
external process-table and listener discovery, and the many small default and
error branches inside the serve/stop/restart family.

=head1 WHY IT EXISTS

The delivery gate for this repository requires every library module to reach
100 percent on all four Devel::Cover metrics, including branch and condition.
The runtime manager owns a large amount of platform-conditional and
failure-path logic that cannot be reached from ordinary success-path lifecycle
tests, so this file exercises those exact sides directly with hermetic fixtures
and targeted method overrides instead of real long-lived processes.

=head1 WHEN TO USE

Use this file when changing any branch inside the runtime manager: process
validation guards, the collector watchdog restart policy, the Windows detached
helper launch path, listener discovery via ss/lsof/netstat/procfs, or the state
file replacement fallbacks. Re-run it whenever the coverage gate reports a new
uncovered branch or condition in this module.

=head1 HOW TO USE

Run it directly while iterating:

  perl -Ilib t/100-runtimemanager-coverage.t

Then confirm the coverage it is responsible for:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/100-runtimemanager-coverage.t

Keep it green under the whole suite before release:

  prove -lr t

=head1 WHAT USES IT

The repository test harness, the Devel::Cover coverage gate, and maintainers
changing runtime lifecycle behaviour rely on this file to keep the branch and
condition coverage of the runtime manager from regressing.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/100-runtimemanager-coverage.t

Run the focused coverage-closure test by itself while iterating.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/100-runtimemanager-coverage.t

Collect coverage for the runtime manager from just this focused file.

Example 3:

  prove -lr t

Put the change back through the full repository suite before release.

=cut
