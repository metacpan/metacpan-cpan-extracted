use strict;
use warnings;
use utf8;

# Deterministic fault-injection for the atomic-write helper. These CORE::GLOBAL
# overrides must be installed BEFORE the module under test is compiled so that
# the module's own `rename`/`close` calls resolve to them. Both stay transparent
# pass-throughs unless the matching package flag is set, so the rest of the test
# (and any module loaded transitively) keeps working normally.
#
# The close override is scoped to the atomic writer's ".pending" temp file so it
# injects a failure for exactly the IndicatorStore write under test and never for
# the unrelated checked closes elsewhere in the runtime.
our $FAIL_RENAME        = 0;
our $FAIL_CLOSE_PENDING = 0;

BEGIN {
    # rename(FROM, TO): honour the failure flag, otherwise defer to the builtin.
    # Input: source and target path. Output: 0 when forced to fail, else builtin.
    *CORE::GLOBAL::rename = sub ($$) {
        return 0 if $main::FAIL_RENAME;
        return CORE::rename( $_[0], $_[1] );
    };
    # close(FH): fail only the atomic writer's ".pending" temp handle when the
    # flag is set, otherwise defer to the builtin.
    # Input: a filehandle. Output: 0 when forced to fail, else builtin result.
    *CORE::GLOBAL::close = sub (;*) {
        if ($main::FAIL_CLOSE_PENDING) {
            my $fno = eval { fileno( $_[0] ) };
            if ( defined $fno ) {
                my $target = readlink("/proc/self/fd/$fno");
                return 0 if defined $target && $target =~ /\.pending\z/;
            }
        }
        return CORE::close( $_[0] );
    };
}

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;

local $ENV{HOME} = tempdir( CLEANUP => 1 );
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::IndicatorStore->new( paths => $paths );

# write_fake_git($dir)
# Stages a fake `git` shim whose `diff --quiet` exit code is driven by the
# FAKE_GIT_DIFF_EXIT environment variable while `rev-parse --is-inside-work-tree`
# always reports a real work tree.
# Input: directory to hold the shim.
# Output: absolute path to the staged shim's bin directory.
sub write_fake_git {
    my ($dir) = @_;
    my $bin = File::Spec->catdir( $dir, 'fakebin' );
    mkdir $bin or die "Unable to mkdir $bin: $!";
    my $git = File::Spec->catfile( $bin, 'git' );
    open my $fh, '>', $git or die "Unable to write $git: $!";
    print {$fh} <<'SH';
#!/bin/sh
if [ "$1" = "rev-parse" ]; then
    echo true
    exit 0
fi
if [ "$1" = "diff" ]; then
    exit ${FAKE_GIT_DIFF_EXIT:-0}
fi
exit 0
SH
    close $fh or die "Unable to close $git: $!";
    chmod 0755, $git or die "Unable to chmod $git: $!";
    return $bin;
}

# git_status_for($repo, $exit)
# Runs refresh_core_indicators against a fake git repo whose `git diff` returns
# the requested exit code and returns the resolved git indicator status.
# Input: project root path and the integer exit code the fake `git diff` returns.
# Output: git indicator status string (or undef when absent).
sub git_status_for {
    my ( $repo, $exit ) = @_;
    local $ENV{FAKE_GIT_DIFF_EXIT} = $exit;
    my $items;
    my ( undef, $stderr ) = capture {
        $items = $store->refresh_core_indicators( cwd => $repo );
    };
    is( $stderr, '', "core refresh stays quiet for git diff exit $exit" );
    my ($git) = grep { $_->{name} eq 'git' } @{$items};
    return defined $git ? $git->{status} : undef;
}

# ---------------------------------------------------------------------------
# Finding 2: `git diff --quiet` exit-code mapping must distinguish a real git
# error (exit 128) from an actually-modified tree (exit 1). The buggy code maps
# every non-zero exit to 'dirty', hiding git failures behind a false 'dirty'.
# ---------------------------------------------------------------------------
{
    my $repo = File::Spec->catdir( $ENV{HOME}, 'fake-repo' );
    mkdir $repo or die "Unable to mkdir $repo: $!";
    mkdir File::Spec->catdir( $repo, '.git' ) or die "Unable to seed .git: $!";
    my $bin = write_fake_git($repo);
    local $ENV{PATH} = "$bin" . ( defined $ENV{PATH} ? ":$ENV{PATH}" : '' );

    is( git_status_for( $repo, 0 ), 'clean',
        'git diff exit 0 maps to clean' );
    is( git_status_for( $repo, 1 ), 'dirty',
        'git diff exit 1 (modified tree) maps to dirty' );
    is( git_status_for( $repo, 128 ), 'error',
        'git diff exit 128 (git error) maps to error, not a false dirty' );
}

# ---------------------------------------------------------------------------
# Finding 1a: the atomic-write helper must not unlink the destination before the
# rename. The buggy sequence deletes the live status file first, so a rename
# failure destroys the previously persisted indicator instead of preserving it.
# ---------------------------------------------------------------------------
{
    $store->set_indicator(
        'atomic-rename',
        label  => 'Atomic',
        icon   => 'A',
        status => 'ok',
    );
    my $before = $store->get_indicator('atomic-rename');
    is( $before->{status}, 'ok', 'seed indicator persisted before rename fault' );

    my $err = do {
        local $main::FAIL_RENAME = 1;
        local $@;
        eval {
            $store->set_indicator(
                'atomic-rename',
                label  => 'Atomic',
                icon   => 'A',
                status => 'changed',
            );
            1;
        };
        $@;
    };

    like( $err, qr/Unable to rename/,
        'rename failure surfaces as an explicit error' );

    my $after = $store->get_indicator('atomic-rename');
    ok( defined $after,
        'previous status file survives a failed rename (no unlink-before-rename)' );
    is( ( defined $after ? $after->{status} : '' ), 'ok',
        'the surviving status file still holds the original committed value' );
}

# ---------------------------------------------------------------------------
# Finding 1b: the atomic-write helper must not ignore close(). A failed close can
# mean the buffered write never reached disk, so it must surface as an error
# rather than being silently swallowed.
# ---------------------------------------------------------------------------
SKIP: {
    skip 'close() fault injection requires /proc/self/fd', 1
      unless -e '/proc/self/fd';

    my $err = do {
        local $main::FAIL_CLOSE_PENDING = 1;
        local $@;
        eval {
            $store->set_indicator(
                'atomic-close',
                label  => 'Close',
                icon   => 'C',
                status => 'ok',
            );
            1;
        };
        $@;
    };

    like( $err, qr/Unable to close/,
        'a failed close on the pending write is reported, not ignored' );
}

done_testing;

__END__

=head1 NAME

55-hunt-indicatorstore.t - regression guards for IndicatorStore atomic writes and git status mapping

=head1 DESCRIPTION

This test pins two robustness defects in
C<Developer::Dashboard::IndicatorStore>: the file-backed atomic write in
C<set_indicator> and the git work-tree dirtiness classification in
C<refresh_core_indicators>.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable contract for two IndicatorStore correctness fixes. First, the atomic status writer must never unlink the destination before the rename and must never ignore C<close>, because both mistakes can lose or silently corrupt persisted indicator state. Second, the git indicator must map C<git diff --quiet> exit 1 to C<dirty> but any other non-zero exit (such as 128) to C<error>, so a broken git invocation is not reported as a modified work tree.

=head1 WHY IT EXISTS

It exists because these are silent-failure defects that a code-only read can miss. A rename that fails after the destination was unlinked leaves no status file at all, an ignored C<close> can hide a short write, and a git error disguised as C<dirty> misleads every prompt and status-strip reader. Deterministic fault injection turns those rare failure paths into repeatable assertions.

=head1 WHEN TO USE

Use this file when changing the IndicatorStore atomic write path, its file replacement strategy, or the git work-tree status classification, and whenever a focused failure points here.

=head1 HOW TO USE

Run it directly with C<prove -lv t/55-hunt-indicatorstore.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. The C<CORE::GLOBAL> overrides at the top must stay installed before the module is loaded so the fault flags reach the module's own C<rename> and C<close> calls.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep the IndicatorStore persistence and git status behavior from regressing.

=head1 EXAMPLES

Example 1:

  prove -lv t/55-hunt-indicatorstore.t

Run the focused regression test by itself while changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/55-hunt-indicatorstore.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
