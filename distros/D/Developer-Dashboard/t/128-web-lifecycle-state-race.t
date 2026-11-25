#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use Test::More;
use Time::HiRes qw(sleep time);

use lib 'lib';
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::RuntimeManager;
use Developer::Dashboard::GoRoutine ();

# Hermetic runtime: the state root resolves from the deepest .developer-dashboard
# layer at or above the CWD, so the temp home must also be the working directory.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $store  = Developer::Dashboard::Collector->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $store,
    config     => $config,
    files      => $files,
    paths      => $paths,
);
my $manager = Developer::Dashboard::RuntimeManager->new(
    app_builder => sub { die "app_builder must not be reached by this test\n" },
    config      => $config,
    files       => $files,
    paths       => $paths,
    runner      => $runner,
);

# capture_warnings($code)
# Runs one code reference with warnings collected instead of printed, because
# lifecycle reads must stay warning-free under this project's warnings-are-errors
# rule.
# Input: code reference.
# Output: two-element list of the code result and an array reference of warnings.
sub capture_warnings {
    my ($code) = @_;
    my @seen;
    my $result;
    {
        local $SIG{__WARN__} = sub { push @seen, $_[0] };
        $result = $code->();
    }
    return ( $result, \@seen );
}

# spawn_managed_web()
# Starts a second process that looks exactly like a managed dashboard web
# service: it carries the "d2 web: HOST:PORT" process title and holds a
# real TCP listener on the reported port. A readiness file replaces the
# inherited pipe so the fixture uses the same native process API on every OS.
# The port is picked here, not inside the child: Windows has no getppid(),
# and a $0 assignment never rewrites the Windows launch command line, so the
# endpoint must already be literal in the spawned arguments for the lifecycle
# to recover it from the process table there. The parent pid travels as an
# argument for the same reason - the child watches it with kill 0 instead of
# getppid(), which Strawberry Perl does not implement (it dies with "The
# getppid function is unimplemented"). The child still reports the port it
# actually bound through the readiness file, so the contract is unchanged.
# Input: none.
# Output: two-element list of the child process id and the bound port.
sub spawn_managed_web {
    my $probe_socket = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', ReuseAddr => 1,
    ) or die "Unable to reserve a managed web stand-in port: $!";
    my $web_port_hint = $probe_socket->sockport;
    close $probe_socket or die "Unable to close the stand-in port probe: $!";
    my $scratch = tempdir( 'dd-web-race-XXXXXX', CLEANUP => 1, TMPDIR => 1 );
    my $port_file = File::Spec->catfile( $scratch, 'bound-port' );
    my $stdout_file = File::Spec->catfile( $scratch, 'child.stdout' );
    my $stderr_file = File::Spec->catfile( $scratch, 'child.stderr' );
    my $script = q{
        my ($ready_file, $parent_pid) = @ARGV;
        my $socket = IO::Socket::INET->new(
            Listen => 5, LocalAddr => '127.0.0.1', LocalPort => __WEB_PORT__,
            Proto => 'tcp', ReuseAddr => 1,
        ) or die "Unable to bind managed web stand-in: $!";
        my $bound = $socket->sockport;
        $0 = "d2 web: 0.0.0.0:__WEB_PORT__";
        open my $ready_fh, '>', $ready_file or die "Unable to create readiness file: $!";
        print {$ready_fh} "$bound\n" or die "Unable to write bound port: $!";
        close $ready_fh or die "Unable to close readiness file: $!";
        # 300 seconds of parent-watch budget: the file takes longer than the
        # old 30-second budget on Windows, where every process-table scan
        # costs a PowerShell launch, and the direct endpoint-recovery
        # checks below need the stand-in alive to the end of the file.
        for (1 .. 3000) {
            exit 0 if !kill 0, $parent_pid;
            Time::HiRes::sleep(0.1);
        }
        exit 0;
    };
    $script =~ s/__WEB_PORT__/$web_port_hint/g;
    my $child = Developer::Dashboard::GoRoutine::spawn(
        [ $^X, '-MIO::Socket::INET', '-MTime::HiRes', '-e', $script, $port_file, $$ ],
        { stdout => $stdout_file, stderr => $stderr_file },
    );
    my $deadline = time() + 5;
    my $line;
    while ( time() < $deadline ) {
        if ( open my $reader, '<', $port_file ) {
            $line = <$reader>;
            close $reader or die "Unable to close $port_file: $!";
            last if defined $line && $line =~ /\A\d+\s*\z/;
        }
        if ( Developer::Dashboard::GoRoutine::process_exited($child) ) {
            my $exit = Developer::Dashboard::GoRoutine::wait_process($child);
            open my $error_fh, '<', $stderr_file or die "Managed web stand-in exited $exit; cannot read $stderr_file: $!";
            my $error = do { local $/; <$error_fh> } // '';
            close $error_fh or die "Unable to close $stderr_file: $!";
            die "Managed web stand-in exited $exit before readiness: $error";
        }
        sleep 0.02;
    }
    if ( !defined $line || $line !~ /\A\d+\s*\z/ ) {
        Developer::Dashboard::GoRoutine::terminate_process( $child, 'KILL' );
        Developer::Dashboard::GoRoutine::wait_process($child);
        open my $error_fh, '<', $stderr_file or die "the managed web stand-in never reported its port; cannot read $stderr_file: $!";
        my $error = do { local $/; <$error_fh> } // '';
        close $error_fh or die "Unable to close $stderr_file: $!";
        die "the managed web stand-in never reported its port: $error";
    }
    chomp $line;
    return ( $child, $line + 0 );
}

my ( $web_pid, $web_port ) = spawn_managed_web();

# persist_running_state(%payload)
# Persists one web state payload plus the matching pid file, the way a real
# background start records a running service.
# Input: state payload key/value pairs.
# Output: true value.
sub persist_running_state {
    my (%payload) = @_;
    $manager->_write_web_state( \%payload );
    $files->write( 'web_pid', "$web_pid\n" );
    return 1;
}

# open_replace_window()
# Reproduces the observable window in which an existing state file is
# zero-length, which is what a concurrent reader can catch during a
# write-and-replace.
# Input: none.
# Output: true value.
sub open_replace_window {
    open my $fh, '>:raw', $files->web_state or die 'Unable to truncate the web state file: ' . $!;
    close $fh or die 'Unable to close the truncated web state file: ' . $!;
    return 1;
}

# attempt_background_start(%args)
# Runs a background start with the native launcher replaced by a recorder, so a
# deduplicated start can be told apart from one that would spawn a second
# listener.
# Input: host, port, and worker count for the start request.
# Output: hash reference with the returned pid, native launch attempt count, error text,
# and collected warnings.
sub attempt_background_start {
    my (%args) = @_;
    my $launches = 0;
    my $error = '';
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_start_web_background = sub {
        $launches++;
        die "duplicate web start attempted\n";
    };
    my ( $pid, $warnings ) = capture_warnings(
        sub {
            my $result = eval { $manager->start_web(%args) };
            $error = $@;
            return $result;
        }
    );
    return {
        error    => $error,
        launches => $launches,
        pid      => $pid,
        warnings => $warnings,
    };
}

# complete_state()
# Returns the payload a healthy background start persists for the stand-in
# server.
# Input: none.
# Output: state payload hash.
sub complete_state {
    return (
        host         => '0.0.0.0',
        pid          => $web_pid,
        port         => $web_port,
        process_name => "d2 web: 0.0.0.0:$web_port",
        started_at   => '2026-07-30T00:00:00Z',
        status       => 'running',
        workers      => 1,
        ssl          => 0,
    );
}

# A complete payload is the baseline: the endpoint is reported and nothing warns.
persist_running_state( complete_state() );
my ( $baseline, $baseline_warnings ) = capture_warnings( sub { return $manager->running_web } );
is( $baseline->{pid},  $web_pid,  'running_web reports the live managed pid for a complete payload' );
is( $baseline->{host}, '0.0.0.0', 'running_web reports the persisted host for a complete payload' );
is( $baseline->{port}, $web_port, 'running_web reports the persisted port for a complete payload' );
is_deeply( $baseline_warnings, [], 'running_web is warning-free for a complete payload' );

# A payload with no endpoint is what the shutdown writer persists when the state
# file was removed under a still-running server. The endpoint is still knowable
# from the live process title, so running_web must never answer with a shape the
# start path cannot compare.
persist_running_state( pid => $web_pid, status => 'stopped', updated_at => '2026-07-30T00:00:01Z' );
my ( $endpointless, $endpointless_warnings ) = capture_warnings( sub { return $manager->running_web } );
ok( $endpointless, 'running_web still reports the live managed web process for a payload with no endpoint' );
is( $endpointless->{pid},  $web_pid,  'running_web keeps the live managed pid for a payload with no endpoint' );
is( $endpointless->{host}, '0.0.0.0', 'running_web recovers the host from the live managed process title' );
is( $endpointless->{port}, $web_port, 'running_web recovers the port from the live managed process title' );
is_deeply( $endpointless_warnings, [], 'running_web is warning-free for a payload with no endpoint' );

# The start path must recognize that recovered endpoint as the requested service:
# starting a second listener strands the first process as an untrackable orphan.
{
    my $attempt = attempt_background_start( host => '0.0.0.0', port => $web_port, workers => 1 );
    is( $attempt->{pid},   $web_pid, 'start_web deduplicates the running service when the persisted payload carries no endpoint' );
    is( $attempt->{launches}, 0,     'start_web launches no duplicate web child when the running service already satisfies the request' );
    is( $attempt->{error}, '',       'start_web returns the running pid instead of failing on a duplicate start' );
    is_deeply( $attempt->{warnings}, [], 'the start_web dedup comparison never warns about an incomplete payload' );
}
ok( -f $files->web_state, 'a deduplicated start leaves the running web state file in place' );
ok( -f $files->web_pid,   'a deduplicated start leaves the running web pid file in place' );

# Same contract while the state file is observable as zero-length.
persist_running_state( complete_state() );
open_replace_window();
{
    my $attempt = attempt_background_start( host => '0.0.0.0', port => $web_port, workers => 1 );
    is( $attempt->{pid},   $web_pid, 'start_web deduplicates the running service while the state file is mid-replace' );
    is( $attempt->{launches}, 0,     'start_web launches no duplicate web child while the state file is mid-replace' );
    is_deeply( $attempt->{warnings}, [], 'the start_web dedup comparison never warns during the replace window' );
}

# An unreadable state file is evidence of nothing: a lifecycle probe must not
# delete the persisted files of a server it merely failed to observe.
persist_running_state( complete_state() );
open_replace_window();
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_is_managed_web         = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes     = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_for_port = sub { return () };
    my ( $unresolved, $unresolved_warnings ) = capture_warnings( sub { return $manager->running_web } );
    ok( !defined $unresolved, 'running_web reports no service when every probe misses and the state file is unreadable' );
    is_deeply( $unresolved_warnings, [], 'running_web is warning-free when every probe misses' );
}
ok( -f $files->web_state, 'running_web keeps a state file it could not read' );
ok( -f $files->web_pid,   'running_web keeps the pid file when the state file could not be read' );
ok( Developer::Dashboard::GoRoutine::process_running($web_pid), 'the managed web stand-in is still running after the failed probe' );

# A confirmed-stopped service is still cleaned up: the tolerance above must not
# turn into stale state that never gets reclaimed.
persist_running_state( complete_state() );
{
    no warnings 'redefine';
    local *Developer::Dashboard::RuntimeManager::_pid_is_running           = sub { return 0 };
    local *Developer::Dashboard::RuntimeManager::_find_web_processes       = sub { return () };
    local *Developer::Dashboard::RuntimeManager::_listener_pids_from_state = sub { return () };
    ok( !defined $manager->running_web, 'running_web reports no service for a confirmed-stopped pid' );
}
ok( !-f $files->web_state, 'running_web removes the state file of a confirmed-stopped service' );
ok( !-f $files->web_pid,   'running_web removes the pid file of a confirmed-stopped service' );

# Direct contract for the settled read, so every outcome a lifecycle caller can
# hit is pinned rather than only reached through running_web.
{
    my ( $absent_state, $absent_unresolved ) = $manager->_read_settled_web_state;
    ok( !defined $absent_state, '_read_settled_web_state reports no state when no state file exists' );
    ok( !$absent_unresolved,    '_read_settled_web_state treats a missing state file as resolved' );

    $manager->_write_web_state( { host => 'h', port => 1, status => 'running' } );
    my ( $good_state, $good_unresolved ) = $manager->_read_settled_web_state;
    is( $good_state->{status}, 'running', '_read_settled_web_state returns a complete payload' );
    ok( !$good_unresolved, '_read_settled_web_state treats a complete payload as resolved' );

    open_replace_window();
    my ( $empty_state, $empty_unresolved ) = $manager->_read_settled_web_state;
    ok( !defined $empty_state, '_read_settled_web_state reports no state for a file that never becomes readable' );
    ok( $empty_unresolved,     '_read_settled_web_state flags a present but unreadable state file as unresolved' );

    no warnings 'redefine';
    my $reads = 0;
    local *Developer::Dashboard::RuntimeManager::web_state = sub {
        $reads++;
        return if $reads < 2;
        return { host => 'settled', port => 2, status => 'running' };
    };
    my ( $settled_state, $settled_unresolved ) = $manager->_read_settled_web_state;
    is( $settled_state->{host}, 'settled', '_read_settled_web_state re-reads a state file caught mid-replace' );
    ok( !$settled_unresolved, '_read_settled_web_state treats a settled re-read as resolved' );
}

# Direct contract for the endpoint recovery, including the shapes where the
# process title cannot supply an endpoint.
{
    my $kept = $manager->_web_state_with_endpoint( { host => 'kept', port => 9 }, $web_pid );
    is( $kept->{host}, 'kept', '_web_state_with_endpoint keeps a persisted host' );
    is( $kept->{port}, 9,      '_web_state_with_endpoint keeps a persisted port' );
    is( $kept->{pid},  $web_pid, '_web_state_with_endpoint reports the live pid' );

    my $port_only = $manager->_web_state_with_endpoint( { host => 'kept' }, $web_pid );
    is( $port_only->{host}, 'kept',    '_web_state_with_endpoint keeps a persisted host when only the port is missing' );
    is( $port_only->{port}, $web_port, '_web_state_with_endpoint recovers a missing port from the process title' );

    my $host_only = $manager->_web_state_with_endpoint( { port => 9 }, $web_pid );
    is( $host_only->{host}, '0.0.0.0', '_web_state_with_endpoint recovers a missing host from the process title' );
    is( $host_only->{port}, 9,         '_web_state_with_endpoint keeps a persisted port when only the host is missing' );

    no warnings 'redefine';
    {
        local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return };
        my $untitled = $manager->_web_state_with_endpoint( { status => 'running' }, $web_pid );
        is( $untitled->{pid}, $web_pid, '_web_state_with_endpoint still reports the live pid without a readable title' );
        ok( !defined $untitled->{host}, '_web_state_with_endpoint invents no host when the title is unreadable' );
    }
    {
        local *Developer::Dashboard::RuntimeManager::_read_process_title = sub { return 'starman master' };
        my $foreign = $manager->_web_state_with_endpoint( { status => 'running' }, $web_pid );
        ok( !defined $foreign->{port}, '_web_state_with_endpoint invents no port from a non-dashboard title' );
    }
}

# Direct contract for the dedup comparison: every mismatch reason, and no
# uninitialized-value warning for any incomplete shape.
{
    my %complete = ( host => '0.0.0.0', port => 7890, workers => 2, ssl => 1 );
    my ( $matches, $match_warnings ) = capture_warnings(
        sub { return $manager->_running_web_satisfies_request( { %complete }, '0.0.0.0', 7890, 2, 1 ) } );
    ok( $matches, '_running_web_satisfies_request accepts an identical running configuration' );
    is_deeply( $match_warnings, [], '_running_web_satisfies_request is warning-free for a complete shape' );

    my @mismatches = (
        [ { %complete, host => undef }, 'a missing host' ],
        [ { %complete, port => undef }, 'a missing port' ],
        [ { %complete, host => '127.0.0.1' }, 'a different host' ],
        [ { %complete, port => 7891 }, 'a different port' ],
        [ { %complete, workers => 3 }, 'a different worker count' ],
        [ { %complete, ssl => 0 }, 'a different ssl mode' ],
    );
    for my $case (@mismatches) {
        my ( $running, $label ) = @{$case};
        my ( $result, $warnings ) = capture_warnings(
            sub { return $manager->_running_web_satisfies_request( $running, '0.0.0.0', 7890, 2, 1 ) } );
        ok( !$result, "_running_web_satisfies_request rejects $label" );
        is_deeply( $warnings, [], "_running_web_satisfies_request stays warning-free for $label" );
    }

    my $unverifiable = $manager->_running_web_satisfies_request( { host => '0.0.0.0', port => 7890 }, '0.0.0.0', 7890, 4, 1 );
    ok(
        $unverifiable,
        '_running_web_satisfies_request treats a property the payload does not carry as unverifiable rather than different',
    );
}

Developer::Dashboard::GoRoutine::terminate_process( $web_pid, 'KILL' );
Developer::Dashboard::GoRoutine::wait_process($web_pid);

done_testing;

__END__

=pod

=head1 NAME

t/128-web-lifecycle-state-race.t - web lifecycle contracts for incomplete runtime state

=head1 PURPOSE

This test is the executable contract that the web lifecycle never acts
destructively on incomplete evidence. It runs a second process that looks
exactly like a managed dashboard web service - the real process title plus a
real TCP listener - and then asks the runtime manager what is running while the
persisted state is missing its endpoint, is observable as zero-length, or cannot
be read at all. The runtime manager must report the live service with a
comparable endpoint, deduplicate a background start instead of launching a
second listener, keep persisted files it could not read, and still reclaim the
files of a confirmed-stopped service.

=head1 WHY IT EXISTS

Under full-suite load the runtime-manager suite failed with a duplicated web
start: the persisted payload carried no host, the start path compared that
undefined host against the requested one, warned, decided the request did not
match, deleted the running server's pid and state files, and started a second
listener that stranded the first process as an orphan. A two-process reproduction
showed two independent ways to reach that payload - the write-and-replace window
that makes an existing state file briefly unreadable, and a shutdown write that
persists a pid and status with no endpoint - so the fix belongs in the lifecycle
contract rather than in the assertion that caught it.

=head1 WHEN TO USE

Use this file when changing background web start, the running-service probe,
persisted web state, or any lifecycle path that decides whether a service is
already up.

=head1 HOW TO USE

Run C<d2 docker compose exec dev prove -blv
t/128-web-lifecycle-state-race.t> while iterating on the web lifecycle. The test
is hermetic - it builds its own temporary home, state root, and GoRoutine-spawned
stand-in web process - so it can run repeatedly without touching a real runtime.
Keep it green under C<d2 docker compose exec dev prove -blr t> and the all-metric
coverage gate before release, and run it together with C<d2 docker compose exec
dev prove -blv t/09-runtime-manager.t> whenever the start or probe paths change.

=head1 WHAT USES IT

Developers during TDD on the runtime lifecycle, the repository test suite, and
the coverage gate use this file to keep web start deduplication and state
cleanup safe against incomplete observations.

=head1 EXAMPLES

Example 1:

  d2 docker compose exec dev prove -blv t/128-web-lifecycle-state-race.t

Run the web lifecycle state contract by itself.

Example 2:

  d2 docker compose exec dev prove -blv t/09-runtime-manager.t t/128-web-lifecycle-state-race.t

Run it beside the full runtime-manager suite after changing start_web or
running_web.

=cut
