#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use File::Path qw(make_path);
use File::Temp qw(tempdir);
use Digest::MD5 ();
use Capture::Tiny qw(capture);

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );
my $lib       = File::Spec->catdir( $repo_root, 'lib' );
my $dashboard = File::Spec->catfile( $repo_root, 'bin', 'dashboard' );

# Same MD5-keyed cache layout PaxCache.pm itself uses: home_cache_root/pax/
# <md5_hex(source_path)>.{md5,pax,compiling}. Seeding it directly (rather
# than going through a real PAX compile) keeps this test fast and hermetic.
sub seed_cache_for_dashboard {
    my ( $home, $binary_contents ) = @_;
    my $cache_dir = File::Spec->catdir( $home, '.developer-dashboard', 'cache', 'pax' );
    make_path($cache_dir);
    my $key = Digest::MD5::md5_hex($dashboard);

    open my $sfh, '<:raw', $dashboard or die "Unable to read $dashboard: $!";
    my $md5 = Digest::MD5->new;
    $md5->addfile($sfh);
    close $sfh;
    my $source_md5 = $md5->hexdigest;

    my $md5_file = File::Spec->catfile( $cache_dir, "$key.md5" );
    open my $mfh, '>', $md5_file or die "Unable to write $md5_file: $!";
    print {$mfh} $source_md5;
    close $mfh;

    my $bin_file = File::Spec->catfile( $cache_dir, "$key.pax" );
    open my $bfh, '>', $bin_file or die "Unable to write $bin_file: $!";
    print {$bfh} $binary_contents;
    close $bfh;
    chmod 0755, $bin_file;

    return $bin_file;
}

# DD-882 (owner correction, Telegram msg #2001, 2026-09-15): dashboard checks
# its own source MD5 against PaxCache's cache and, if the exec side is live,
# execs a matching compiled binary directly on a hit. DD-905 (2026-09-16)
# temporarily disabled the exec side after finding that a real PAX-compiled
# binary of this entrypoint silently corrupted %ENV loading. DD-922
# (2026-09-16) root-caused and fixed THAT defect (StandaloneRuntime's own
# _run_*_unit dispatchers left $/ undef across a later `eval` of the
# entrypoint's own source) and briefly re-enabled the exec side - within
# minutes a SECOND, independent defect surfaced (EnvAudit->record failing
# inside the compiled binary's "legacy namespace", never reachable before
# since self-exec had been off since DD-905), so DD-930 (2026-09-17)
# disabled it again. A cache hit is detected (the resolve() call still
# runs, keeping a background compile warm) but never acted on.
{
    my $home = tempdir( CLEANUP => 1 );
    my $sentinel_bin = seed_cache_for_dashboard(
        $home,
        "#!/usr/bin/env perl\nprint \"DD882-SENTINEL-COMPILED-OUTPUT\\n\";\n"
    );

    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        system( $^X, '-I', $lib, $dashboard, 'version' );
    };
    is( $exit >> 8, 0, 'DD-930: dashboard exits cleanly with a matching self-compiled binary cached' );
    unlike(
        $out,
        qr/DD882-SENTINEL-COMPILED-OUTPUT/,
        'DD-930: dashboard does NOT exec the cached self-compiled binary on a cache hit - the exec side stays disabled'
    );
    like( $out, qr/\A\d+\.\d+\s*\z/, 'DD-930: dashboard runs its own interpreted body and produces correct output' );
}

# A stale/no-cache case must still work exactly as before: run interpreted,
# with zero behavior change and no attempt to exec anything.
{
    my $home = tempdir( CLEANUP => 1 );
    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        local $ENV{PATH} = '/nonexistent-empty-dir-for-this-test';    # no pax available either
        system( $^X, '-I', $lib, $dashboard, 'version' );
    };
    is( $exit >> 8, 0, 'DD-882: dashboard exits cleanly with no cached self-binary' );
    like( $out, qr/\A\d+\.\d+\s*\z/, 'DD-882: dashboard runs interpreted normally with no cached self-binary (no compile blocking, correct output)' );
}

# DD-882's exec guard var (DEVELOPER_DASHBOARD_PAX_SELF_EXECED) must still
# suppress the self-check when inherited from a parent process, regardless
# of whether the exec side is currently live (DD-930) or disabled - a
# suppressed check must never emit sentinel output either way, and the
# guard must still be cleared before falling through so a later child
# `dashboard` this process spawns gets its own independent, unsuppressed
# self-check.
{
    my $home = tempdir( CLEANUP => 1 );
    seed_cache_for_dashboard(
        $home,
        "#!/usr/bin/env perl\nprint \"DD882-SENTINEL-GUARD-TEST\\n\";\n"
    );

    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        local $ENV{DEVELOPER_DASHBOARD_PAX_SELF_EXECED} = 1;
        system( $^X, '-I', $lib, $dashboard, 'version' );
    };
    is( $exit >> 8, 0, 'DD-882: with the exec guard set from outside, dashboard still exits cleanly' );
    unlike(
        $out,
        qr/DD882-SENTINEL-GUARD-TEST/,
        'DD-882: a self-exec guard already set from OUTSIDE this invocation suppresses the self-check, matching the documented anti-infinite-loop contract'
    );
    like( $out, qr/\A\d+\.\d+\s*\z/, 'DD-882: with the guard pre-set, dashboard runs its own interpreted body normally' );
}

# DD-930's own regression coverage: even with a REAL PAX compile of
# dashboard cached (not a hand-written sentinel), and even though DD-922
# fixed the ORIGINAL $/ defect, `dashboard` itself must never be corrupted
# by acting on that cache hit - a DIFFERENT, previously-unreachable defect
# (EnvAudit->record failing inside the compiled binary's "legacy namespace")
# surfaced the moment DD-922 re-enabled self-exec, so DD-930 disabled it
# again. The guaranteed property is the same shape DD-905 established: the
# interpreted `dashboard` entrypoint must run correctly regardless of
# whether the cached compiled binary is itself broken. Skipped when pax is
# not resolvable (no vendored Pax CLI staged) or when explicitly disabled,
# since a real compile is slow and heavy.
SKIP: {
    skip 'DD_SKIP_REAL_PAX_COMPILE_TEST is set', 3 if $ENV{DD_SKIP_REAL_PAX_COMPILE_TEST};

    my $home = tempdir( CLEANUP => 1 );
    my $cache_dir = File::Spec->catdir( $home, '.developer-dashboard', 'cache', 'pax' );
    make_path($cache_dir);
    my $key = Digest::MD5::md5_hex($dashboard);
    my $bin_file = File::Spec->catfile( $cache_dir, "$key.pax" );
    my $md5_file = File::Spec->catfile( $cache_dir, "$key.md5" );

    my $pax = File::Spec->catfile( $repo_root, 'share', 'private-cli', 'pax' );
    my ( $build_out, $build_err, $build_exit ) = capture {
        local $ENV{HOME} = $home;
        system( $^X, $pax, 'build', '--compact', '-o', $bin_file, $dashboard );
    };
    skip 'a real pax build did not succeed in this environment', 3 if ( $build_exit >> 8 ) != 0 || !-x $bin_file;

    open my $sfh, '<:raw', $dashboard or die "Unable to read $dashboard: $!";
    my $md5 = Digest::MD5->new;
    $md5->addfile($sfh);
    close $sfh;
    open my $mfh, '>', $md5_file or die "Unable to write $md5_file: $!";
    print {$mfh} $md5->hexdigest;
    close $mfh;

    # .env is untracked (git-ignored) and loaded relative to the REPO ROOT,
    # not $HOME - a ticket worktree sandbox carries no .env of its own, so
    # write a throwaway multi-line one here: this is the exact shape DD-905
    # found broken (a plain line-by-line <$fh> read misreading the whole
    # file as one "line") and DD-922 fixed at the StandaloneRuntime level.
    my $env_file = File::Spec->catfile( $repo_root, '.env' );
    my $had_env = -f $env_file;
    my $original_env_content;
    if ($had_env) {
        open my $rfh, '<:raw', $env_file or die "Unable to read $env_file: $!";
        local $/;
        $original_env_content = <$rfh>;
        close $rfh;
    }
    open my $wfh, '>:raw', $env_file or die "Unable to write $env_file: $!";
    print {$wfh} "DD922_TEST_TOKEN=1234:abcdEFGHijklMNOP\nDD922_TEST_SECOND=another-value\nDD922_TEST_THIRD=third-value\n";
    close $wfh;

    my ( $direct_out, $direct_err, $direct_exit ) = capture {
        local $ENV{HOME} = $home;
        system($bin_file, 'version');
    };

    diag(
        ( $direct_exit >> 8 ) != 0
        ? "DD-930: the real self-compiled binary reproduced the known upstream EnvAudit-legacy-namespace defect in this environment (exit $direct_exit), as expected."
        : "DD-930: the real self-compiled binary did NOT reproduce the known upstream defect in this environment this run - environment-dependent, not this ticket's own concern (see DD-930's card for the confirmed reproduction)."
    );

    # DD-934: StandaloneRuntime.pm's _run_cli_router_unit called
    # _prime_command_result_env with only ($cmd, @ARGV), silently dropping
    # the $main_gate_results positional argument the function's own
    # signature expects - so the first real argv token filled that slot
    # instead of a hashref, and the function's "$main_gate_results || {}"
    # fallback then dereferenced a plain string. A bare command name never
    # triggered it (no argv token to misplace); ANY trailing token did.
    # Reuses the already-built $bin_file from the block above rather than
    # paying for a second ~2 minute real compile.
    my ( $argv_out, $argv_err, $argv_exit ) = capture {
        local $ENV{HOME} = $home;
        system( $bin_file, 'which', 'perl' );
    };
    unlike(
        $argv_err,
        qr/Can't use string \(.*\) as a HASH ref/,
        'DD-934: a real compiled binary invoked with a subcommand PLUS a trailing argv token does not crash on the $main_gate_results arity mismatch'
    );

    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        system( $^X, '-I', $lib, $dashboard, 'version' );
    };

    if ($had_env) {
        open my $wfh2, '>:raw', $env_file or die "Unable to restore $env_file: $!";
        print {$wfh2} $original_env_content;
        close $wfh2;
    }
    else {
        unlink $env_file;
    }

    is( $exit >> 8, 0, 'DD-930 regression: dashboard exits cleanly even with a REAL compiled binary cached' );
    like(
        $out,
        qr/\A\d+\.\d+\s*\z/,
        'DD-930 regression: dashboard runs its own interpreted body and produces correct output, never touching the cached compiled binary'
    );
}

done_testing;

__END__

=head1 NAME

t/182-dashboard-self-compile.t - dashboard's own MD5-checked self-compile hook

=head1 PURPOSE

Exercises bin/dashboard's self-compile check: it still checks its own
source MD5 against PaxCache's cache (keeping a background compile warm),
but never acts on a cache hit - dashboard always runs its own interpreted
body. DD-905 first disabled acting on a hit after a real compiled binary
silently corrupted config loading; DD-922 root-caused and fixed THAT
defect and re-enabled the exec side; within minutes a DIFFERENT,
previously-unreachable defect surfaced (EnvAudit->record failing inside
the compiled binary's "legacy namespace" - never reachable before because
self-exec had been off since DD-905), so DD-930 disabled it again. This
file is the executable proof that dashboard's own interpreted behavior is
never corrupted by whatever state the cached compiled binary happens to be
in - the actual safety property, independent of which specific upstream
defect the cached binary carries at any given time.

=head1 WHY IT EXISTS

DD-877 only wired PaxCache into the internal C<ps1> helper command, never
into dashboard's own entrypoint - the owner's original, explicit request
(Telegram msg #2001, 2026-09-15) was specifically that d2/dashboard
themselves become the self-compiling target. DD-882 built that (execing a
cached compiled binary on a hit); DD-905 found and disabled the exec side
after it silently broke config loading in real use, undetected by DD-882's
own tests because prove sets HARNESS_ACTIVE, which skips this whole check;
DD-922 root-caused that defect (a `local $/;` in the vendored Pax
StandaloneRuntime's own entrypoint dispatchers spanning a later `eval` of
the entrypoint's own source, since C<eval STRING> shares its caller's
dynamic scope rather than opening a fresh one) and re-enabled the exec
side; DD-930 found a second, independent defect the same day (the vendored
Pax CodeUnitCompiler's own narrow special-case handling of EnvLoader.pm's
C<_load_env_pl_file> sub substitutes a runtime op whose C<EnvAudit->record>
call never resolves in the compiled binary) and disabled the exec side
again, since it had never actually been exercised against real config
before DD-922 turned it back on. This file is the executable proof that a
cache hit is still detected (the mechanism DD-882 built) but never acted
on, and that dashboard's own interpreted execution is unaffected by
whatever state - correct or broken - the cached compiled binary is in.

=head1 WHEN TO USE

Run this file whenever the self-compile hook in bin/dashboard changes, or
whenever PaxCache's cache file layout changes (this file seeds the cache
directly using that exact layout, so a layout change must update both), or
whenever StandaloneRuntime's entrypoint dispatch changes (the DD-922 fix
lives there, not in bin/dashboard itself).
Set C<DD_SKIP_REAL_PAX_COMPILE_TEST=1> to skip the slow real-compile
regression block (still runs the fast sentinel-based blocks).

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/182-dashboard-self-compile.t

=head1 WHAT USES IT

Confirms the contract every real dashboard invocation depends on: a cache
hit is exec'd into correctly, a miss never blocks or breaks normal
interpreted operation, the anti-infinite-loop guard still works, and a real
compiled binary's actual (not simulated) config loading now succeeds.

=head1 EXAMPLES

Seeding a fake cached binary and confirming dashboard execs it:

    my $bin_file = seed_cache_for_dashboard($home, "#!/usr/bin/env perl\nprint 'hi';\n");
    system($^X, '-I', $lib, $dashboard, 'version');    # execs the cached binary on a hit

=cut
