#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use POSIX ();
use Test::More;

use lib 'lib';

use Developer::Dashboard::Config;
use Developer::Dashboard::Collector;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;

BEGIN {
    no warnings 'redefine';
    # Make every internal poll loop instant and hermetic.
    *Developer::Dashboard::RuntimeManager::sleep = sub (;@) { return 0 };
}

my $RM = 'Developer::Dashboard::RuntimeManager';

# A minimal collector runner: none of the target methods drive real loops.
{
    package Local::Runner;
    sub new           { return bless {}, shift }
    sub running_loops { return () }
    sub start_loop    { return 4242 }
    sub stop_loop     { return 1 }
}

my $original_cwd = getcwd();
my $test_cwd     = tempdir( CLEANUP => 1 );
chdir $test_cwd or die "Unable to chdir to $test_cwd: $!";

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $runner = Local::Runner->new;

my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { return bless {}, 'Local::Server' },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);

# Ensure the runtime state root exists so we can plant supervisor pid files.
make_path( $paths->state_root ) if !-d $paths->state_root;

# ---------------------------------------------------------------------------
# Environment-driven tuning knobs: exercise every condition cell of the
# "defined $value && $value =~ /re/ && $value > 0" guards (source lines
# 1758, 1769, 1781, 3193) plus the fractional interval guard (line 1792).
# ---------------------------------------------------------------------------
my @env_int_cases = (
    [ '_collector_restart_limit',          'DEVELOPER_DASHBOARD_COLLECTOR_RESTART_LIMIT',           3 ],
    [ '_collector_restart_window_seconds', 'DEVELOPER_DASHBOARD_COLLECTOR_RESTART_WINDOW_SECONDS', 300 ],
    [ '_collector_stall_grace_seconds',    'DEVELOPER_DASHBOARD_COLLECTOR_STALL_GRACE_SECONDS',     10 ],
    [ '_runtime_stability_polls',          'DEVELOPER_DASHBOARD_RUNTIME_STABILITY_POLLS',          300 ],
);
for my $case (@env_int_cases) {
    my ( $method, $var, $default ) = @{$case};
    {
        delete local $ENV{$var};
        is( $manager->$method, $default, "$method falls back to its default when the override is unset" );
    }
    {
        local $ENV{$var} = 'abc';
        is( $manager->$method, $default, "$method ignores a non-numeric override" );
    }
    {
        local $ENV{$var} = '0';
        is( $manager->$method, $default, "$method ignores a zero override" );
    }
    {
        local $ENV{$var} = '7';
        is( $manager->$method, 7, "$method honors a positive integer override" );
    }
}

{
    my $var = 'DEVELOPER_DASHBOARD_COLLECTOR_SUPERVISOR_POLL_INTERVAL';
    {
        delete local $ENV{$var};
        is( $manager->_collector_supervisor_poll_interval, 5, 'poll interval default when the override is unset' );
    }
    {
        local $ENV{$var} = 'abc';
        is( $manager->_collector_supervisor_poll_interval, 5, 'poll interval ignores a non-numeric override' );
    }
    {
        local $ENV{$var} = '0';
        is( $manager->_collector_supervisor_poll_interval, 5, 'poll interval ignores a zero override' );
    }
    {
        local $ENV{$var} = '2.5';
        is( $manager->_collector_supervisor_poll_interval, 2.5, 'poll interval honors a fractional override' );
    }
}

# ---------------------------------------------------------------------------
# _managed_ajax_processes: drive every runtime-root / env-marker / procfs
# combination so both condition nodes of source lines 386 and 387 are hit,
# including the previously-missing "runtime root is empty" arms.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my ( @procs, %markers, $procfs, $state_root );
    local *Developer::Dashboard::RuntimeManager::_find_processes_by_prefix = sub { return @procs };
    local *Developer::Dashboard::RuntimeManager::_read_process_env_marker  = sub {
        my ( $self, $pid, $key ) = @_;
        return exists $markers{$pid} ? $markers{$pid} : undef;
    };
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return $procfs };
    local *Developer::Dashboard::PathRegistry::state_root          = sub { return $state_root };

    # Runtime root is non-empty: marker matches the root (kept), empty marker
    # and undef markers belonging to another root are skipped.
    $state_root = '/root';
    $procfs     = 1;
    @procs      = (
        { pid => 101, args => 'dashboard ajax: a' },
        { pid => 102, args => 'dashboard ajax: b' },
        { pid => 103, args => 'dashboard ajax: c' },
        { pid => 104, args => 'dashboard ajax: d' },
    );
    %markers = ( 101 => '', 103 => '/root', 104 => 'other' );
    is_deeply(
        [ map { $_->{pid} } $manager->_managed_ajax_processes ],
        [103],
        '_managed_ajax_processes keeps only the marker that matches the active runtime root'
    );

    # Runtime root is empty: the empty-marker and undef-marker arms fall
    # through to the keep path (covers the l&&!r cells of lines 386 and 387).
    $state_root = '';
    $procfs     = 1;
    @procs      = (
        { pid => 101, args => 'dashboard ajax: a' },
        { pid => 102, args => 'dashboard ajax: b' },
    );
    %markers = ( 101 => '' );
    is_deeply(
        [ sort { $a <=> $b } map { $_->{pid} } $manager->_managed_ajax_processes ],
        [ 101, 102 ],
        '_managed_ajax_processes keeps every ajax worker when the runtime root is empty'
    );

    # procfs unavailable with an undef marker: the middle term of line 387 is
    # false, so the process is kept regardless of runtime root.
    $state_root = '/root';
    $procfs     = 0;
    @procs      = ( { pid => 102, args => 'dashboard ajax: b' } );
    %markers    = ();
    is_deeply(
        [ map { $_->{pid} } $manager->_managed_ajax_processes ],
        [102],
        '_managed_ajax_processes keeps markerless workers when procfs is unavailable'
    );
}

# ---------------------------------------------------------------------------
# _collector_supervisor_running: exercise every short-circuit stage of the
# five-term guard on source line 1634, including the previously-missing
# "alive but a different pid namespace" arm.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my ( $ns, $super ) = ( 1, 1 );
    local *Developer::Dashboard::RuntimeManager::_same_pid_namespace   = sub { return $ns };
    local *Developer::Dashboard::RuntimeManager::_is_collector_supervisor = sub { return $super };

    my $pidfile = $manager->_collector_supervisor_pidfile;
    my $plant   = sub {
        my ($content) = @_;
        open my $fh, '>', $pidfile or die "Unable to write $pidfile: $!";
        print {$fh} $content;
        close $fh;
    };

    $plant->('');
    is( $manager->_collector_supervisor_running, undef, 'supervisor running: empty pid file yields undef' );

    $plant->('abc');
    is( $manager->_collector_supervisor_running, undef, 'supervisor running: non-numeric pid yields undef' );

    $plant->('999999');
    is( $manager->_collector_supervisor_running, undef, 'supervisor running: dead numeric pid yields undef' );

    $ns = 0;
    $plant->("$$");
    is( $manager->_collector_supervisor_running, undef, 'supervisor running: live pid in another namespace yields undef' );

    $ns    = 1;
    $super = 0;
    $plant->("$$");
    is( $manager->_collector_supervisor_running, undef, 'supervisor running: live same-namespace non-supervisor yields undef' );

    $super = 1;
    $plant->("$$");
    is( $manager->_collector_supervisor_running, $$ + 0, 'supervisor running: live managed supervisor pid is returned' );

    $manager->_cleanup_collector_supervisor_files;
}

# ---------------------------------------------------------------------------
# _merge_collector_supervisor_targets: cover the "$names || []" branch on
# source line 1405 for both a truthy and a falsy names argument, and for both
# an empty and a populated persisted watch set.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $sup_state = {};
    local *Developer::Dashboard::RuntimeManager::_collector_supervisor_state = sub { return $sup_state };
    local *Developer::Dashboard::RuntimeManager::_set_collector_supervisor_targets = sub {
        my ( $self, $targets ) = @_;
        return scalar @{ $targets || [] };
    };

    $sup_state = {};
    is( $manager->_merge_collector_supervisor_targets( ['alpha'] ), 1, 'merge with a truthy names list and an empty watch set' );
    is( $manager->_merge_collector_supervisor_targets(undef),       0, 'merge with an undef names list defaults to an empty list' );

    $sup_state = { watched_names => ['xray'] };
    is( $manager->_merge_collector_supervisor_targets( ['bravo'] ), 2, 'merge unions a truthy names list with the persisted watch set' );
}

# ---------------------------------------------------------------------------
# _start_web_windows_background: reach the state-assembly block (source line
# 176) with a discovered, accepting listener under a forced Windows profile.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_windows_background_web_command  = sub { return ('serve') };
    local *Developer::Dashboard::RuntimeManager::_spawn_windows_background_command = sub { return 4242 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port          = sub { return (4321) };
    local *Developer::Dashboard::RuntimeManager::_port_accepting_connections      = sub { return 1 };

    my $pid = $manager->_start_web_windows_background(
        host    => '0.0.0.0',
        port    => 7890,
        workers => 1,
        ssl     => 0,
    );
    is( $pid, 4321, '_start_web_windows_background returns the confirmed listener pid' );
    $manager->_cleanup_web_files;
}

# ---------------------------------------------------------------------------
# _listener_pids_for_port (Windows PowerShell path): cover both condition
# nodes of source line 2763, including the empty-stdout arm.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my @cap;
    local *Developer::Dashboard::RuntimeManager::is_windows                        = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port_via_netstat = sub { return () };
    local *Developer::Dashboard::RuntimeManager::capture                           = sub (&) { return @cap };

    @cap = ( '', '', 1 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [], 'windows listener lookup: non-zero exit falls back' );

    @cap = ( undef, '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [], 'windows listener lookup: undef stdout falls back' );

    @cap = ( '', '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [], 'windows listener lookup: empty stdout falls back' );

    @cap = ( "123\n456\n123\n", '', 0 );
    is_deeply( [ $manager->_listener_pids_for_port(7890) ], [ 123, 456 ], 'windows listener lookup: parses and de-duplicates pids' );
}

# ---------------------------------------------------------------------------
# _read_process_state: cover both arms of the /proc stat regex on source line
# 3332 by feeding a real stat line and a defined-but-empty read.
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    my $slurp;
    local *Developer::Dashboard::RuntimeManager::_procfs_available = sub { return 1 };
    local *Developer::Dashboard::RuntimeManager::_slurp_proc_file  = sub { return $slurp };

    $slurp = '4242 (perl) S 1 4242 4242 0';
    is( $manager->_read_process_state(4242), 'S', '_read_process_state extracts the state letter from a real stat line' );

    $slurp = '';
    is( $manager->_read_process_state(4242), undef, '_read_process_state returns undef when the stat line does not match' );

    $slurp = undef;
    is( $manager->_read_process_state(4242), undef, '_read_process_state returns undef when the stat file is unreadable' );
}

# ---------------------------------------------------------------------------
# _read_process_env_marker: cover both arms of the KEY=VALUE split guard on
# source line 3251. Our own environ supplies well-formed pairs; a child whose
# process title has overwritten its environ region supplies the malformed
# pairs that make the skip branch fire.
# ---------------------------------------------------------------------------
{
    # /proc/self/environ reflects the environ captured at process start, so we
    # assert a well-formed pair was parsed rather than the value of a variable
    # mutated after startup.
    my $home_value = $manager->_read_process_env_marker( $$, 'HOME' );
    ok( defined $home_value && $home_value ne '', '_read_process_env_marker reads a well-formed KEY=VALUE pair from the current process' );
    is( $manager->_read_process_env_marker( $$, 'DD_ABSENT_KEY_XYZ' ), undef, '_read_process_env_marker returns undef for an absent key' );

    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $0 = 'dashboard collector coverage worker ' . ( 'z' x 512 );
        select undef, undef, undef, 5;
        POSIX::_exit(0);
    }

    my $environ = "/proc/$child/environ";
    my $ready   = 0;
    for ( 1 .. 200 ) {
        if ( -r $environ ) { $ready = 1; last }
        select undef, undef, undef, 0.02;
    }
    SKIP: {
        skip 'child /proc environ not readable on this host', 1 if !$ready;
        my $marker = $manager->_read_process_env_marker( $child, 'DD_ABSENT_KEY_XYZ' );
        is( $marker, undef, '_read_process_env_marker skips malformed environ entries and returns undef' );
    }
    kill 'KILL', $child;
    waitpid $child, 0;
}

chdir $original_cwd or die "Unable to restore cwd: $!";

done_testing;

__END__

=pod

=head1 NAME

t/106-runtimemanager-coverage-2.t - branch and condition closure for the runtime lifecycle manager

=head1 PURPOSE

This test drives the residual branch and condition arms of
C<Developer::Dashboard::RuntimeManager> that the rest of the suite never
reaches: the empty-runtime-root arms of the managed Ajax worker filter, the
alive-but-foreign-namespace arm of the collector supervisor discovery guard,
the environment-tuning fallbacks, the Windows PowerShell listener parser, the
process-state and process-environ readers, and the Windows background
state-assembly path. It exists so those arms are exercised by a real,
observable behavior rather than an annotation.

=head1 WHY IT EXISTS

The all-metric coverage gate requires C<lib/> to report 100.0 on statement,
subroutine, branch, AND condition. The runtime manager accumulated a handful of
short-circuit arms and environ/stat edge cases that only occur against live
process trees or Windows hosts, so ordinary functional tests left them dark.
Two of those arms were previously masked with C<# uncoverable> annotations even
though real dashboard processes (whose C<$0> rewrite scrambles their environ,
and whose stat reads can come back empty) genuinely reach them; this test
replaces those annotations with executed coverage.

=head1 WHEN TO USE

Use this file when changing runtime lifecycle discovery, the collector
watchdog supervisor, the managed Ajax worker filter, the process
inspection helpers, or the Windows web-service background launch path.

=head1 HOW TO USE

Run C<prove -lv t/106-runtimemanager-coverage-2.t> while iterating on the
runtime manager. Keep it green under C<prove -lr t>, and confirm the runtime
manager still reports 100.0 on every Devel::Cover metric before release.

=head1 WHAT USES IT

Developers during TDD, the repository test suite, and the coverage gate use
this file to keep the runtime manager's process-lifecycle edge cases exercised.

=head1 EXAMPLES

Example 1:

  prove -lv t/106-runtimemanager-coverage-2.t

Run the dedicated runtime-manager branch/condition closure check by itself.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
