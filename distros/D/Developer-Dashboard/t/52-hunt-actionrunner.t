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

# build_runner()
# Purpose: construct an ActionRunner backed by throwaway file/path registries.
# Input: none.
# Output: (runner, home_dir) where home_dir is a real, existing directory the
#         command-action tests can use as a valid cwd.
sub build_runner {
    my $home  = tempdir( CLEANUP => 1 );
    my $paths = Developer::Dashboard::PathRegistry->new(
        home            => $home,
        workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
        project_roots   => [ File::Spec->catdir( $home, 'projects' ) ],
    );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $runner = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );
    return ( $runner, $home );
}

# forged_command_token($runner, $page, $command_action, $source)
# Purpose: mint an encoded action token exactly the way an attacker would, using
#          only the module's public encoder and any claimed trust origin.
# Input: runner object, PageDocument, command action hash, and claimed source.
# Output: encoded action token string.
sub forged_command_token {
    my ( $runner, $page, $command_action, $source ) = @_;
    return $runner->encode_action_payload(
        action => $command_action,
        page   => $page,
        source => $source,
    );
}

my ( $runner, $home ) = build_runner();

my $forged_page = Developer::Dashboard::PageDocument->new(
    id          => 'attacker-page',
    title       => 'Attacker Page',
    state       => {},
    permissions => {},
);

# Finding 1: a forged encoded token that claims saved-page trust for an
# arbitrary command action must be rejected and must never execute the command.
{
    my $marker = File::Spec->catfile( $home, 'saved-source-pwned.marker' );
    my $token  = forged_command_token(
        $runner,
        $forged_page,
        {
            id      => 'pwn',
            kind    => 'command',
            command => qq{printf pwned > "$marker"},
            cwd     => $home,
        },
        'saved',
    );

    my $ran = eval { $runner->run_encoded_action( token => $token ); 1 };
    my $err = $@;
    ok( !$ran, 'forged saved-source command token is rejected on the encoded path' );
    like( $err, qr/[Cc]ommand actions/, 'encoded command rejection explains the policy' );
    ok( !-e $marker, 'forged saved-source command action never executed its command' );
}

# Finding 1 (root cause): the payload-supplied per-action 'safe' flag is equally
# forgeable, so a safe-flagged command over the encoded transport must also be
# refused. A source-only fix would leave this vector open.
{
    my $marker = File::Spec->catfile( $home, 'safe-flag-pwned.marker' );
    my $token  = forged_command_token(
        $runner,
        $forged_page,
        {
            id      => 'pwn-safe',
            kind    => 'command',
            command => qq{printf pwned > "$marker"},
            cwd     => $home,
            safe    => 1,
        },
        'transient',
    );

    my $ran = eval { $runner->run_encoded_action( token => $token ); 1 };
    ok( !$ran, 'forged safe-flagged command token is rejected on the encoded path' );
    ok( !-e $marker, 'forged safe-flagged command action never executed its command' );
}

# Finding 1 (no over-blocking): built-in actions map to a fixed server-side
# allowlist, so they must still execute over the encoded path.
{
    my $state_page = Developer::Dashboard::PageDocument->new(
        id    => 'state-page',
        title => 'State Page',
        state => { alpha => 'one' },
    );
    my $token = $runner->encode_action_payload(
        action => { id => 'state', kind => 'builtin', builtin => 'page.state', safe => 1 },
        page   => $state_page,
        source => 'saved',
    );

    my $result = $runner->run_encoded_action( token => $token );
    is( ref($result), 'HASH', 'builtin encoded action still returns a result hash' );
    like( $result->{content_type}, qr{application/json}, 'builtin encoded action keeps its JSON content type' );
    like( $result->{body}, qr/"alpha"\s*:\s*"one"/, 'builtin encoded action still returns page state' );
}

# Finding 1 (still authenticated on the saved route): a command action invoked
# through run_page_action with a server-established saved source is unaffected.
{
    my $marker  = File::Spec->catfile( $home, 'saved-route.marker' );
    # Windows runs command actions through PowerShell, which has no
    # printf; there the same side effect comes from a Perl script run by
    # the current interpreter.
    my $marker_command = qq{printf ok > "$marker"};
    if ( $^O eq 'MSWin32' ) {
        my $script = _write_script( 'saved-route-marker.pl',
            qq{open my \$fh, '>', \$ARGV[0] or die "Unable to write \$ARGV[0]: \$!"; print {\$fh} 'ok'; close \$fh or die "Unable to close \$ARGV[0]: \$!";\n} );
        $marker_command = qq{& "$^X" "$script" "$marker"};
    }
    my $command = {
        id      => 'run',
        kind    => 'command',
        command => $marker_command,
        cwd     => $home,
    };
    my $result = $runner->run_page_action(
        action => $command,
        page   => $forged_page,
        source => 'saved',
    );
    is( $result->{exit_code}, 0, 'trusted saved-route command action still executes' );
    ok( -e $marker, 'trusted saved-route command action produced its side effect' );
}

# Finding 2: background actions use the platform-neutral GoRoutine process API
# and request an isolated process group for timeout and signal supervision.
{
    require Developer::Dashboard::GoRoutine;
    no warnings 'redefine';
    my ( $argv, $options );
    local *Developer::Dashboard::GoRoutine::spawn = sub {
        ( $argv, $options ) = @_;
        return 4242;
    };
    my $result = $runner->_spawn_background_action(
        command    => 'true',
        cwd        => $home,
        env        => {},
        timeout_ms => 5000,
    );
    is( $result->{pid}, 4242, 'background action returns the GoRoutine process identifier' );
    is( $options->{process_group}, 1, 'background action asks GoRoutine to isolate the supervised process group' );
    is( $options->{cwd}, $home, 'background action passes its validated working directory to GoRoutine' );
    is( $options->{stdin}, File::Spec->devnull(), 'background action closes child stdin through GoRoutine options' );
}

# Finding 3: a synchronous command killed by a signal must report a signal-aware
# exit code (128 + signal), not the naive $? >> 8 value of zero.
{
    local $ENV{SHELL} = 'bash';
    # Windows has no signals: a process that kills itself with 9 simply
    # ends with exit code 9, and a wait status never carries signal bits.
    # There the child is a Perl script run through PowerShell, and the
    # real contract is that its exit code comes back unchanged.
    my $is_windows   = $^O eq 'MSWin32';
    my $kill_command = 'kill -9 $$';
    if ($is_windows) {
        my $script = _write_script( 'kill-self.pl', qq{kill 9, \$\$; sleep 5; exit 0;\n} );
        $kill_command = qq{& "$^X" "$script"; exit \$LASTEXITCODE};
    }
    my $result = $runner->run_command_action(
        command    => $kill_command,
        cwd        => $home,
        timeout_ms => 5000,
    );
    is( $result->{timed_out}, 0, 'signal-killed command is not treated as a timeout' );
    if ($is_windows) {
        cmp_ok( $result->{exit_code}, '>', 0, 'self-killed command reports a failing exit code on Windows' );
        is( $result->{exit_code}, 9, 'a self-kill with 9 comes back as plain exit code 9 on Windows (no signal bits)' );
    }
    else {
        cmp_ok( $result->{exit_code}, '>=', 128, 'signal-killed command reports a signal-aware exit code' );
        is( $result->{exit_code}, 137, 'SIGKILL maps to shell-style exit code 137 (128 + 9)' );
    }
}

# Finding 3 (no regression): a normal exit code is passed through unchanged.
{
    local $ENV{SHELL} = 'bash';
    my $result = $runner->run_command_action(
        command    => 'exit 3',
        cwd        => $home,
        timeout_ms => 5000,
    );
    is( $result->{exit_code}, 3, 'normal command exit codes are preserved unchanged' );
}

# _write_script($name, $source)
# Writes one Perl helper script under the test home.
# Input: file name and Perl source text.
# Output: absolute script path.
sub _write_script {
    my ( $name, $source ) = @_;
    my $path = File::Spec->catfile( $home, $name );
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $source;
    close $fh or die "Unable to close $path: $!";
    return $path;
}

# A hand-built token whose action is not a hash still routes into the normal
# page-action validation instead of dying on a bad dereference.
{
    my $token = encode_payload( json_encode( { source => 'saved', page_source => '', action => [ 1, 2 ] } ) );
    my $ran = eval { $runner->run_encoded_action( token => $token ); 1 };
    ok( !$ran, 'encoded token with a non-hash action is rejected' );
}

done_testing;

__END__

=head1 NAME

52-hunt-actionrunner.t - security and portability regression tests for the action runner

=head1 DESCRIPTION

This test pins down three defects in C<Developer::Dashboard::ActionRunner>: an
encoded-action transport that executed attacker-controlled command actions, a
background detach path that called POSIX C<setsid> unconditionally, and a
synchronous command exit code that hid signal terminations behind a zero.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for the action runner's trust
boundary and its cross-platform process handling. It proves that command actions
delivered over the unauthenticated encoded token transport are refused, that the
background detach helper skips C<setsid> on Windows, and that a signal-killed
synchronous command reports a shell-style C<128 + signal> exit code instead of a
misleading zero.

=head1 WHY IT EXISTS

It exists because these three behaviors are easy to regress silently: the encoded
transport looks like a normal action call, the Windows detach branch never runs
on the Linux test host by default, and a naive C<$? E<gt>E<gt> 8> exit code
looks correct for every command that exits normally. Pinning each one in a
dedicated file keeps the TDD loop, the coverage loop, and the security audit
concrete instead of relying on a code-only review to catch a re-introduction.

=head1 WHEN TO USE

Use this file when changing the action trust model, the encoded action transport,
the background-action fork and detach path, or the way command actions report
exit codes. Run it directly for a fast loop, then keep it green under the full
suite and the coverage gate before release.

=head1 HOW TO USE

Run it directly with C<prove -lv t/52-hunt-actionrunner.t> while iterating on the
action runner, then keep it green under C<prove -lr t> and the Devel::Cover runs.
The forged-token cases mint their payloads with the module's own public encoder,
so they reproduce exactly what an untrusted client can construct.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the library coverage gates,
and the pre-push security audit all rely on this file to keep the action runner's
trust boundary and cross-platform behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/52-hunt-actionrunner.t

Run the focused security and portability regression test by itself while changing
the action runner.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/52-hunt-actionrunner.t

Exercise the same focused test while collecting coverage for the action-runner
code it reaches.

Example 3:

  prove -lr t

Put the action-runner change back through the whole repository suite before
calling the work finished.

=for comment FULL-POD-DOC END

=cut
