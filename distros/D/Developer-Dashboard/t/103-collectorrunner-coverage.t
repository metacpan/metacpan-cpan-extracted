#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use Test::More;

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::InternalCLI ();
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;

# ---------------------------------------------------------------------------
# Hermetic runtime rooted in a throwaway HOME. The config root resolves from
# the deepest .developer-dashboard layer discovered from the CWD, so we must
# chdir into the temp home before building any object.
# ---------------------------------------------------------------------------
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'workspace' ) ],
);
my $files           = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $collector_store = Developer::Dashboard::Collector->new( paths => $paths );
my $indicator_store = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner          = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector_store,
    files      => $files,
    indicators => $indicator_store,
    paths      => $paths,
);

my $PKG = 'Developer::Dashboard::CollectorRunner';

# write_raw_state: force a specific loop.json payload for a collector so the
# lifecycle readers see crafted state fields the normal writer would never
# emit (missing pid/name/process_name/status, non-hash JSON, etc.).
sub write_raw_state {
    my ( $name, $json ) = @_;
    my $file = File::Spec->catfile( $paths->collector_dir($name), 'loop.json' );
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $json;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

# ===========================================================================
# run_once: cwd resolution, indicator materialization exit-code handling.
# ===========================================================================

# L52 cwd fallback: a job without cwd falls through to cwd().
{
    my $result = $runner->run_once( { name => 'nocwd.collector', command => q{printf ok} } );
    is( $result->{exit_code}, 0, 'run_once defaults cwd to the process cwd when the job omits cwd' );
}

# L53 middle condition: a relative cwd that is not a path-registry method dies
# on the "does not exist" guard before any work happens.
{
    my $err = eval { $runner->run_once( { name => 'relcwd.collector', command => q{printf ok}, cwd => 'relative-not-a-method' } ); 1 } ? '' : $@;
    like( $err, qr/does not exist/, 'run_once rejects a relative cwd that is neither absolute nor a path-registry accessor' );
}

# L89 schedule: an explicit schedule value is used verbatim by mark_run_started.
{
    my $result = $runner->run_once( { name => 'sched.collector', command => q{printf ok}, cwd => $home, schedule => 'interval' } );
    is( $result->{exit_code}, 0, 'run_once accepts an explicit schedule on the job' );
    is( $collector_store->read_status('sched.collector')->{schedule}, 'interval', 'run_once records the explicit schedule verbatim' );
}

# L124 false side: a failing command whose indicator template also fails keeps
# the non-zero command exit code instead of forcing it to 255.
{
    my $result = $runner->run_once(
        {
            name      => 'failtemplate.collector',
            command   => q{printf 'not json'; exit 3},
            cwd       => $home,
            indicator => {
                name => 'failtemplate.indicator',
                icon => '[% a %]',
            },
        }
    );
    is( $result->{exit_code}, 3, 'run_once preserves a non-zero command exit code even when indicator materialization fails' );
}

# L104 left side: a runner without an indicator store skips indicator work.
{
    my $runner_no_indicators = Developer::Dashboard::CollectorRunner->new(
        collectors => $collector_store,
        files      => $files,
        paths      => $paths,
    );
    my $result = $runner_no_indicators->run_once(
        { name => 'noindicators.collector', command => q{printf ok}, cwd => $home, indicator => { name => 'x' } } );
    is( $result->{exit_code}, 0, 'run_once skips indicator materialization when no indicator store is configured' );
}

# ===========================================================================
# _materialize_indicator_state / _render_indicator_icon_template /
# _indicator_template_vars / _append_error_text / _collector_source.
# ===========================================================================

# L187/L188 required-argument dies.
like( ( eval { $runner->_materialize_indicator_state(); 1 } ? '' : $@ ), qr/Missing collector job/, '_materialize_indicator_state requires a job' );
like( ( eval { $runner->_materialize_indicator_state( job => { name => 'x' } ); 1 } ? '' : $@ ), qr/Missing indicator payload/, '_materialize_indicator_state requires an indicator payload' );

# L191: icon_template absent / empty / present.
{
    my $absent = $runner->_materialize_indicator_state( job => { name => 'm' }, indicator => { name => 'i' } );
    ok( !exists $absent->{icon}, '_materialize_indicator_state leaves icon untouched with no icon_template' );

    my $empty = $runner->_materialize_indicator_state( job => { name => 'm' }, indicator => { name => 'i', icon_template => '' } );
    ok( !exists $empty->{icon}, '_materialize_indicator_state skips rendering for an empty icon_template' );

    my $present = $runner->_materialize_indicator_state(
        job       => { name => 'm' },
        indicator => { name => 'i', icon_template => 'static' },
        stdout    => '{}',
    );
    is( $present->{icon}, 'static', '_materialize_indicator_state renders a present icon_template' );
}

# L208/L209 required-argument dies and L216 template-process failure.
like( ( eval { $runner->_render_indicator_icon_template(); 1 } ? '' : $@ ), qr/Missing collector name/, '_render_indicator_icon_template requires a collector name' );
like( ( eval { $runner->_render_indicator_icon_template( collector_name => 'c' ); 1 } ? '' : $@ ), qr/Missing indicator icon template/, '_render_indicator_icon_template requires a template' );
like(
    ( eval { $runner->_render_indicator_icon_template( collector_name => 'c', template => q{[% THROW myerr 'boom' %]}, stdout => '{"a":1}' ); 1 } ? '' : $@ ),
    qr/indicator icon template failed/,
    '_render_indicator_icon_template dies when the TT template fails to process',
);

# L228/L229/L238 template variable decoding.
like( ( eval { $runner->_indicator_template_vars(); 1 } ? '' : $@ ), qr/Missing collector name/, '_indicator_template_vars requires a collector name' );
like( ( eval { $runner->_indicator_template_vars( collector_name => 'c' ); 1 } ? '' : $@ ), qr/requires collector stdout JSON/, '_indicator_template_vars dies on an undef (defaulted-empty) stdout' );
{
    my $vars = $runner->_indicator_template_vars( collector_name => 'c', stdout => '[1,2,3]' );
    is_deeply( $vars->{data}, [ 1, 2, 3 ], '_indicator_template_vars decodes a non-hash payload into data only' );
    my $hash_vars = $runner->_indicator_template_vars( collector_name => 'c', stdout => '{"a":1}' );
    is( $hash_vars->{a}, 1, '_indicator_template_vars flattens a hash payload into template variables' );
}

# L250/L251/L252/L253 error-text merging.
is( $runner->_append_error_text( undef, 'boom' ), "boom\n", '_append_error_text tolerates an undef stderr' );
is( $runner->_append_error_text( 'keep', undef ), 'keep', '_append_error_text returns stderr unchanged for an undef error' );
is( $runner->_append_error_text( 'keep', '' ),    'keep', '_append_error_text returns stderr unchanged for an empty error' );
is( $runner->_append_error_text( 'abc', 'def' ), "abc\ndef\n", '_append_error_text separates a newline-less stderr from the appended error' );
is( $runner->_append_error_text( "abc\n", 'def' ), "abc\ndef\n", '_append_error_text does not double the separator when stderr already ends in a newline' );

# L263/L264/L265 source resolution.
like( ( eval { $runner->_collector_source( { command => '', code => '' } ); 1 } ? '' : $@ ), qr/missing command or code/, '_collector_source treats empty command and code as missing' );
like( ( eval { $runner->_collector_source( { name => 'named' } ); 1 } ? '' : $@ ), qr/'named' missing command or code/, '_collector_source names a hash job in its error' );
like( ( eval { $runner->_collector_source( bless {}, 'Some::Blessed' ); 1 } ? '' : $@ ), qr/'\(unnamed\)' missing/, '_collector_source labels a non-plain-hash job as unnamed' );

# L275 unknown/missing mode.
like( ( eval { $runner->_run_job(); 1 } ? '' : $@ ), qr/Missing collector mode/, '_run_job requires a mode' );

# ===========================================================================
# _collector_execution_policy / _effective_interval_seconds /
# _minimum_dashboard_command_interval_seconds / _is_dashboard_subcommand_collector.
# ===========================================================================

# L552/L553/L557.
is_deeply( [ $runner->_collector_execution_policy(undef) ], [ 'singleton', 1 ], '_collector_execution_policy defaults an undef job to singleton' );
is_deeply( [ $runner->_collector_execution_policy( { mode => '' } ) ], [ 'singleton', 1 ], '_collector_execution_policy treats an empty mode as singleton' );
is_deeply( [ $runner->_collector_execution_policy( { mode => 'multiple', multiple => 3 } ) ], [ 'multiple', 3 ], '_collector_execution_policy honors a bounded multiple limit' );
like( ( eval { $runner->_collector_execution_policy( { name => 'p', mode => 'multiple', multiple => 'abc' } ); 1 } ? '' : $@ ), qr/positive integer/, '_collector_execution_policy rejects a non-numeric multiple value' );
like( ( eval { $runner->_collector_execution_policy( { name => 'p', mode => 'multiple', multiple => 0 } ); 1 } ? '' : $@ ), qr/positive integer/, '_collector_execution_policy rejects a zero multiple value' );

# L570/L571/L572.
is( $runner->_effective_interval_seconds(undef),                 30, '_effective_interval_seconds defaults an undef job to 30s' );
is( $runner->_effective_interval_seconds( { interval => 'abc' } ), 30, '_effective_interval_seconds falls back for a non-numeric interval' );
is( $runner->_effective_interval_seconds( { interval => 0 } ),     30, '_effective_interval_seconds falls back for a non-positive interval' );
is( $runner->_effective_interval_seconds( { interval => 5 } ),     5,  '_effective_interval_seconds keeps a valid positive interval' );

# L590/L591 minimum floor env parsing.
{
    local $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS} = '';
    is( $runner->_minimum_dashboard_command_interval_seconds, 30, 'minimum floor defaults when the env value is empty' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS} = 'abc';
    is( $runner->_minimum_dashboard_command_interval_seconds, 30, 'minimum floor defaults when the env value is non-numeric' );
}
{
    local $ENV{DEVELOPER_DASHBOARD_MIN_DASHBOARD_COMMAND_INTERVAL_SECONDS} = '15';
    is( $runner->_minimum_dashboard_command_interval_seconds, 15, 'minimum floor honors a numeric env value' );
}

# L603/L605/L607.
is( $runner->_is_dashboard_subcommand_collector('not-a-hash'), 0, '_is_dashboard_subcommand_collector rejects a non-hash job' );
is( $runner->_is_dashboard_subcommand_collector( { command => '' } ), 0, '_is_dashboard_subcommand_collector rejects an empty command' );
is( $runner->_is_dashboard_subcommand_collector( { command => '/opt/tools/dashboard status' } ), 1, '_is_dashboard_subcommand_collector detects an absolute dashboard path command' );

# ===========================================================================
# _sleep_until_next_tick internals.
# ===========================================================================
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::sleep = sub { return 0 };
    is( $runner->_sleep_until_next_tick( interval => -5 ), 1, '_sleep_until_next_tick clamps a negative interval to zero' );
    is( $runner->_sleep_until_next_tick(),                 1, '_sleep_until_next_tick tolerates a missing interval and worker set' );
    is( $runner->_sleep_until_next_tick( interval => 0.3, active_workers => {} ), 1, '_sleep_until_next_tick drains a positive interval through its slices' );
}

# ===========================================================================
# _active_worker_pids / _state_active_worker_pids / _reap_finished_loop_workers.
# ===========================================================================
is_deeply( [ $runner->_active_worker_pids(undef) ], [], '_active_worker_pids tolerates an undef worker set' );
is_deeply( [ $runner->_state_active_worker_pids(undef) ], [], '_state_active_worker_pids rejects an undef name' );
is_deeply( [ $runner->_state_active_worker_pids('') ],    [], '_state_active_worker_pids rejects an empty name' );
{
    $runner->_write_loop_state( 'awp.collector', { active_worker_pids => [ 5, 5, 0, -1, 'x', undef, 7 ] } );
    is_deeply( [ $runner->_state_active_worker_pids('awp.collector') ], [ 5, 7 ], '_state_active_worker_pids filters and de-dupes recorded worker pids' );
}

# ===========================================================================
# _same_pid_namespace / _pid_namespace_id and pid-shape guards.
# ===========================================================================
is( $runner->_same_pid_namespace(undef), 0, '_same_pid_namespace rejects an undef pid' );
is( $runner->_same_pid_namespace('abc'), 0, '_same_pid_namespace rejects a non-numeric pid' );
is( $runner->_same_pid_namespace(0),     0, '_same_pid_namespace rejects a zero pid' );
is( $runner->_same_pid_namespace($$),    1, '_same_pid_namespace treats the current pid as same-namespace' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pid_namespace_id = sub { return undef };
    is( $runner->_same_pid_namespace($$), 1, '_same_pid_namespace assumes same namespace when the current ns id is unavailable' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pid_namespace_id = sub { return '' };
    is( $runner->_same_pid_namespace($$), 1, '_same_pid_namespace assumes same namespace when a target ns id is empty' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pid_namespace_id = sub { my ( undef, $pid ) = @_; return $pid == $$ ? 'ns:current' : '' };
    is( $runner->_same_pid_namespace(1), 1, '_same_pid_namespace assumes same namespace when the target ns id is empty but the current is known' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_pid_namespace_id = sub { my ( undef, $pid ) = @_; return $pid == $$ ? 'ns:a' : 'ns:b' };
    is( $runner->_same_pid_namespace(1), 0, '_same_pid_namespace rejects a differing target namespace' );
}

# _reap_child_process / _pid_is_running pid-shape guards.
is( $runner->_reap_child_process(undef), 0, '_reap_child_process rejects an undef pid' );
is( $runner->_reap_child_process('abc'), 0, '_reap_child_process rejects a non-numeric pid' );
is( $runner->_reap_child_process(0),     0, '_reap_child_process rejects a zero pid' );
is( $runner->_pid_is_running(undef), 0, '_pid_is_running rejects an undef pid' );
is( $runner->_pid_is_running('abc'), 0, '_pid_is_running rejects a non-numeric pid' );
is( $runner->_pid_is_running(0),     0, '_pid_is_running rejects a zero pid' );

# ===========================================================================
# _is_managed_loop / _state_confirms_managed_loop.
# ===========================================================================
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_same_pid_namespace = sub { return 0 };
    is( $runner->_is_managed_loop( $$, 'demo' ), 0, '_is_managed_loop rejects a pid outside the current namespace' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_same_pid_namespace     = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return 'other-loop' };
    local *Developer::Dashboard::CollectorRunner::_read_process_title      = sub { return 'unrelated' };
    is( $runner->_is_managed_loop( $$, 'demo' ), 0, '_is_managed_loop rejects a pid whose env marker names a different loop' );
}

is( $runner->_state_confirms_managed_loop( undef, $$ ), 0, '_state_confirms_managed_loop rejects an undef name' );
is( $runner->_state_confirms_managed_loop( '',    $$ ), 0, '_state_confirms_managed_loop rejects an empty name' );
is( $runner->_state_confirms_managed_loop( 'demo', 0 ), 0, '_state_confirms_managed_loop rejects a falsy pid' );
{
    write_raw_state( 'confirm.array', '[1,2,3]' );
    is( $runner->_state_confirms_managed_loop( 'confirm.array', $$ ), 0, '_state_confirms_managed_loop rejects non-hash recorded state' );
}
{
    write_raw_state( 'confirm.pid', json_encode( { pid => 0 } ) );
    is( $runner->_state_confirms_managed_loop( 'confirm.pid', $$ ), 0, '_state_confirms_managed_loop rejects a mismatched recorded pid' );
}
{
    write_raw_state( 'confirm.name', json_encode( { pid => $$ } ) );
    is( $runner->_state_confirms_managed_loop( 'confirm.name', $$ ), 0, '_state_confirms_managed_loop rejects a missing recorded name' );
}
{
    write_raw_state( 'confirm.title', json_encode( { pid => $$, name => 'confirm.title' } ) );
    is( $runner->_state_confirms_managed_loop( 'confirm.title', $$ ), 0, '_state_confirms_managed_loop rejects a missing recorded process title' );
}
{
    write_raw_state( 'confirm.stopped', json_encode( { pid => $$, name => 'confirm.stopped', process_name => $runner->_process_title('confirm.stopped'), status => 'stopped' } ) );
    is( $runner->_state_confirms_managed_loop( 'confirm.stopped', $$ ), 0, '_state_confirms_managed_loop rejects a recorded loop that already marked itself stopped' );
}
{
    write_raw_state( 'confirm.ok', json_encode( { pid => $$, name => 'confirm.ok', process_name => $runner->_process_title('confirm.ok'), status => 'running' } ) );
    is( $runner->_state_confirms_managed_loop( 'confirm.ok', $$ ), 1, '_state_confirms_managed_loop confirms a live recorded loop identity' );
}
{
    # Matching identity with no recorded status: the status fallback yields the
    # empty string, which is not 'stopped', so the loop is still confirmed.
    write_raw_state( 'confirm.nostatus', json_encode( { pid => $$, name => 'confirm.nostatus', process_name => $runner->_process_title('confirm.nostatus') } ) );
    is( $runner->_state_confirms_managed_loop( 'confirm.nostatus', $$ ), 1, '_state_confirms_managed_loop confirms a live recorded loop with no recorded status' );
}

# ===========================================================================
# _read_process_env_marker / _read_process_title / _read_process_state.
# ===========================================================================
is( $runner->_read_process_env_marker( 999999999, 'ANY' ), undef, '_read_process_env_marker returns undef for an unreadable environ' );
ok( defined $runner->_read_process_env_marker( $$, 'PATH' ), '_read_process_env_marker reads a present env marker for the current process' );

# A child that clears %ENV before exec has a genuinely empty (zero-length)
# environ, which reads back as a defined empty string and drives the
# empty-environ return path.
#
# This used to delegate to `env -i sleep 30` and poll /proc/<pid>/cmdline for
# /sleep/, but the intermediate env process already matches that pattern in its
# own cmdline, so the poll returned on its first iteration - before env had
# exec'd sleep and installed the empty environment. Measured 10 runs out of 10,
# the environ at that moment was still the inherited one (1564 and 1820 bytes in
# two samples), so whether the routine below saw an empty environ at all came
# down to env finishing its exec inside the gap between the poll exiting and the
# call being made. Nothing pinned that: is($marker, undef) is satisfied just as
# well by a populated environ that lacks the key, so the empty-environ leg could
# stop being exercised without a single assertion failing. Clearing the
# environment in this very fork removes the intermediate process entirely, and
# the environ assertion below turns the precondition into a real one.
SKIP: {
    my ($sleep_bin) = grep { -x } qw(/bin/sleep /usr/bin/sleep);
    skip 'no sleep binary available to hold an empty environment open', 2 if !defined $sleep_bin;
    my $probe_title = 'dd-empty-environ-probe';
    my $child       = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        %ENV = ();
        exec { $sleep_bin } $probe_title, '30' or CORE::exit(127);
    }
    # Poll on the exec'd argv[0], which only the post-exec process can show.
    #
    # The bound is 30 seconds, and it is measured rather than chosen (DD-482).
    # The previous bound was 500 polls -- 5 seconds -- and the coverage gate
    # failed on it while the plain suite passed. Instrumenting the loop showed
    # the bound expiring with the child still ALIVE in state R, having not yet
    # reached its exec: a Devel::Cover-instrumented child flushes its coverage
    # database before exec'ing, which took 678 polls (~6.8s) against 2 polls
    # plain. So the old bound sat just under what the gated run needs.
    #
    # Widening a poll loop is normally a smell, and in this repo it has been an
    # actual defect (a loop once widened past a sleep that was silently zero).
    # The difference is that the mechanism here was demonstrated before the
    # number was changed, and the timeout below now reports what it saw so a
    # future failure is diagnosable instead of a bare undef.
    my $probe_environ;
    my $probe_polls = 0;
    for ( 1 .. 3000 ) {
        $probe_polls = $_;
        my $cmdline = '';
        if ( open my $cf, '<', "/proc/$child/cmdline" ) { local $/; $cmdline = <$cf>; close $cf; }
        if ( defined $cmdline && index( $cmdline, $probe_title ) == 0 ) {
            if ( open my $ef, '<', "/proc/$child/environ" ) { local $/; $probe_environ = <$ef>; close $ef; }
            diag("probe child did not expose a readable environ after $probe_polls polls: $!")
              if !defined $probe_environ;
            last;
        }
        select undef, undef, undef, 0.01;
    }

    # A bare "got undef" says nothing about which of the two very different
    # failures happened: the child never reached its exec, or its environ could
    # not be read. Note that undef never means "the environ was empty" -- a
    # genuinely empty /proc/<pid>/environ reads back as '' with length 0.
    if ( !defined $probe_environ ) {
        my $alive = -e "/proc/$child" ? 'alive' : 'gone';
        my $state = eval {
            open my $st, '<', "/proc/$child/stat" or die;
            my $line = <$st>;
            close $st;
            ( split / /, $line )[2];
        } // '?';
        diag("probe gave up after $probe_polls polls; child is $alive in state $state and never exposed its exec'd argv[0]");
    }
    # Pin the precondition the coverage below depends on. Without this the
    # marker assertion is satisfied by any environ that lacks the key, so the
    # empty-environ leg can stop being exercised without a single test failing.
    is( $probe_environ, '', 'the probe child exposes a readable zero-length environ' );
    is( $runner->_read_process_env_marker( $child, 'ANY' ), undef, '_read_process_env_marker returns undef for an empty environ' );
    kill 9, $child;
    waitpid( $child, 0 );
}

# _read_process_title: proc cmdline path, then the ps fallback under a mocked
# capture so every exit-code and defined-title branch is exercised.
{
    my $title = $runner->_read_process_title($$);
    ok( defined $title && $title ne '', '_read_process_title reads the current process cmdline' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return undef };
    {
        local *Developer::Dashboard::CollectorRunner::capture = sub { return ( 'ps-title   ', '', 0 ) };
        is( $runner->_read_process_title($$), 'ps-title', '_read_process_title trims a successful ps fallback title' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::capture = sub { return ( '', '', 1 ) };
        is( $runner->_read_process_title($$), undef, '_read_process_title returns undef when the ps fallback exits non-zero' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::capture = sub { return ( undef, '', undef ) };
        is( $runner->_read_process_title($$), undef, '_read_process_title returns undef when the ps fallback yields no title' );
    }
}

# _read_process_state: procfs parse variants plus the ps fallback.
{
    no warnings 'redefine';
    {
        local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return '4242 (cmd) R 1 4242 4242' };
        is( $runner->_read_process_state($$), 'R', '_read_process_state parses a running state from procfs stat' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return 'garbage-without-format' };
        local *Developer::Dashboard::CollectorRunner::capture         = sub { return ( ' Ss ', '', 0 ) };
        is( $runner->_read_process_state($$), 'S', '_read_process_state falls back to ps when procfs stat is unparseable' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return '' };
        local *Developer::Dashboard::CollectorRunner::capture         = sub { return ( 'R', '', 0 ) };
        is( $runner->_read_process_state($$), 'R', '_read_process_state falls back to ps when procfs stat is empty' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::capture         = sub { return ( '', '', 1 ) };
        is( $runner->_read_process_state($$), undef, '_read_process_state returns undef when the ps fallback exits non-zero' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::capture         = sub { return ( undef, '', undef ) };
        is( $runner->_read_process_state($$), undef, '_read_process_state returns undef when the ps fallback yields no state' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_read_proc_file = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::capture         = sub { return ( '', '', 0 ) };
        is( $runner->_read_process_state($$), undef, '_read_process_state returns undef when the ps fallback state is empty' );
    }
}

# ===========================================================================
# loop_state error/empty/retry paths.
# ===========================================================================
is( $runner->loop_state('missing.loop'), undef, 'loop_state returns undef when no state file exists' );
{
    # An unreadable-but-present state file makes the open fail.
    my $file = write_raw_state( 'unreadable.loop', json_encode( { status => 'running' } ) );
  SKIP: {
        chmod 0000, $file or skip 'chmod not honored on this filesystem', 1;
        skip 'running as root defeats the unreadable-file open failure', 1 if -r $file;
        like( ( eval { $runner->loop_state('unreadable.loop'); 1 } ? '' : $@ ), qr/Unable to read/, 'loop_state dies when a present state file cannot be opened' );
        chmod 0600, $file;
    }
}
{
    write_raw_state( 'emptypayload.loop', '' );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::sleep = sub { return 0 };
    like( ( eval { $runner->loop_state('emptypayload.loop'); 1 } ? '' : $@ ), qr/was empty/, 'loop_state reports a truly empty state payload' );
}
{
    write_raw_state( 'nonref.loop', '{ not: valid json' );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::sleep = sub { return 0 };
    ok( !eval { $runner->loop_state('nonref.loop'); 1 }, 'loop_state dies after retrying an undecodable state payload' );
}
{
    # A decode that yields a falsy-but-defined value (no exception) drives the
    # default decode-error fallback message.
    write_raw_state( 'falsydecode.loop', '{}' );
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::sleep       = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::json_decode = sub { return 0 };
    ok( !eval { $runner->loop_state('falsydecode.loop'); 1 }, 'loop_state falls back to the default decode-error message when json_decode yields a falsy value' );
}

# ===========================================================================
# _write_loop_state: undef data merge and temp-open failure.
# ===========================================================================
{
    my $state = $runner->_write_loop_state( 'undefdata.loop', undef );
    is( $state->{name}, 'undefdata.loop', '_write_loop_state tolerates an undef data payload' );
}
{
  SKIP: {
        my $dir = $paths->collector_dir('nowrite.loop');
        chmod 0500, $dir or skip 'chmod not honored on this filesystem', 1;
        skip 'running as root defeats the unwritable-directory failure', 1 if -w $dir;
        like( ( eval { $runner->_write_loop_state( 'nowrite.loop', { status => 'running' } ); 1 } ? '' : $@ ), qr/Unable to write/, '_write_loop_state dies when the temp state file cannot be opened' );
        chmod 0700, $dir;
    }
}

# ===========================================================================
# _slurp failure.
# ===========================================================================
like( ( eval { Developer::Dashboard::CollectorRunner::_slurp( File::Spec->catfile( $home, 'no-such-slurp-file' ) ); 1 } ? '' : $@ ), qr/Unable to read/, '_slurp dies for a missing file' );

# ===========================================================================
# _descriptor_is_inherited_pipe fd classification.
# ===========================================================================
is( $runner->_descriptor_is_inherited_pipe(undef), 0, '_descriptor_is_inherited_pipe rejects an undef fd' );
is( $runner->_descriptor_is_inherited_pipe('abc'), 0, '_descriptor_is_inherited_pipe rejects a non-numeric fd' );
is( $runner->_descriptor_is_inherited_pipe(999999999), 0, '_descriptor_is_inherited_pipe rejects an fd with no symlink target' );
{
    open my $reg, '>', File::Spec->catfile( $home, 'fd-regular' ) or die $!;
    is( $runner->_descriptor_is_inherited_pipe( fileno($reg) ), 0, '_descriptor_is_inherited_pipe ignores a plain-file fd without close_ipc' );
    is( $runner->_descriptor_is_inherited_pipe( fileno($reg), close_ipc => 1 ), 0, '_descriptor_is_inherited_pipe ignores a plain-file fd even with close_ipc' );
    close $reg;

    socketpair my $sa, my $sb, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die "socketpair failed: $!";
    is( $runner->_descriptor_is_inherited_pipe( fileno($sa), close_ipc => 1 ), 1, '_descriptor_is_inherited_pipe treats a socket fd as an IPC endpoint under close_ipc' );
    close $sa;
    close $sb;
}

# ===========================================================================
# _current_perl_command / _dashboard_core_helper_path /
# _helper_file_supports_internal_command / _powershell_command /
# _powershell_single_quote / _replace_path_via_powershell /
# _overwrite_state_file_in_place / _spawn_windows_background_command.
# ===========================================================================

# _current_perl_command: Windows branch and the $^X shape guards on Linux.
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
    {
        local *Developer::Dashboard::CollectorRunner::command_in_path = sub { return '/win/perl' };
        is( $runner->_current_perl_command, '/win/perl', '_current_perl_command prefers perl on Windows when present' );
    }
    {
        my %answers = ( 'perl' => undef, 'perl.exe' => '/win/perl.exe' );
        local *Developer::Dashboard::CollectorRunner::command_in_path = sub { return $answers{ $_[0] } };
        is( $runner->_current_perl_command, '/win/perl.exe', '_current_perl_command falls back to perl.exe on Windows' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::command_in_path = sub { return undef };
        local $^X = 'x';
        is( $runner->_current_perl_command, 'x', '_current_perl_command falls through to $^X when no Windows perl is resolvable' );
    }
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::command_in_path = sub { return '/usr/bin/perl' };
    is( $runner->_current_perl_command, $^X, '_current_perl_command returns a runnable $^X on Linux' );
    {
        local $^X = '';
        is( $runner->_current_perl_command, '/usr/bin/perl', '_current_perl_command skips an empty $^X' );
    }
    {
        no warnings 'uninitialized';
        local $^X = undef;
        is( $runner->_current_perl_command, '/usr/bin/perl', '_current_perl_command skips an undef $^X' );
    }
    {
        local $^X = File::Spec->catfile( $home, 'not-a-real-perl-binary' );
        is( $runner->_current_perl_command, '/usr/bin/perl', '_current_perl_command skips a non-existent $^X' );
    }
}

# _dashboard_core_helper_path: default command plus the undef shipped-path guard.
ok( defined $runner->_dashboard_core_helper_path(), '_dashboard_core_helper_path defaults its command argument' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::_helper_asset_path = sub { return undef };
    ok( defined $runner->_dashboard_core_helper_path('collector-loop-foreground'), '_dashboard_core_helper_path tolerates an undef shipped helper path' );
}

# _helper_file_supports_internal_command: argument guards and unreadable file.
is( $runner->_helper_file_supports_internal_command( undef, 'cmd' ), 0, '_helper_file_supports_internal_command rejects an undef path' );
is( $runner->_helper_file_supports_internal_command( '',    'cmd' ), 0, '_helper_file_supports_internal_command rejects an empty path' );
is( $runner->_helper_file_supports_internal_command( File::Spec->catfile( $home, 'no-helper' ), 'cmd' ), 0, '_helper_file_supports_internal_command rejects a missing file' );
{
    my $helper = File::Spec->catfile( $home, 'helper-body' );
    open my $fh, '>', $helper or die $!;
    print {$fh} "collector-loop-foreground body\n";
    close $fh;
    is( $runner->_helper_file_supports_internal_command( $helper, undef ), 0, '_helper_file_supports_internal_command rejects an undef command' );
    is( $runner->_helper_file_supports_internal_command( $helper, '' ),    0, '_helper_file_supports_internal_command rejects an empty command' );
    is( $runner->_helper_file_supports_internal_command( $helper, 'collector-loop-foreground' ), 1, '_helper_file_supports_internal_command detects a present command token' );
  SKIP: {
        chmod 0000, $helper or skip 'chmod not honored on this filesystem', 1;
        skip 'running as root defeats the unreadable-file open failure', 1 if -r $helper;
        is( $runner->_helper_file_supports_internal_command( $helper, 'collector-loop-foreground' ), 0, '_helper_file_supports_internal_command returns false when a present file cannot be opened' );
        chmod 0600, $helper;
    }
}

# _powershell_command / _powershell_single_quote on Linux.
is( $runner->_powershell_command, '', '_powershell_command returns empty on a non-Windows host' );
is( Developer::Dashboard::CollectorRunner::_powershell_single_quote(undef), q{''}, '_powershell_single_quote defaults an undef value to an empty literal' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows      = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::command_in_path = sub { return undef };
    {
        local $ENV{SystemRoot} = '/tmp/win-system-root';
        is( $runner->_powershell_command, '', '_powershell_command falls back through SystemRoot and returns empty when no binary exists' );
    }
    {
        local %ENV = %ENV;
        delete $ENV{SystemRoot};
        is( $runner->_powershell_command, '', '_powershell_command defaults SystemRoot when it is unset' );
    }
}

# _replace_path_via_powershell early return, powershell-missing guards, and the
# stderr/stdout merge on a non-zero PowerShell exit.
is_deeply( [ $runner->_replace_path_via_powershell( 'a', 'b' ) ], [ 0, '' ], '_replace_path_via_powershell no-ops on a non-Windows host' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
    {
        local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return '' };
        my ( $ok, $err ) = $runner->_replace_path_via_powershell( 'a', 'b' );
        is( $ok, 0, '_replace_path_via_powershell fails when PowerShell resolves to an empty string' );
        like( $err, qr/PowerShell/, '_replace_path_via_powershell explains the missing PowerShell binary' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return undef };
        my ( $ok ) = $runner->_replace_path_via_powershell( 'a', 'b' );
        is( $ok, 0, '_replace_path_via_powershell fails when PowerShell resolves to undef' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return 'pwsh' };
        local *Developer::Dashboard::CollectorRunner::capture             = sub { return ( '', '', 0 ) };
        my ( $ok ) = $runner->_replace_path_via_powershell( 'a', 'b' );
        is( $ok, 1, '_replace_path_via_powershell reports success on a zero PowerShell exit' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return 'pwsh' };
        local *Developer::Dashboard::CollectorRunner::capture             = sub { return ( 'out-msg', 'err-msg', 1 ) };
        my ( $ok, $err ) = $runner->_replace_path_via_powershell( 'a', 'b' );
        is( $ok, 0, '_replace_path_via_powershell fails on a non-zero PowerShell exit' );
        is( $err, 'err-msgout-msg', '_replace_path_via_powershell merges stderr and stdout on failure' );
    }
    {
        local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return 'pwsh' };
        local *Developer::Dashboard::CollectorRunner::capture             = sub { return ( '', '', 1 ) };
        my ( $ok, $err ) = $runner->_replace_path_via_powershell( 'a', 'b' );
        is( $err, '', '_replace_path_via_powershell yields an empty message when both streams are empty' );
    }
}

# _overwrite_state_file_in_place: Linux no-op and Windows failure/success paths.
is_deeply( [ $runner->_overwrite_state_file_in_place( 'a', 'b' ) ], [ 0, '' ], '_overwrite_state_file_in_place no-ops on a non-Windows host' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
    my $src = File::Spec->catfile( $home, 'ovr-src' );
    my $tgt = File::Spec->catfile( $home, 'ovr-tgt' );

    {
        my ( $ok ) = $runner->_overwrite_state_file_in_place( File::Spec->catfile( $home, 'ovr-missing-src' ), $tgt );
        is( $ok, 0, '_overwrite_state_file_in_place fails when the source cannot be read' );
    }
    {
        open my $sfh, '>', $src or die $!;
        print {$sfh} 'payload';
        close $sfh;
        my ( $ok ) = $runner->_overwrite_state_file_in_place( $src, File::Spec->catfile( $home, 'no-such-dir', 'ovr-tgt' ) );
        is( $ok, 0, '_overwrite_state_file_in_place fails when the target cannot be opened' );
    }
    {
        # Writing more than one PerlIO buffer to /dev/full makes the mid-print
        # flush fail. The implicit close of the returned-from handle then re-tries
        # the flush and emits an expected ENOSPC close warning; tolerate exactly
        # that one artifact while still turning any other warning into a failure.
        local $SIG{__WARN__} = sub {
            my ($w) = @_;
            return if defined $w && $w =~ /unable to close filehandle.*No space left on device/;
            die $w;
        };
        open my $sfh, '>', $src or die $!;
        print {$sfh} ( 'payload' x 5000 );    # larger than the PerlIO buffer so the write flushes mid-print
        close $sfh;
        my ( $ok ) = $runner->_overwrite_state_file_in_place( $src, '/dev/full' );
        is( $ok, 0, '_overwrite_state_file_in_place fails when the target write cannot be flushed' );
    }
    {
        open my $sfh, '>', $src or die $!;
        print {$sfh} 'payload';
        close $sfh;
        my ( $ok ) = $runner->_overwrite_state_file_in_place( $src, $tgt );
        is( $ok, 1, '_overwrite_state_file_in_place overwrites the target and removes the source' );
        ok( !-e $src, '_overwrite_state_file_in_place unlinks the source after a successful overwrite' );
    }
    {
        open my $sfh, '>', $src or die $!;
        print {$sfh} 'payload';
        close $sfh;
        local *Developer::Dashboard::CollectorRunner::_unlink_path = sub { return 0 };
        my ( $ok ) = $runner->_overwrite_state_file_in_place( $src, $tgt );
        is( $ok, 1, '_overwrite_state_file_in_place still succeeds when the source unlink fails' );
        unlink $src;
    }
}

# _spawn_windows_background_command: missing PowerShell, non-zero exit, and pid parse.
like( ( eval { $runner->_spawn_windows_background_command( 'perl', 'x' ); 1 } ? '' : $@ ), qr/powershell is unavailable/, '_spawn_windows_background_command dies when PowerShell is unavailable' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return undef };
    like( ( eval { $runner->_spawn_windows_background_command( 'perl', 'x' ); 1 } ? '' : $@ ), qr/powershell is unavailable/, '_spawn_windows_background_command dies when PowerShell resolves to undef' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::CollectorRunner::capture             = sub { return ( 'boom', 'err', 1 ) };
    like( ( eval { $runner->_spawn_windows_background_command( 'perl', 'x' ); 1 } ? '' : $@ ), qr/Unable to launch detached Windows collector process/, '_spawn_windows_background_command dies on a non-zero PowerShell exit' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::CollectorRunner::capture             = sub { return ( "42\nabc\n0\n", '', 0 ) };
    is( $runner->_spawn_windows_background_command( 'perl', 'x' ), 42, '_spawn_windows_background_command parses the first positive numeric pid from stdout' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_powershell_command = sub { return 'pwsh' };
    local *Developer::Dashboard::CollectorRunner::capture             = sub { return ( '', '', 0 ) };
    is( $runner->_spawn_windows_background_command( 'perl', 'x' ), undef, '_spawn_windows_background_command returns undef when stdout carries no pid' );
}

# ===========================================================================
# _replace_state_file: Linux non-Windows failure, and the Windows retry loop.
# ===========================================================================
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_rename_path = sub { return 0 };
    like( ( eval { $runner->_replace_state_file( File::Spec->catfile( $home, 'no-src' ), File::Spec->catfile( $home, 'no-tgt' ) ); 1 } ? '' : $@ ), qr/Unable to rename/, '_replace_state_file dies when a non-Windows rename fails and the source is gone' );

    my $existing_src = File::Spec->catfile( $home, 'rs-src' );
    open my $sfh, '>', $existing_src or die $!;
    close $sfh;
    like( ( eval { $runner->_replace_state_file( $existing_src, File::Spec->catfile( $home, 'no-tgt2' ) ); 1 } ? '' : $@ ), qr/Unable to rename/, '_replace_state_file unlinks an existing source before dying on a non-Windows rename failure' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows   = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::sleep        = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_unlink_path = sub { return 0 };

    my $tgt = File::Spec->catfile( $home, 'rsw-existing-tgt' );
    open my $tfh, '>', $tgt or die $!;
    close $tfh;
    local *Developer::Dashboard::CollectorRunner::_rename_path = sub { return 0 };
    like(
        ( eval { $runner->_replace_state_file( File::Spec->catfile( $home, 'rsw-src' ), $tgt ); 1 } ? '' : $@ ),
        qr/Unable to remove .* before Windows replace retry/,
        '_replace_state_file dies when the existing Windows target cannot be removed',
    );
    unlink $tgt;
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows                  = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::sleep                       = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_replace_path_via_powershell = sub { return ( 0, undef ) };
    local *Developer::Dashboard::CollectorRunner::_overwrite_state_file_in_place = sub { return ( 0, undef ) };
    my $rename_calls = 0;
    local *Developer::Dashboard::CollectorRunner::_rename_path = sub { $rename_calls++; return $rename_calls >= 2 ? 1 : 0 };
    ok( $runner->_replace_state_file( File::Spec->catfile( $home, 'rsw2-src' ), File::Spec->catfile( $home, 'rsw2-tgt' ) ), '_replace_state_file recovers when a later Windows rename retry succeeds (undef fallback messages)' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows                  = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::sleep                       = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_rename_path                = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_replace_path_via_powershell = sub { return ( 0, '' ) };
    local *Developer::Dashboard::CollectorRunner::_overwrite_state_file_in_place = sub { return ( 0, '' ) };
    local *Developer::Dashboard::CollectorRunner::_unlink_path                = sub { return 1 };
    like(
        ( eval { $runner->_replace_state_file( File::Spec->catfile( $home, 'rsw3-src' ), File::Spec->catfile( $home, 'rsw3-tgt' ) ); 1 } ? '' : $@ ),
        qr/Unable to rename/,
        '_replace_state_file exhausts the Windows retry loop with empty fallback messages and dies',
    );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows                  = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::sleep                       = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_rename_path                = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_replace_path_via_powershell = sub { return ( 0, "psh error\n" ) };
    local *Developer::Dashboard::CollectorRunner::_overwrite_state_file_in_place = sub { return ( 0, "overwrite error\n" ) };
    local *Developer::Dashboard::CollectorRunner::_unlink_path                = sub { return 1 };
    like(
        ( eval { $runner->_replace_state_file( File::Spec->catfile( $home, 'rsw4-src' ), File::Spec->catfile( $home, 'rsw4-tgt' ) ); 1 } ? '' : $@ ),
        qr/PowerShell Move-Item fallback failed.*in-place overwrite fallback failed/s,
        '_replace_state_file accumulates non-empty fallback error messages before dying',
    );
}

# ===========================================================================
# cron scheduling: _job_is_due, _cron_due, _cron_match.
# ===========================================================================
ok( !$runner->_job_is_due( { schedule => 'manual' }, 'cron.c' ), '_job_is_due rejects a manual collector' );
ok( $runner->_job_is_due( { interval => 10 }, 'cron.c' ),       '_job_is_due accepts an interval collector' );
ok( $runner->_job_is_due( { schedule => 'interval' }, 'cron.c' ), '_job_is_due accepts an explicit interval schedule' );
ok( $runner->_cron_due( undef, 'cron.undef' ), '_cron_due treats an undef expression as always due' );
ok( $runner->_cron_due( '',    'cron.empty' ), '_cron_due treats an empty expression as always due' );
ok( !$runner->_cron_due( '60 * * * *', 'cron.min' ),  '_cron_due rejects an unmatchable minute field' );
ok( !$runner->_cron_due( '* 25 * * *', 'cron.hour' ), '_cron_due rejects an unmatchable hour field' );
ok( !$runner->_cron_due( '* * 32 * *', 'cron.mday' ), '_cron_due rejects an unmatchable day-of-month field' );
ok( !$runner->_cron_due( '* * * 13 *', 'cron.mon' ),  '_cron_due rejects an unmatchable month field' );
ok( !$runner->_cron_due( '* * * * 8', 'cron.wday' ),  '_cron_due rejects an unmatchable weekday field' );

is( Developer::Dashboard::CollectorRunner::_cron_match( undef, 5 ), 1, '_cron_match treats an undef spec as a wildcard' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '',    5 ), 1, '_cron_match treats an empty spec as a wildcard' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '*',   5 ), 1, '_cron_match treats a star spec as a wildcard' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '*/0', 5 ), 0, '_cron_match ignores a zero step divisor' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '*/2', 4 ), 1, '_cron_match matches a step divisor' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '10-20', 5 ),  0, '_cron_match rejects a value below a range' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '10-20', 25 ), 0, '_cron_match rejects a value above a range' );
is( Developer::Dashboard::CollectorRunner::_cron_match( '10-20', 15 ), 1, '_cron_match accepts a value inside a range' );

# ===========================================================================
# _run_command / _run_code: chdir failures, timeout, error propagation, env.
# ===========================================================================
like( ( eval { $runner->_run_command( source => 'true', cwd => File::Spec->catdir( $home, 'no-such-cwd' ), timeout_ms => 1000 ); 1 } ? '' : $@ ), qr/Unable to chdir/, '_run_command dies when it cannot chdir into the collector cwd' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::shell_command_argv = sub { die "argv boom\n" };
    like( ( eval { $runner->_run_command( source => 'true', cwd => $home, timeout_ms => 1000 ); 1 } ? '' : $@ ), qr/argv boom/, '_run_command re-throws a non-timeout error from the command build' );
}
{
    my ( $stdout, $stderr, $exit_code, $timed_out ) = $runner->_run_command( source => qq{$^X -e 'sleep 5'}, cwd => $home, timeout_ms => 100 );
    is( $exit_code, 124, '_run_command reports a timeout exit code' );
    ok( $timed_out, '_run_command flags a timed-out command' );
}

# Command-launcher pid tracking and platform-specific subtree cleanup branches.
{
    my $pidfile = File::Spec->catfile( $home, 'command.pid' );
    ok( !defined $runner->_command_pid_from_file(undef), '_command_pid_from_file rejects an undef path' );
    ok( !defined $runner->_command_pid_from_file(''), '_command_pid_from_file rejects an empty path' );
    ok( !defined $runner->_command_pid_from_file($pidfile), '_command_pid_from_file rejects a missing file' );

    open my $fh, '>', $pidfile or die $!;
    print {$fh} "not-a-pid\n";
    close $fh;
    ok( !defined $runner->_command_pid_from_file($pidfile), '_command_pid_from_file rejects non-numeric content' );

    open $fh, '>', $pidfile or die $!;
    print {$fh} "0\n";
    close $fh;
    ok( !defined $runner->_command_pid_from_file($pidfile), '_command_pid_from_file rejects pid zero' );

    open $fh, '>', $pidfile or die $!;
    print {$fh} "4242\n";
    close $fh;
    is( $runner->_command_pid_from_file($pidfile), 4242, '_command_pid_from_file returns a positive pid' );

    is( $runner->_await_command_pid($pidfile), 4242,
        '_await_command_pid returns a pid as soon as the launcher records it' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_command_pid_from_file = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::sleep = sub { return 0 };
        ok( !defined $runner->_await_command_pid($pidfile),
            '_await_command_pid stops after its bounded startup wait' );
    }

    my @launcher = $runner->_command_launcher_argv( $pidfile, 'command', 'arg' );
    is( $launcher[0], $^X, '_command_launcher_argv uses the current Perl interpreter' );
    is_deeply( [ @launcher[ -3 .. -1 ] ], [ $pidfile, 'command', 'arg' ],
        '_command_launcher_argv preserves the pid file and command argv' );
}

ok( $runner->_terminate_command_process(undef), '_terminate_command_process tolerates an undef pid' );
ok( $runner->_terminate_command_process('bad'), '_terminate_command_process tolerates a non-numeric pid' );
ok( $runner->_terminate_command_process(0), '_terminate_command_process tolerates pid zero' );
{
    my $fake_bin = File::Spec->catdir( $home, 'fake-taskkill-bin' );
    make_path($fake_bin);
    my $taskkill = File::Spec->catfile( $fake_bin, 'taskkill' );
    open my $fh, '>', $taskkill or die $!;
    print {$fh} "#!/bin/sh\nexit 0\n";
    close $fh;
    chmod 0755, $taskkill or die $!;
    local $ENV{PATH} = "$fake_bin:$ENV{PATH}";
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
    ok( $runner->_terminate_command_process(999999999),
        '_terminate_command_process invokes the Windows taskkill tree path' );
}
SKIP: {
    skip 'stubborn command cleanup needs POSIX process groups', 1
      if Developer::Dashboard::Platform::is_windows();
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        POSIX::setsid();
        $SIG{TERM} = 'IGNORE';
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    }
    select undef, undef, undef, 0.1;
    ok( $runner->_terminate_command_process($child),
        '_terminate_command_process escalates a stubborn POSIX group to KILL' );
}
{
    my $pidfile = File::Spec->catfile( $home, 'forwarded-command.pid' );
    open my $fh, '>', $pidfile or die $!;
    print {$fh} "4242\n";
    close $fh;
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_await_command_pid = sub { return 4242 };
        local *Developer::Dashboard::CollectorRunner::_terminate_command_process = sub { return 1 };
        $runner->_forward_command_signal( $pidfile, 'TERM', 15 );
        POSIX::_exit(1);
    }
    waitpid( $child, 0 );
    is( $? >> 8, 143, '_forward_command_signal preserves the numeric signal exit on Windows' );
    ok( !-e $pidfile, '_forward_command_signal removes the command pid file' );
}

like( ( eval { $runner->_run_code( source => '1', cwd => File::Spec->catdir( $home, 'no-such-cwd' ), timeout_ms => 1000 ); 1 } ? '' : $@ ), qr/Unable to chdir/, '_run_code dies when it cannot chdir into the collector cwd' );
{
    my ( undef, undef, $exit_code ) = $runner->_run_code( source => 'undef', cwd => $home );
    is( $exit_code, 0, '_run_code maps an undef result to exit 0' );
}
{
    my ( undef, undef, $exit_code ) = $runner->_run_code( source => '"not-a-number"', cwd => $home );
    is( $exit_code, 0, '_run_code maps a non-numeric result to exit 0' );
}
{
    my ( undef, undef, $exit_code ) = $runner->_run_code( source => '42', cwd => $home, env => { CODE_ENV => 'v' } );
    is( $exit_code, 42, '_run_code passes through a numeric result as the exit code' );
}
{
    my ( undef, undef, $exit_code ) = $runner->_run_code( source => '7', cwd => $home, env => {} );
    is( $exit_code, 7, '_run_code tolerates an empty env hash' );
}

# _run_command / _run_code cwd-restore failure: the command removes the
# original cwd so the chdir back fails.
{
    my $old_cwd = File::Spec->catdir( $home, 'restore-old-cmd' );
    my $run_cwd = File::Spec->catdir( $home, 'restore-run-cmd' );
    make_path( $old_cwd, $run_cwd );
    chdir $old_cwd or die $!;
    my $err = eval { $runner->_run_command( source => qq{rmdir '$old_cwd'}, cwd => $run_cwd, timeout_ms => 2000 ); 1 } ? '' : $@;
    chdir $home or die $!;
    like( $err, qr/Unable to restore cwd/, '_run_command dies when it cannot chdir back to the original cwd' );
}
{
    my $old_cwd = File::Spec->catdir( $home, 'restore-old-code' );
    my $run_cwd = File::Spec->catdir( $home, 'restore-run-code' );
    make_path( $old_cwd, $run_cwd );
    chdir $old_cwd or die $!;
    my $err = eval { $runner->_run_code( source => qq{rmdir '$old_cwd'; 0}, cwd => $run_cwd, timeout_ms => 2000 ); 1 } ? '' : $@;
    chdir $home or die $!;
    like( $err, qr/Unable to restore cwd/, '_run_code dies when it cannot chdir back to the original cwd' );
}

# ===========================================================================
# start_loop: name guard, fork failure, pidfile-open failure, and the parent
# branch (mocked fork) with matching and differing configured intervals.
# ===========================================================================
like( ( eval { $runner->start_loop( {} ); 1 } ? '' : $@ ), qr/missing name/, 'start_loop requires a collector name' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return undef };
    like( ( eval { $runner->start_loop( { name => 'forkfail.loop', command => 'sleep 1', cwd => $home, interval => 5 } ); 1 } ? '' : $@ ), qr/Unable to fork/, 'start_loop dies when fork fails' );
}
{
    my $dir_pidfile = $runner->_pidfile('pidfiledir.loop');
    make_path($dir_pidfile);
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 4242 };
    like( ( eval { $runner->start_loop( { name => 'pidfiledir.loop', command => 'sleep 1', cwd => $home, interval => 5 } ); 1 } ? '' : $@ ), qr/Unable to write/, 'start_loop dies when the pidfile cannot be written' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 515151 };
    is( $runner->start_loop( { name => 'parent.matching.loop', command => 'sleep 1', cwd => $home, interval => 5 } ), 515151, 'start_loop returns the (mocked) child pid in the parent branch' );
    my $state = $runner->loop_state('parent.matching.loop');
    ok( !exists $state->{configured_interval}, 'start_loop omits configured_interval when the effective interval matches' );
    $runner->_cleanup_loop_files('parent.matching.loop');
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 525252 };
    is( $runner->start_loop( { name => 'parent.floored.loop', command => 'dashboard status', cwd => $home, interval => 1 } ), 525252, 'start_loop returns the (mocked) child pid for a floored dashboard collector' );
    is( $runner->loop_state('parent.floored.loop')->{configured_interval}, 1, 'start_loop records configured_interval when the effective interval is floored' );
    $runner->_cleanup_loop_files('parent.floored.loop');
}

# start_loop existing-pidfile branch: an already-running loop recognized by
# process identity, by recorded state, a stale pidfile, and a falsy recorded pid.
{
    my $name = 'existing.managed.loop';
    open my $fh, '>', $runner->_pidfile($name) or die $!;
    print {$fh} "12345\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_is_managed_loop = sub { return 1 };
    is( $runner->start_loop( { name => $name, command => 'sleep 1', cwd => $home, interval => 5, schedule => 'interval' } ), 12345, 'start_loop returns and refreshes an already-running managed loop' );
    is( $runner->loop_state($name)->{status}, 'running', 'start_loop refreshes state for an already-running managed loop' );
    $runner->_cleanup_loop_files($name);
}
{
    my $name = 'existing.confirmed.loop';
    open my $fh, '>', $runner->_pidfile($name) or die $!;
    print {$fh} "23456\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_is_managed_loop            = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_state_confirms_managed_loop = sub { return 1 };
    is( $runner->start_loop( { name => $name, command => 'sleep 1', cwd => $home, interval => 5 } ), 23456, 'start_loop returns a state-confirmed already-running loop' );
    $runner->_cleanup_loop_files($name);
}
{
    my $name = 'existing.stale.loop';
    open my $fh, '>', $runner->_pidfile($name) or die $!;
    print {$fh} "34567\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_is_managed_loop            = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_state_confirms_managed_loop = sub { return 0 };
    local *Developer::Dashboard::CollectorRunner::_fork_process               = sub { return 636363 };
    is( $runner->start_loop( { name => $name, command => 'sleep 1', cwd => $home, interval => 5 } ), 636363, 'start_loop replaces a stale pidfile and starts a new loop' );
    $runner->_cleanup_loop_files($name);
}
{
    my $name = 'existing.falsypid.loop';
    open my $fh, '>', $runner->_pidfile($name) or die $!;
    print {$fh} "0\n";
    close $fh;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return 646464 };
    is( $runner->start_loop( { name => $name, command => 'sleep 1', cwd => $home, interval => 5 } ), 646464, 'start_loop discards a falsy recorded pid and starts a new loop' );
    $runner->_cleanup_loop_files($name);
}

# ===========================================================================
# _start_windows_loop_process: argument guards, spawn failure, pidfile failure,
# and the two configured-interval branches.
# ===========================================================================
like( ( eval { $runner->_start_windows_loop_process(); 1 } ? '' : $@ ), qr/Missing collector job/, '_start_windows_loop_process requires a job' );
like( ( eval { $runner->_start_windows_loop_process( job => {} ); 1 } ? '' : $@ ), qr/Missing collector name/, '_start_windows_loop_process requires a name' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_windows_background_loop_command  = sub { return ('cmd') };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 0 };
    like(
        ( eval { $runner->_start_windows_loop_process( job => { name => 'winspawn' }, name => 'winspawn', title => 't', interval => 5, configured_interval => 10, schedule_mode => 'interval' ); 1 } ? '' : $@ ),
        qr/Unable to launch collector 'winspawn' on Windows/,
        '_start_windows_loop_process dies when the detached spawn fails',
    );
}
{
    my $dir_pidfile = $runner->_pidfile('winpiddir');
    make_path($dir_pidfile);
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_windows_background_loop_command  = sub { return ('cmd') };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 9191 };
    like(
        ( eval { $runner->_start_windows_loop_process( job => { name => 'winpiddir' }, name => 'winpiddir', title => 't', interval => 5, configured_interval => 10, schedule_mode => 'interval' ); 1 } ? '' : $@ ),
        qr/Unable to write/,
        '_start_windows_loop_process dies when the detached pidfile cannot be written',
    );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_windows_background_loop_command  = sub { return ('cmd') };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 8181 };
    is(
        $runner->_start_windows_loop_process( job => { name => 'windiff', command => 'x' }, name => 'windiff', title => 't', interval => 5, configured_interval => 10, schedule_mode => 'cron' ),
        8181,
        '_start_windows_loop_process records a differing configured interval and returns the spawned pid',
    );
    is( $runner->loop_state('windiff')->{configured_interval}, 10, '_start_windows_loop_process persists a differing configured interval' );
    $runner->_cleanup_loop_files('windiff');
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_windows_background_loop_command  = sub { return ('cmd') };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { return 7171 };
    is(
        $runner->_start_windows_loop_process( job => { name => 'winsame', command => 'x' }, name => 'winsame' ),
        7171,
        '_start_windows_loop_process defaults title/interval/schedule and returns the spawned pid',
    );
    ok( !exists $runner->loop_state('winsame')->{configured_interval}, '_start_windows_loop_process omits configured_interval when defaults match' );
    $runner->_cleanup_loop_files('winsame');
}

# ===========================================================================
# _run_loop_child: argument guards and single-tick coverage of the scheduling
# body run in-process (daemonize => 0). Coverage-env vars are preserved because
# the child scrubs them when instrumentation is active.
# ===========================================================================
like( ( eval { $runner->_run_loop_child(); 1 } ? '' : $@ ), qr/Missing collector job/, '_run_loop_child requires a job' );
like( ( eval { $runner->_run_loop_child( job => {} ); 1 } ? '' : $@ ), qr/Missing collector name/, '_run_loop_child requires a name' );

{
    my $harness  = $ENV{HARNESS_PERL_SWITCHES};
    my $perl5opt = $ENV{PERL5OPT};
    my $loopname = $ENV{DEVELOPER_DASHBOARD_LOOP_NAME};
    my $loopstat = $ENV{DEVELOPER_DASHBOARD_LOOP_STATUS};

    # Tick with due=false: no worker spawned; effective interval equals the job
    # interval so configured_interval is omitted.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        ok(
            $runner->_run_loop_child( daemonize => 0, single_tick => 1, interval => 30, job => { command => 'true', cwd => $home, interval => 30 }, name => 'tick.notdue', schedule_mode => 'interval', title => 't' ),
            '_run_loop_child completes a non-due single tick',
        );
    }

    # Tick with a spawned worker (cron schedule drives the sleep-interval ternary).
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_start_loop_worker       = sub { return 777777 };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        ok(
            $runner->_run_loop_child( daemonize => 0, single_tick => 1, interval => 0, job => { command => 'true', cwd => $home }, name => 'tick.spawn', schedule_mode => 'cron', title => 't' ),
            '_run_loop_child spawns and records a worker on a due tick',
        );
    }

    # Tick where the worker start returns a falsy pid (no worker recorded).
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_start_loop_worker       = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        ok(
            $runner->_run_loop_child( daemonize => 0, single_tick => 1, interval => 0, job => { command => 'true', cwd => $home }, name => 'tick.noworker', schedule_mode => 'interval', title => 't' ),
            '_run_loop_child tolerates a worker start that yields no pid',
        );
    }

    # Tick that is due but already at capacity: the reaper pre-populates the
    # active set so the singleton capacity check declines to spawn.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub { my ( undef, $aw ) = @_; $aw->{424242} = 1; return 0 };
        local *Developer::Dashboard::CollectorRunner::_start_loop_worker       = sub { die "should not spawn at capacity\n" };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        ok(
            $runner->_run_loop_child( daemonize => 0, single_tick => 1, interval => 0, job => { command => 'true', cwd => $home, mode => 'singleton' }, name => 'tick.capacity', schedule_mode => 'interval', title => 't' ),
            '_run_loop_child declines to spawn when the singleton capacity is reached',
        );
    }

    # Tick where the worker start dies: exercises the error state write, with a
    # differing configured interval.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_start_loop_worker       = sub { die "forced worker start failure\n" };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        ok(
            $runner->_run_loop_child( daemonize => 0, single_tick => 1, interval => 0, job => { command => 'true', cwd => $home, interval => 5 }, name => 'tick.err.diff', schedule_mode => 'interval', title => 't' ),
            '_run_loop_child records an error state when a worker start dies (differing interval)',
        );
        is( $runner->loop_state('tick.err.diff')->{status}, 'error', '_run_loop_child persists the error status' );
    }

    # Error tick with a matching interval and defaulted title.
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_start_loop_worker       = sub { die "forced worker start failure\n" };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        ok(
            $runner->_run_loop_child( daemonize => 0, single_tick => 1, job => { command => 'true', cwd => $home, interval => 30 }, name => 'tick.err.same', schedule_mode => 'interval' ),
            '_run_loop_child records an error state when a worker start dies (matching interval, defaulted title)',
        );
    }

    $ENV{HARNESS_PERL_SWITCHES}              = $harness  if defined $harness;
    $ENV{PERL5OPT}                           = $perl5opt if defined $perl5opt;
    $ENV{DEVELOPER_DASHBOARD_LOOP_NAME}      = $loopname if defined $loopname;
    $ENV{DEVELOPER_DASHBOARD_LOOP_STATUS}    = $loopstat if defined $loopstat;
    delete $ENV{DEVELOPER_DASHBOARD_LOOP_NAME}   if !defined $loopname;
    delete $ENV{DEVELOPER_DASHBOARD_LOOP_STATUS} if !defined $loopstat;
}

# The CHLD handler guard: capture the installed handler during a tick, then
# invoke it with different signal globals to drive both its guard sides.
{
    my $harness  = $ENV{HARNESS_PERL_SWITCHES};
    my $perl5opt = $ENV{PERL5OPT};
    my $captured;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due              = sub { $captured = $SIG{CHLD}; return 0 };
        local *Developer::Dashboard::CollectorRunner::_sleep_until_next_tick   = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_settle_single_tick_workers = sub { return 1 };
        $runner->_run_loop_child( daemonize => 0, single_tick => 1, interval => 0, job => { command => 'true', cwd => $home }, name => 'tick.chld', schedule_mode => 'interval', title => 't' );
    }
    $ENV{HARNESS_PERL_SWITCHES} = $harness  if defined $harness;
    $ENV{PERL5OPT}              = $perl5opt if defined $perl5opt;
    ok( ref($captured) eq 'CODE', 'captured the loop CHLD handler installed during a tick' );

    no warnings 'redefine';
    my $reaped = 0;
    local *Developer::Dashboard::CollectorRunner::_reap_finished_loop_workers = sub { $reaped++; return 0 };
    {
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER = undef;
        $captured->();
    }
    {
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER       = $runner;
        local $Developer::Dashboard::CollectorRunner::SIGNAL_LOOP_WORKERS = 'not-a-hash';
        $captured->();
    }
    {
        local $Developer::Dashboard::CollectorRunner::SIGNAL_RUNNER       = $runner;
        local $Developer::Dashboard::CollectorRunner::SIGNAL_LOOP_WORKERS = {};
        $captured->();
    }
    is( $reaped, 1, 'the CHLD handler only reaps when a runner and worker hash are both present' );
}

# ===========================================================================
# _run_loop_child daemon path: successful single tick (fork), and the STDOUT
# reopen failure when the collector log path is a directory (fresh runtime).
# ===========================================================================
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 0 };
        my $ok = eval {
            $runner->_run_loop_child(
                single_tick   => 1,
                interval      => 1,
                job           => { command => 'true', cwd => $home },
                name          => 'daemon.tick',
                schedule_mode => 'interval',
                title         => $runner->_process_title('daemon.tick'),
            );
            1;
        };
        CORE::exit( $ok ? 0 : 1 );
    }
    waitpid( $child, 0 );
    is( $? >> 8, 0, '_run_loop_child completes a default-daemonized single tick and exits cleanly' );
}
{
    my $home2 = tempdir( CLEANUP => 1 );
    my $paths2 = Developer::Dashboard::PathRegistry->new( home => $home2, workspace_roots => [ File::Spec->catdir( $home2, 'workspace' ) ] );
    my $files2 = Developer::Dashboard::FileRegistry->new( paths => $paths2 );
    my $runner2 = Developer::Dashboard::CollectorRunner->new(
        collectors => Developer::Dashboard::Collector->new( paths => $paths2 ),
        files      => $files2,
        indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths2 ),
        paths      => $paths2,
    );
    make_path( $files2->collector_log );    # make the log path a directory so the append open fails

    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        open STDERR, '>', File::Spec->devnull();
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_job_is_due = sub { return 0 };
        my $died = eval {
            $runner2->_run_loop_child(
                daemonize     => 1,
                single_tick   => 1,
                interval      => 1,
                job           => { command => 'true', cwd => $home2 },
                name          => 'daemon.logfail',
                schedule_mode => 'interval',
                title         => $runner2->_process_title('daemon.logfail'),
            );
            0;
        } ? 0 : 1;
        open STDOUT, '>', File::Spec->devnull();
        CORE::exit( $died ? 3 : 0 );
    }
    waitpid( $child, 0 );
    is( $? >> 8, 3, '_run_loop_child dies in the daemon child when the collector log cannot be reopened for append' );
}

# ===========================================================================
# _start_loop_worker (Windows spawn + fork failure) and _run_loop_worker
# (setsid guard and the error-branch loop-state write).
# ===========================================================================
{
    my @spawned;
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows                     = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_windows_background_worker_command = sub { my ( undef, $name, $loop ) = @_; return ( 'perl.exe', $name, $loop ) };
    local *Developer::Dashboard::CollectorRunner::_spawn_windows_background_command = sub { shift; @spawned = @_; return 6262 };
    is( $runner->_start_loop_worker( { command => 'true' }, 'win.worker', 'title' ), 6262, '_start_loop_worker returns the detached Windows worker pid' );
    is_deeply( \@spawned, [ 'perl.exe', 'win.worker', $$ ], '_start_loop_worker forwards the Windows worker command' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::_fork_process = sub { return undef };
    like( ( eval { $runner->_start_loop_worker( { command => 'true' }, 'forkworker', 'title' ); 1 } ? '' : $@ ), qr/Unable to fork collector worker/, '_start_loop_worker dies when the worker fork fails' );
}

# _run_loop_worker error branch (run_once dies) with a supplied loop pid/title/schedule.
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        open STDERR, '>', File::Spec->devnull();
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::run_once = sub { die "worker body failure\n" };
        $runner->_run_loop_worker( { command => 'x', schedule => 'interval' }, 'worker.explicit', 'explicit-title', 4242 );
        CORE::exit(9);
    }
    waitpid( $child, 0 );
    is( $? >> 8, 255, '_run_loop_worker exits non-zero when the worker body dies (explicit identity)' );
    my $state = $runner->loop_state('worker.explicit');
    is( $state->{pid}, 4242, '_run_loop_worker records the supplied loop pid on failure' );
    is( $state->{process_name}, 'explicit-title', '_run_loop_worker records the supplied title on failure' );
}
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        open STDERR, '>', File::Spec->devnull();
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::run_once = sub { die "worker body failure\n" };
        $runner->_run_loop_worker( { command => 'x', interval => 5 }, 'worker.defaulted', undef, 0 );
        CORE::exit(9);
    }
    waitpid( $child, 0 );
    is( $? >> 8, 255, '_run_loop_worker exits non-zero when the worker body dies (defaulted identity)' );
    my $state = $runner->loop_state('worker.defaulted');
    ok( $state->{pid} > 0, '_run_loop_worker falls back to the current pid when no loop pid is supplied' );
    is( $state->{process_name}, $runner->_process_title('worker.defaulted'), '_run_loop_worker falls back to the process title when none is supplied' );
    is( $state->{schedule}, 'interval', '_run_loop_worker derives the schedule from the job when none is recorded' );
}
# _run_loop_worker on the Windows branch skips setsid before running.
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        open STDERR, '>', File::Spec->devnull();
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::is_windows = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::run_once   = sub { return {} };
        $runner->_run_loop_worker( { command => 'x' }, 'worker.windows', 'title', 5 );
        CORE::exit(9);
    }
    waitpid( $child, 0 );
    is( $? >> 8, 0, '_run_loop_worker skips setsid and exits cleanly on the Windows branch' );
}

# ===========================================================================
# _terminate_loop_workers: undef set default, and the Windows (no process-group
# kill) branch alongside the real POSIX group-kill branch.
# ===========================================================================
ok( $runner->_terminate_loop_workers(undef), '_terminate_loop_workers tolerates an undef worker set' );
{
    no warnings 'redefine';
    local *Developer::Dashboard::CollectorRunner::is_windows        = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_pid_is_running   = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::_reap_child_process = sub { return 1 };
    local *Developer::Dashboard::CollectorRunner::sleep             = sub { return 0 };
    my %active = ( 909090 => 1 );
    ok( $runner->_terminate_loop_workers( \%active ), '_terminate_loop_workers skips process-group kills on the Windows branch' );
    is_deeply( \%active, {}, '_terminate_loop_workers still clears the active set on the Windows branch' );
}
{
    # Real POSIX branch: a stubborn worker child that ignores SIGTERM.
    my $worker = fork();
    die "fork failed: $!" if !defined $worker;
    if ( !$worker ) {
        POSIX::setsid();
        $SIG{TERM} = 'IGNORE';
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    }
    select undef, undef, undef, 0.1;
    ok( $runner->_terminate_loop_workers( { $worker => 1 } ), '_terminate_loop_workers group-kills a stubborn worker on the POSIX branch' );
    kill 9, $worker;
    waitpid( $worker, 0 ) if kill 0, $worker;
}

# ===========================================================================
# stop_loop: missing pidfile, falsy recorded pid, and the managed/foreign/
# reaped/unrecognized branch matrix.
# ===========================================================================
ok( !defined $runner->stop_loop('stop.missing'), 'stop_loop returns undef with no pidfile' );
{
    my $pidfile = $runner->_pidfile('stop.zeropid');
    open my $fh, '>', $pidfile or die $!;
    print {$fh} "0\n";
    close $fh;
    is( $runner->stop_loop('stop.zeropid'), '0', 'stop_loop tolerates a zero recorded pid and returns it' );
}

# Live managed loop: full kill path (real POSIX group kill).
{
    my $name  = 'stop.managed.posix';
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        POSIX::setsid();
        $0 = $runner->_process_title($name);
        $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $name;
        $SIG{TERM} = 'DEFAULT';
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    }
    my $pidfile = $runner->_pidfile($name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $child;
    close $fh;
    $runner->_write_loop_state( $name, { pid => $child, name => $name, process_name => $runner->_process_title($name), status => 'running' } );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return $name };
        is( $runner->stop_loop($name), $child, 'stop_loop returns the pid of a managed loop it terminates' );
    }
    select undef, undef, undef, 0.2;
    ok( !kill( 0, $child ), 'stop_loop terminates the managed loop process' );
    waitpid( $child, 0 ) if kill 0, $child;
}

# Live managed loop under the Windows branch: no process-group kill.
{
    my $name  = 'stop.managed.windows';
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) {
        $0 = $runner->_process_title($name);
        $ENV{DEVELOPER_DASHBOARD_LOOP_NAME} = $name;
        $SIG{TERM} = 'DEFAULT';
        select undef, undef, undef, 30;
        POSIX::_exit(0);
    }
    my $pidfile = $runner->_pidfile($name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $child;
    close $fh;
    $runner->_write_loop_state( $name, { pid => $child, name => $name, process_name => $runner->_process_title($name), status => 'running' } );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::is_windows               = sub { return 1 };
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { return $name };
        is( $runner->stop_loop($name), $child, 'stop_loop returns the managed loop pid on the Windows branch' );
    }
    select undef, undef, undef, 0.2;
    kill 9, $child;
    waitpid( $child, 0 ) if kill 0, $child;
}

# Already-reaped loop child: the reap short-circuits the kill path.
{
    my $name  = 'stop.reaped';
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) { POSIX::_exit(0); }
    my $pidfile = $runner->_pidfile($name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $child;
    close $fh;
    $runner->_write_loop_state( $name, { pid => $child, name => $name, process_name => $runner->_process_title($name), status => 'running' } );
    select undef, undef, undef, 0.1;
    is( $runner->stop_loop($name), $child, 'stop_loop returns the pid of an already-exited loop it reaps' );
}

# Foreign-namespace loop: pid is alive but reported in another namespace.
{
    my $name  = 'stop.foreign';
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) { $SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 30; POSIX::_exit(0); }
    my $pidfile = $runner->_pidfile($name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $child;
    close $fh;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_same_pid_namespace = sub { return 0 };
        is( $runner->stop_loop($name), $child, 'stop_loop returns a foreign-namespace pid without signalling it' );
    }
    ok( kill( 0, $child ), 'stop_loop leaves a foreign-namespace loop running' );
    kill 9, $child;
    waitpid( $child, 0 ) if kill 0, $child;
}

# Unrecognized live loop with recorded worker pids: else-branch worker sweep.
{
    my $name  = 'stop.unrecognized';
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) { $SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 30; POSIX::_exit(0); }
    my $pidfile = $runner->_pidfile($name);
    open my $fh, '>', $pidfile or die $!;
    print {$fh} $child;
    close $fh;
    $runner->_write_loop_state( $name, { pid => $child, name => $name, process_name => 'unrelated-title', status => 'running', active_worker_pids => [ 2000000001 ] } );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker  = sub { return undef };
        local *Developer::Dashboard::CollectorRunner::_read_process_title       = sub { return 'unrelated-title' };
        local *Developer::Dashboard::CollectorRunner::_state_confirms_managed_loop = sub { return 0 };
        local *Developer::Dashboard::CollectorRunner::_terminate_loop_workers   = sub { return 1 };
        is( $runner->stop_loop($name), $child, 'stop_loop sweeps recorded workers for an unrecognized live loop' );
    }
    kill 9, $child;
    waitpid( $child, 0 ) if kill 0, $child;
}

# ===========================================================================
# running_loops: empty pidfile, reaped child, managed loop, foreign loop, and
# an unrecognized (swept) loop.
# ===========================================================================
{
    # Use a fresh runtime so the collectors root holds only these pidfiles and
    # every readdir branch/condition outcome is exercised deterministically.
    my $rl_home  = tempdir( CLEANUP => 1 );
    my $rl_paths = Developer::Dashboard::PathRegistry->new( home => $rl_home, workspace_roots => [ File::Spec->catdir( $rl_home, 'workspace' ) ] );
    my $rl_runner = Developer::Dashboard::CollectorRunner->new(
        collectors => Developer::Dashboard::Collector->new( paths => $rl_paths ),
        files      => Developer::Dashboard::FileRegistry->new( paths => $rl_paths ),
        indicators => Developer::Dashboard::IndicatorStore->new( paths => $rl_paths ),
        paths      => $rl_paths,
    );
    my $root = $rl_paths->collectors_root;

    # Empty pidfile -> skipped on the falsy-pid guard (slurps to undef).
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.empty.pid' ) or die $!; close $fh; }
    # "0\n" pidfile -> survives the pre-chomp guard, chomps to the falsy "0".
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.zero.pid' ) or die $!; print {$fh} "0\n"; close $fh; }

    # Reaped (exited, unwaited) child -> reaped and cleaned up.
    my $reaped = fork();
    die "fork failed: $!" if !defined $reaped;
    if ( !$reaped ) { POSIX::_exit(0); }
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.reaped.pid' ) or die $!; print {$fh} $reaped; close $fh; }
    select undef, undef, undef, 0.1;

    # Live loop recognized by process identity -> reported.
    my $managed = fork();
    die "fork failed: $!" if !defined $managed;
    if ( !$managed ) { $SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 30; POSIX::_exit(0); }
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.managed.pid' ) or die $!; print {$fh} $managed; close $fh; }

    # Live loop recognized only by recorded state (process identity unavailable).
    my $confirmed = fork();
    die "fork failed: $!" if !defined $confirmed;
    if ( !$confirmed ) { $SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 30; POSIX::_exit(0); }
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.confirmed.pid' ) or die $!; print {$fh} $confirmed; close $fh; }
    $rl_runner->_write_loop_state( 'rl.confirmed', { pid => $confirmed, name => 'rl.confirmed', process_name => $rl_runner->_process_title('rl.confirmed'), status => 'running' } );

    # Unrecognized same-namespace live loop -> pidfile swept.
    my $unrec = fork();
    die "fork failed: $!" if !defined $unrec;
    if ( !$unrec ) { $SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 30; POSIX::_exit(0); }
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.unrec.pid' ) or die $!; print {$fh} $unrec; close $fh; }

    # Foreign-namespace live loop -> skipped without cleanup.
    my $foreign = fork();
    die "fork failed: $!" if !defined $foreign;
    if ( !$foreign ) { $SIG{TERM} = 'DEFAULT'; select undef, undef, undef, 30; POSIX::_exit(0); }
    { open my $fh, '>', File::Spec->catfile( $root, 'rl.foreign.pid' ) or die $!; print {$fh} $foreign; close $fh; }

    my %by_name;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CollectorRunner::_read_process_env_marker = sub { my ( undef, $pid ) = @_; return $pid == $managed ? 'rl.managed' : undef };
        local *Developer::Dashboard::CollectorRunner::_read_process_title      = sub { my ( undef, $pid ) = @_; return $pid == $managed ? $rl_runner->_process_title('rl.managed') : 'other-title' };
        local *Developer::Dashboard::CollectorRunner::_same_pid_namespace      = sub { my ( undef, $pid ) = @_; return $pid == $foreign ? 0 : 1 };
        %by_name = map { $_->{name} => $_ } $rl_runner->running_loops;
    }
    ok( $by_name{'rl.managed'},   'running_loops reports a process-identity managed loop' );
    ok( $by_name{'rl.confirmed'}, 'running_loops reports a state-confirmed loop when process identity is unavailable' );
    ok( !$by_name{'rl.unrec'},    'running_loops drops an unrecognized same-namespace loop' );
    ok( -f File::Spec->catfile( $root, 'rl.empty.pid' ),   'running_loops skips an empty pidfile on the falsy-pid guard' );
    ok( -f File::Spec->catfile( $root, 'rl.foreign.pid' ), 'running_loops leaves a foreign-namespace pidfile in place' );
    ok( !-f File::Spec->catfile( $root, 'rl.unrec.pid' ),  'running_loops sweeps the pidfile of an unrecognized loop' );
    ok( !-f File::Spec->catfile( $root, 'rl.zero.pid' ),   'running_loops sweeps a pidfile that chomps to a falsy zero pid' );

    for my $pid ( $managed, $confirmed, $unrec, $foreign ) { kill 9, $pid; waitpid( $pid, 0 ) if kill 0, $pid; }
}

# ===========================================================================
# _shutdown_loop: falsy and truthy status, with and without a worker set.
# ===========================================================================
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) { $runner->_shutdown_loop( 'shutdown.default', '', undef ); CORE::exit(9); }
    waitpid( $child, 0 );
    is( $? >> 8, 0, '_shutdown_loop defaults a falsy status to stopped and exits cleanly' );
}
{
    my $child = fork();
    die "fork failed: $!" if !defined $child;
    if ( !$child ) { $runner->_shutdown_loop( 'shutdown.crashed', 'crashed', {} ); CORE::exit(9); }
    waitpid( $child, 0 );
    is( $? >> 8, 0, '_shutdown_loop honors an explicit status and terminates the worker set' );
}

done_testing;

__END__

=head1 NAME

t/103-collectorrunner-coverage.t - branch and condition closure for the collector runner

=head1 PURPOSE

This file is the executable branch-and-condition coverage contract for
C<Developer::Dashboard::CollectorRunner>. It drives every remaining
partially-covered decision in the collector execution and loop-management
runtime: cwd and schedule resolution in C<run_once>, indicator template
materialization, collector-source and execution-policy normalization, interval
and cron scheduling, process-identity and namespace probing, loop pidfile and
state lifecycle, the daemonized child and worker fork paths, the Windows
detached-launch and PowerShell state-replacement fallbacks, and the timeout and
chdir-restore error paths in the command and code executors.

=head1 WHY IT EXISTS

The collector runner concentrates a large amount of process-lifecycle and
platform-conditional logic whose failure and fallback arms are invisible to the
broader runtime suites, which carry heavy setup and monkey-patched state. Those
arms are exactly where a regression silently orphans a worker, mis-reports a
timeout, or breaks a Windows launch. This file pins each decision in isolation
so the coverage gate stays honest and a regression surfaces immediately, with a
minimal, targeted reproduction per behavior.

=head1 WHEN TO USE

Run it whenever you change collector process spawning, pid validation, loop
state persistence, cron or interval scheduling, indicator icon rendering, the
Windows detached-launch and state-replacement fallbacks, or the command and
code timeout handling. It is the first check to run when touching C<run_once>,
C<start_loop>, C<stop_loop>, C<running_loops>, C<_run_loop_child>,
C<_run_loop_worker>, or the private state-file and process-probe helpers.

=head1 HOW TO USE

Run it directly while iterating:

  perl -Ilib t/103-collectorrunner-coverage.t

Run it under the repository coverage gate when closing the library coverage:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/103-collectorrunner-coverage.t

Several checks fork managed loop and worker children, install real pidfiles and
loop-state files under a throwaway HOME, and reap the children afterward. Others
mock the platform predicate, the capture helper, or the fork and rename
primitives so the Windows and failure arms run deterministically on a Linux
host.

=head1 WHAT USES IT

This is a standalone author regression test for
C<Developer::Dashboard::CollectorRunner>. It is exercised by C<prove -lr t> and
by the repository coverage gate; nothing in the shipped library depends on it.

=head1 EXAMPLES

Drive only this file with verbose output while iterating on a fix:

  prove -lv t/103-collectorrunner-coverage.t

Confirm the collector runner still reads clean under the all-metric coverage
gate after a change:

  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t
  cover -report text -select_re '^lib/' -coverage branch -coverage condition

=cut
