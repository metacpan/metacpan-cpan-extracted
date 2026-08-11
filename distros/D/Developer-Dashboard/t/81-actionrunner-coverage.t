#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Codec qw(encode_payload);
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PathRegistry;

# Hermetic runtime rooted at a throwaway home. The runtime root resolves from the
# deepest .developer-dashboard layer discovered from the current working
# directory, so the test must chdir into the temp home before building objects.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $runner = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

my $background_wait_loops = $INC{'Devel/Cover.pm'} ? 600 : 40;

# wait_for_pid_exit($pid)
# Purpose: block until a background action wrapper pid stops so the detached
# child flushes its coverage before the test process ends.
# Input: process id integer.
# Output: none.
sub wait_for_pid_exit {
    my ($pid) = @_;
    for ( 1 .. $background_wait_loops ) {
        last if !$runner->_pid_is_running($pid);
        select undef, undef, undef, 0.1;
    }
    return;
}

# ---------------------------------------------------------------------------
# new(): both registry guards must reject a missing dependency (line 24, 25).
# ---------------------------------------------------------------------------
{
    my $no_files = eval { Developer::Dashboard::ActionRunner->new( paths => $paths ); 1 };
    ok( !$no_files, 'new() rejects a missing file registry' );
    like( $@, qr/Missing file registry/, 'new() reports the missing file registry' );

    my $no_paths = eval { Developer::Dashboard::ActionRunner->new( files => $files ); 1 };
    ok( !$no_paths, 'new() rejects a missing path registry' );
    like( $@, qr/Missing path registry/, 'new() reports the missing path registry' );

    isa_ok( $runner, 'Developer::Dashboard::ActionRunner', 'new() builds a runner with both registries' );
}

# ---------------------------------------------------------------------------
# run_page_action(): page/action guards and source/kind defaults
# (lines 38, 39, 40, 43).
# ---------------------------------------------------------------------------
my $source_page = Developer::Dashboard::PageDocument->new(
    id     => 'source-page',
    title  => 'Source Page',
    layout => { body => 'body' },
);
{
    my $no_page = eval { $runner->run_page_action( action => { builtin => 'page.source' } ); 1 };
    ok( !$no_page, 'run_page_action() rejects a missing page' );
    like( $@, qr/Missing page/, 'run_page_action() reports the missing page' );

    my $no_action = eval { $runner->run_page_action( page => $source_page ); 1 };
    ok( !$no_action, 'run_page_action() rejects a missing action' );
    like( $@, qr/Missing action/, 'run_page_action() reports the missing action' );

    # No source argument -> defaults to 'saved' (line 40 default); no kind key ->
    # defaults to 'builtin' (line 43 default).
    my $defaulted = $runner->run_page_action(
        page   => $source_page,
        action => { builtin => 'page.source' },
    );
    is( $defaulted->{kind}, 'builtin', 'run_page_action() defaults an action with no source or kind to a builtin' );
    like( $defaulted->{body}, qr/Source Page/, 'defaulted builtin action returns the page source' );
}

# ---------------------------------------------------------------------------
# run_page_action(): a command action with an explicit trusted source runs
# (source present -> line 40 left-true; kind present -> line 43 left-true).
# ---------------------------------------------------------------------------
{
    my $marker  = File::Spec->catfile( $home, 'run-page-command.marker' );
    my $command = {
        id      => 'run',
        kind    => 'command',
        command => qq{printf ok > "$marker"},
        cwd     => $home,
    };
    my $result = $runner->run_page_action(
        action => $command,
        page   => $source_page,
        source => 'saved',
    );
    is( $result->{exit_code}, 0, 'trusted saved-source command action executes' );
    ok( -e $marker, 'trusted saved-source command action produced its side effect' );
}

# ---------------------------------------------------------------------------
# run_page_action(): an untrusted command action is rejected, and an
# unsupported kind dies (exercises the trust and kind-routing branches).
# ---------------------------------------------------------------------------
{
    my $rejected = eval {
        $runner->run_page_action(
            action => { id => 'x', kind => 'command', command => 'true', cwd => $home },
            page   => Developer::Dashboard::PageDocument->new( id => 'p', title => 'P', layout => { body => 'b' } ),
            source => 'transient',
        );
        1;
    };
    ok( !$rejected, 'run_page_action() rejects an untrusted transient command action' );
    like( $@, qr/is not trusted/, 'untrusted command rejection explains the policy' );

    my $bad_kind = eval {
        $runner->run_page_action(
            action => { id => 'z', kind => 'mystery' },
            page   => $source_page,
            source => 'saved',
        );
        1;
    };
    ok( !$bad_kind, 'run_page_action() rejects an unsupported action kind' );
    like( $@, qr/Unsupported action kind/, 'unsupported kind rejection explains the policy' );
}

# ---------------------------------------------------------------------------
# encode_action_payload(): page/action guards (line 73, 74) and the canonical
# instruction, source, and action-id defaults (line 84).
# ---------------------------------------------------------------------------
{
    my $no_page = eval { $runner->encode_action_payload( action => { id => 'a' } ); 1 };
    ok( !$no_page, 'encode_action_payload() rejects a missing page' );
    like( $@, qr/Missing page/, 'encode_action_payload() reports the missing page' );

    my $no_action = eval { $runner->encode_action_payload( page => $source_page ); 1 };
    ok( !$no_action, 'encode_action_payload() rejects a missing action' );
    like( $@, qr/Missing action/, 'encode_action_payload() reports the missing action' );

    # A real page with canonical_instruction and full source/id keys covers the
    # can()/||-true sides.
    my $encoded = $runner->encode_action_payload(
        page   => $source_page,
        action => { id => 'full', builtin => 'page.source' },
        source => 'saved',
    );
    ok( length $encoded, 'encode_action_payload() returns a token for a full page' );

    # A page object that lacks canonical_instruction, with no source argument and
    # an action with no id, drives the can()-false ternary and the ||-false
    # defaults (line 84).
    my $bare_encoded = $runner->encode_action_payload(
        page   => Local::NoInstructionPage->new,
        action => { builtin => 'page.source' },
    );
    ok( length $bare_encoded, 'encode_action_payload() falls back cleanly for a page without a canonical instruction' );
}

# ---------------------------------------------------------------------------
# run_encoded_action(): token default (line 110) and the command-refusal guard
# (line 127) across hash, non-hash, and command actions.
# ---------------------------------------------------------------------------
{
    # The decoded page source must name at least one section, so every hand-built
    # token carries a real page instruction.
    my $page_src = $source_page->canonical_instruction;

    # No token argument -> defaults to '' (line 110 left-false); the empty token
    # then fails to decode, which is the expected refusal.
    my $no_token = eval { $runner->run_encoded_action(); 1 };
    ok( !$no_token, 'run_encoded_action() rejects a missing token' );

    # A hash builtin action with no kind key -> the kind defaults to 'builtin'
    # (line 127 kind default) and executes instead of being refused.
    my $builtin_token = encode_payload(
        json_encode(
            {
                version     => 1,
                source      => 'saved',
                page_source => $page_src,
                action      => { id => 'state', builtin => 'page.state' },
            }
        )
    );
    my $builtin_result = $runner->run_encoded_action( token => $builtin_token );
    is( ref($builtin_result), 'HASH', 'run_encoded_action() executes a builtin action carried over the encoded transport' );

    # A command action over the encoded transport is refused (line 127 die side).
    my $command_token = encode_payload(
        json_encode(
            {
                version     => 1,
                source      => 'saved',
                page_source => $page_src,
                action      => { id => 'run', kind => 'command', command => 'true' },
            }
        )
    );
    my $ran_command = eval { $runner->run_encoded_action( token => $command_token ); 1 };
    ok( !$ran_command, 'run_encoded_action() refuses a command action over the encoded transport' );
    like( $@, qr/Command actions cannot be executed/, 'encoded command refusal explains the policy' );

    # A non-hash action -> ref() is not HASH (line 127 left-false) and routes into
    # the normal page-action validation instead.
    my $array_token = encode_payload(
        json_encode( { version => 1, source => 'saved', page_source => $page_src, action => [ 1, 2 ] } )
    );
    my $ran_array = eval { $runner->run_encoded_action( token => $array_token ); 1 };
    ok( !$ran_array, 'run_encoded_action() rejects a non-hash encoded action' );
}

# ---------------------------------------------------------------------------
# run_command_action(): command guard (line 143) and cwd resolution branches
# (lines 144, 145).
# ---------------------------------------------------------------------------
{
    my $no_command = eval { $runner->run_command_action( cwd => $home ); 1 };
    ok( !$no_command, 'run_command_action() rejects a missing command' );
    like( $@, qr/Missing command/, 'run_command_action() reports the missing command' );

    # Absolute cwd -> file_name_is_absolute true (line 145 left-false).
    my $absolute = $runner->run_command_action( command => 'true', cwd => $home );
    is( $absolute->{exit_code}, 0, 'run_command_action() runs with an absolute cwd' );

    # No cwd -> defaults to cwd() (line 144 left-false-right-true); the current
    # directory is the temp home, which exists.
    my $defaulted_cwd = $runner->run_command_action( command => 'true' );
    is( $defaulted_cwd->{exit_code}, 0, 'run_command_action() defaults the cwd to the current directory' );

    # Relative cwd that names a path-registry method (line 145 left-true-right-true).
    my $relative_method = $runner->run_command_action( command => 'true', cwd => 'home' );
    is( $relative_method->{exit_code}, 0, 'run_command_action() resolves a relative cwd that names a path registry accessor' );

    # Relative cwd that is a real directory but is not a path-registry method
    # (line 145 left-true-right-false).
    my $workdir = File::Spec->catdir( $home, 'workdir' );
    mkdir $workdir or die "Unable to create $workdir: $!";
    my $relative_plain = $runner->run_command_action( command => 'true', cwd => 'workdir' );
    is( $relative_plain->{exit_code}, 0, 'run_command_action() runs in a relative cwd that is not a path registry accessor' );

    # Missing cwd -> the existence guard fires.
    my $missing_cwd = eval {
        $runner->run_command_action( command => 'true', cwd => File::Spec->catdir( $home, 'no-such-cwd' ) );
        1;
    };
    ok( !$missing_cwd, 'run_command_action() rejects a cwd that does not exist' );
}

# ---------------------------------------------------------------------------
# _run_command(): the non-timeout exception is re-thrown (line 418 true) and a
# real timeout is not re-thrown (line 418 false).
# ---------------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::shell_command_argv = sub { die "forced argv failure\n" };
    my $argv_die = eval { $runner->run_command_action( command => 'true', cwd => $home ); 1 };
    ok( !$argv_die, 'run_command_action() propagates a non-timeout exception from the command runner' );
    like( $@, qr/forced argv failure/, 'the non-timeout exception message is preserved' );
}
{
    my $timed = $runner->run_command_action(
        command    => qq{$^X -e 'sleep 5'},
        cwd        => $home,
        timeout_ms => 100,
    );
    is( $timed->{timed_out}, 1, 'run_command_action() reports a real timeout' );
    is( $timed->{exit_code}, 124, 'a timed-out command returns exit code 124' );
}

# ---------------------------------------------------------------------------
# _run_builtin_action(): the builtin id source (line 336) and the empty-state
# default (line 350).
# ---------------------------------------------------------------------------
{
    # builtin key present -> line 336 uses it directly (left-true).
    my $by_builtin = $runner->run_page_action(
        page   => Developer::Dashboard::PageDocument->new( id => 'state-a', title => 'State A', state => { alpha => 1 } ),
        action => { kind => 'builtin', builtin => 'page.state' },
        source => 'saved',
    );
    like( $by_builtin->{body}, qr/"alpha"/, 'builtin id resolves from the builtin key' );

    # builtin key absent -> line 336 falls back to the id.
    my $by_id = $runner->run_page_action(
        page   => Developer::Dashboard::PageDocument->new( id => 'source-b', title => 'Source B', layout => { body => 'b' } ),
        action => { kind => 'builtin', id => 'page.source' },
        source => 'saved',
    );
    like( $by_id->{body}, qr/Source B/, 'builtin id falls back to the action id' );

    # Present state -> line 350 uses it directly (left-true).
    my $present_state = $runner->run_page_action(
        page   => Developer::Dashboard::PageDocument->new( id => 'state-c', title => 'State C', state => { beta => 2 } ),
        action => { kind => 'builtin', builtin => 'page.state' },
        source => 'saved',
    );
    like( $present_state->{body}, qr/"beta"/, 'page.state serializes a present state hash' );

    # A page object whose as_hash carries no state key -> line 350 falls back to
    # an empty hash (left-false). PageDocument->new always defaults state to a
    # truthy hash, so this needs a page without that default.
    my $empty_state = $runner->_run_builtin_action(
        action => { builtin => 'page.state' },
        page   => Local::NoInstructionPage->new,
    );
    is( $empty_state->{body}, "{}\n", 'page.state falls back to an empty hash when the page carries no state key' );

    my $unsupported = eval {
        $runner->_run_builtin_action( action => {}, page => $source_page );
        1;
    };
    ok( !$unsupported, '_run_builtin_action() rejects an action with no builtin id' );
}

# ---------------------------------------------------------------------------
# _is_action_trusted(): the source default (line 381), the saved/provider check
# (line 383), and the permissions default (line 385).
# ---------------------------------------------------------------------------
{
    my $with_perms = Developer::Dashboard::PageDocument->new(
        id          => 'perm-page',
        title       => 'Perm Page',
        permissions => { allow_untrusted_actions => 1, trusted_actions => ['allowed'] },
    );
    my $no_perms = Developer::Dashboard::PageDocument->new(
        id     => 'no-perm-page',
        title  => 'No Perm Page',
        layout => { body => 'b' },
    );

    # Source present, permissions present, action listed as trusted (line 381
    # left-true, line 383 both false, line 385 left-true).
    ok(
        $runner->_is_action_trusted( action => { id => 'allowed' }, page => $with_perms, source => 'transient' ),
        '_is_action_trusted() honours an explicitly trusted action for a transient source',
    );

    # Source 'provider' -> line 383 left-false-right-true short-circuits to trusted.
    ok(
        $runner->_is_action_trusted( action => { id => 'p' }, page => $no_perms, source => 'provider' ),
        '_is_action_trusted() trusts provider-sourced actions',
    );

    # Source 'saved' -> line 383 left-true short-circuits to trusted.
    ok(
        $runner->_is_action_trusted( action => { id => 's' }, page => $no_perms, source => 'saved' ),
        '_is_action_trusted() trusts saved-sourced actions',
    );

    # No source argument -> defaults to '' (line 381 left-false); a page whose
    # as_hash carries no permissions key -> defaults to {} (line 385 left-false)
    # and denies the action. PageDocument->new always defaults permissions to a
    # truthy hash, so this needs a page without that default.
    ok(
        !$runner->_is_action_trusted( action => { id => 'u' }, page => Local::NoInstructionPage->new ),
        '_is_action_trusted() denies an untrusted action when no source or permissions exist',
    );

    # A page that provides a permissions hash covers the line 385 left-true side.
    ok(
        !$runner->_is_action_trusted( action => { id => 'v' }, page => $no_perms, source => 'transient' ),
        '_is_action_trusted() denies a transient action when the page permissions forbid it',
    );

    # A safe action is always trusted (line 382 short-circuit).
    ok(
        $runner->_is_action_trusted( action => { id => 'safe', safe => 1 }, page => $no_perms, source => 'transient' ),
        '_is_action_trusted() trusts an action flagged safe',
    );
}

# ---------------------------------------------------------------------------
# _reap_child_process() and _pid_is_running(): the pid guard covers each
# rejected input class and a valid pid (lines 283, 322).
# ---------------------------------------------------------------------------
{
    ok( !$runner->_reap_child_process(undef),  '_reap_child_process() rejects an undefined pid' );
    ok( !$runner->_reap_child_process('abc'),  '_reap_child_process() rejects a non-numeric pid' );
    ok( !$runner->_reap_child_process(0),      '_reap_child_process() rejects a zero pid' );
    ok( !$runner->_reap_child_process(999999), '_reap_child_process() returns false for a pid it does not own' );

    ok( !$runner->_pid_is_running(undef),  '_pid_is_running() rejects an undefined pid' );
    ok( !$runner->_pid_is_running('abc'),  '_pid_is_running() rejects a non-numeric pid' );
    ok( !$runner->_pid_is_running(0),      '_pid_is_running() rejects a zero pid' );
    ok( !$runner->_pid_is_running(999999), '_pid_is_running() reports a missing pid as stopped' );
}

# ---------------------------------------------------------------------------
# _read_process_state(): the live procfs path (lines 296, 297, 300, 301) and the
# ps fallback with undef, populated, and blank output (lines 309, 310, 311).
# ---------------------------------------------------------------------------
{
    my $state = $runner->_read_process_state($$);
    ok( defined $state && $state =~ /^\S$/, '_read_process_state() reads the live procfs one-letter state' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::capture = sub (&) { return ( undef, '', 0 ) };
    is( scalar $runner->_read_process_state(999998), undef, '_read_process_state() tolerates undefined ps output' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::capture = sub (&) { return ( "S\n", '', 0 ) };
    is( $runner->_read_process_state(999997), 'S', '_read_process_state() falls back to ps output when procfs is unavailable' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::capture = sub (&) { return ( "   \n", '', 0 ) };
    is( scalar $runner->_read_process_state(999996), undef, '_read_process_state() returns undef when ps output is blank' );
}
{
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::capture = sub (&) { return ( '', '', 3 ) };
    is( scalar $runner->_read_process_state(999995), undef, '_read_process_state() returns undef when ps exits non-zero' );
}

# ---------------------------------------------------------------------------
# Background actions: the successful fork/detach path plus its deadline,
# supervisor-exit, timeout, forced-kill, and boot-failure branches
# (lines 155, 185, 199, 202, 203, 206, 213, 214, 215).
# ---------------------------------------------------------------------------

# A fast command with a non-positive timeout leaves the deadline undefined
# (line 199 false, line 203 left-false) and exits through the supervisor once
# the command child is reaped (line 202 true).
{
    my $result = $runner->run_command_action(
        command    => qq{$^X -e 1},
        cwd        => $home,
        background => 1,
        timeout_ms => -1,
    );
    ok( $result->{pid} > 0, 'background action with a non-positive timeout returns a child pid' );
    wait_for_pid_exit( $result->{pid} );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'background action with an undefined deadline exits when its command finishes' );
}

# A fast command with a positive timeout exercises the normal deadline path.
{
    my $result = $runner->run_command_action(
        command    => qq{$^X -e 1},
        cwd        => $home,
        background => 1,
        timeout_ms => 5000,
    );
    ok( $result->{pid} > 0, 'background action with a positive timeout returns a child pid' );
    wait_for_pid_exit( $result->{pid} );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'background action with a deadline exits cleanly' );
}

# A slow command whose shell traps SIGTERM keeps the supervisor's direct child
# alive across the terminate window, forcing the escalation to SIGKILL (line 206
# true). Trapping in the shell and exec-ing sleep makes the direct child both
# ignore TERM (inherited SIG_IGN) and be the process KILL reaps, with no orphan
# left behind and no interpreter-startup race. This case runs before the plain
# timeout case below because a preceding plain-timeout run perturbs the timing
# and hides the forced-KILL branch.
{
    local $ENV{SHELL} = 'bash';
    my $result = $runner->run_command_action(
        command    => q{trap '' TERM; exec sleep 60},
        cwd        => $home,
        background => 1,
        timeout_ms => 800,
    );
    ok( $result->{pid} > 0, 'background action with a TERM-trapping command returns a child pid' );
    wait_for_pid_exit( $result->{pid} );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'background action deadline escalates to KILL when TERM is ignored' );
}

# A slow command with a tiny timeout hits the deadline (line 203 right-true) and
# is already reaped by the time the escalation check runs (line 206 false).
{
    my $result = $runner->run_command_action(
        command    => qq{$^X -e 'sleep 5'},
        cwd        => $home,
        background => 1,
        timeout_ms => 100,
    );
    ok( $result->{pid} > 0, 'background action with a slow command returns a child pid' );
    wait_for_pid_exit( $result->{pid} );
    ok( !$runner->_pid_is_running( $result->{pid} ), 'background action deadline terminates a slow command' );
}

# An exec failure in the detached command child is surfaced through the pipe
# (line 185 die side).
{
    my $fork_calls = 0;
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::_fork_process = sub {
        $fork_calls++;
        return fork() if $fork_calls == 1;
        return 0;
    };
    local *Developer::Dashboard::ActionRunner::shell_command_argv = sub { return ('/definitely/missing-action-runner-binary') };
    my $exec_fail = eval {
        $runner->run_command_action(
            command    => 'never-execs',
            cwd        => $home,
            background => 1,
            timeout_ms => 1000,
        );
        1;
    };
    ok( !$exec_fail, 'background action surfaces a detached-child exec failure' );
    like( $@, qr/Unable to exec background action command/, 'exec failure explains itself' );
}

# A detach failure makes the eval body die, so the boot-failure path writes the
# error back to the parent (lines 213 true, 214, 215 true).
{
    no warnings 'redefine';
    local *Developer::Dashboard::ActionRunner::_detach_background_session = sub {
        $! = 1;
        return undef;
    };
    my $boot_fail = eval {
        $runner->run_command_action(
            command    => 'never-detaches',
            cwd        => $home,
            background => 1,
            timeout_ms => 1000,
        );
        1;
    };
    ok( !$boot_fail, 'background action surfaces a detach failure' );
    like( $@, qr/Unable to detach background action session/, 'detach failure explains itself' );
}

done_testing;

{
    package Local::NoInstructionPage;
    # new()
    # Purpose: a minimal page object that intentionally lacks a
    # canonical_instruction method so the encoder must fall back.
    # Input: class name.
    # Output: blessed object.
    sub new { return bless {}, shift }

    # as_hash()
    # Purpose: satisfy the encoder's only structural requirement.
    # Input: none.
    # Output: empty hash reference (no id key).
    sub as_hash { return {} }
}

__END__

=head1 NAME

t/81-actionrunner-coverage.t - branch and condition coverage closure for the action runner

=head1 PURPOSE

This test is the executable coverage contract for the residual branch and
condition sides of C<Developer::Dashboard::ActionRunner>. It drives the
constructor guards, the page-action trust and routing decisions, the encoded
transport refusal, the command runner's cwd resolution and exception handling,
the process-state helpers, and the detached background-action lifecycle so that
every reachable branch and condition in the module is exercised from one
hermetic fixture.

=head1 WHY IT EXISTS

The action runner mixes ordinary in-process logic with detached, forked,
stdio-redirected background children whose branch decisions are easy to leave
uncovered. The broader security and integration suites hit the module's happy
paths but skip the non-positive timeout, supervisor-exit, forced-kill,
boot-failure, and procfs/ps fallback branches. Keeping those in one focused file
makes the coverage loop and the release gate concrete instead of depending on a
code-only reading of which side ran.

=head1 WHEN TO USE

Use this file when changing the action trust model, the encoded action
transport, the command runner's cwd or timeout handling, the background fork and
detach path, or the process-state helpers. Run it directly for a fast loop, then
keep it green under the full suite and the coverage gate before release.

=head1 HOW TO USE

Run it directly while iterating:

  perl -Ilib t/81-actionrunner-coverage.t

Collect coverage for just this file into a private database when closing the
gap:

  HARNESS_PERL_SWITCHES="-MDevel::Cover=-db,/tmp/ddcov-ActionRunner" prove -l t/81-actionrunner-coverage.t

Then keep it green inside the whole suite:

  prove -lr t

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the library coverage
gates, and the release verification loop all rely on this file to keep the
action runner's branch and condition coverage from regressing.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/81-actionrunner-coverage.t

Run the focused coverage-closure test by itself while changing the action runner.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/81-actionrunner-coverage.t

Exercise the same focused test while collecting coverage for the action-runner
code it reaches.

Example 3:

  prove -lr t

Put the action-runner change back through the whole repository suite before
calling the work finished.

=cut
