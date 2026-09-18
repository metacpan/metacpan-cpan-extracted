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
my $d2        = File::Spec->catfile( $repo_root, 'bin', 'd2' );

# Same MD5-keyed cache layout PaxCache.pm uses, this time keyed on d2's OWN
# source path (not dashboard's) - d2 is a distinct compile target from
# dashboard, so it gets its own cache entry under the same md5-of-path key
# scheme (see t/182 for the dashboard-side twin of this test).
sub seed_cache_for_d2 {
    my ( $home, $binary_contents ) = @_;
    my $cache_dir = File::Spec->catdir( $home, '.developer-dashboard', 'cache', 'pax' );
    make_path($cache_dir);
    my $key = Digest::MD5::md5_hex($d2);

    open my $sfh, '<:raw', $d2 or die "Unable to read $d2: $!";
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

# DD-882 (owner correction, Telegram msg #2001): d2, not only dashboard, must
# check its OWN source MD5 and exec a matching cached compiled binary
# directly - the owner named both entrypoints explicitly and separately
# tested `file ~/perl5/bin/d2`.
{
    my $home = tempdir( CLEANUP => 1 );
    seed_cache_for_d2(
        $home,
        "#!/usr/bin/env perl\nprint \"DD882-D2-SENTINEL-COMPILED-OUTPUT\\n\";\n"
    );

    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        system( $^X, '-I', $lib, $d2, 'version' );
    };
    is( $exit >> 8, 0, 'DD-882: d2 exits cleanly when a matching self-compiled binary is cached for d2 itself' );
    like(
        $out,
        qr/DD882-D2-SENTINEL-COMPILED-OUTPUT/,
        'DD-882: d2 execs its own cached self-compiled binary directly on a cache hit, instead of re-execing interpreted dashboard'
    );
}

# No cache present: falls through to the existing, unchanged behavior of
# re-execing sibling dashboard interpreted.
{
    my $home = tempdir( CLEANUP => 1 );
    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        local $ENV{PATH} = '/nonexistent-empty-dir-for-this-test';
        system( $^X, '-I', $lib, $d2, 'version' );
    };
    is( $exit >> 8, 0, 'DD-882: d2 exits cleanly with no cached self-binary' );
    like( $out, qr/\A\d+\.\d+\s*\z/, 'DD-882: d2 re-execs dashboard interpreted normally with no cached self-binary' );
}

# Safety: the shared guard env var (already set, e.g. because dashboard's own
# hook already fired once in this process tree) must stop d2 from attempting
# its own self-exec too, even though its cache matches.
{
    my $home = tempdir( CLEANUP => 1 );
    seed_cache_for_d2(
        $home,
        "#!/usr/bin/env perl\nprint \"DD882-D2-SENTINEL-SHOULD-NOT-RUN\\n\";\nexit 1;\n"
    );

    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME} = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        local $ENV{DEVELOPER_DASHBOARD_PAX_SELF_EXECED} = 1;
        system( $^X, '-I', $lib, $d2, 'version' );
    };
    is( $exit >> 8, 0, 'DD-882: with the self-exec guard already set, d2 still exits cleanly' );
    unlike(
        $out,
        qr/DD882-D2-SENTINEL-SHOULD-NOT-RUN/,
        'DD-882: with the self-exec guard already set, d2 never execs its own cached binary even though it matches'
    );
    like( $out, qr/\A\d+\.\d+\s*\z/, 'DD-882: with the guard set, d2 falls through to its normal re-exec of dashboard' );
}

# DD-924: a REAL PAX-compiled d2 binary, not merely the hand-written sentinel
# used above, must correctly fall through to dashboard when it re-runs its
# own internal exec-into-dashboard fallback line. That line computes its
# target path from $Bin, and inside a genuinely compiled binary FindBin's
# $Bin resolves to wherever the RUNNING COMPILED BINARY physically lives
# (PaxCache's cache directory) rather than to bin/'s real location - a defect
# the sentinel above is structurally unable to exercise, since it never runs
# any of d2's own compiled body. This builds a real standalone binary from
# bin/d2 itself (via share/private-cli/pax, the same build path
# t/183-pax-cli-build-run-contract.t exercises for its own contract) and
# seeds it into the cache exactly as a genuine self-compile would leave it.
{
    my $home         = tempdir( CLEANUP => 1 );
    my $real_binary  = File::Spec->catfile( $home, 'd2-real-compiled.pax' );
    my $pax          = File::Spec->catfile( $repo_root, 'share', 'private-cli', 'pax' );

    my ( $build_out, $build_err, $build_exit ) = capture {
        local $ENV{PERL5LIB} = defined $ENV{PERL5LIB} && $ENV{PERL5LIB} ne ''
            ? "$lib:$ENV{PERL5LIB}"
            : $lib;
        system( $^X, $pax, 'build', '--compact', $d2, '-o', $real_binary );
        return $? >> 8;
    };
    is( $build_exit, 0, 'DD-924: pax build compiles a real standalone binary from bin/d2 itself' )
        or diag("build stdout: $build_out\nbuild stderr: $build_err");
    ok( -x $real_binary, 'DD-924: the real compiled d2 binary is executable' );

    open my $rbfh, '<:raw', $real_binary or die "Unable to read $real_binary: $!";
    local $/;
    my $real_binary_contents = <$rbfh>;
    close $rbfh;

    seed_cache_for_d2( $home, $real_binary_contents );

    my ( $out, $err, $exit ) = capture {
        local $ENV{HOME}          = $home;
        local $ENV{HARNESS_ACTIVE} = 0;
        system( $^X, '-I', $lib, $d2, 'version' );
    };
    is( $exit >> 8, 0,
        'DD-924: d2 execs the real compiled binary, whose own internal exec-into-dashboard fallback succeeds'
    ) or diag("stdout: $out\nstderr: $err");
    unlike( $err, qr/Can't open perl script/,
        q{DD-924: the compiled binary's own $Bin resolution does not point at the pax cache directory} );
    like( $out, qr/\A\d+\.\d+\s*\z/,
        'DD-924: the compiled binary correctly falls through to dashboard and prints its plain version' );
}

done_testing;

__END__

=head1 NAME

t/184-d2-self-compile.t - d2's own MD5-checked self-compile hook

=head1 PURPOSE

Exercises DD-882's requirement that C<d2>, not only C<dashboard>, checks its
own source MD5 against PaxCache's cache and execs a matching cached compiled
binary directly, sharing the C<DEVELOPER_DASHBOARD_PAX_SELF_EXECED> guard
with dashboard's own hook so neither entrypoint double-triggers a self-exec
in the same process tree.

=head1 WHY IT EXISTS

The owner named both C<d2> and C<dashboard> explicitly (Telegram msg #2001,
2026-09-15) and personally tested C<file ~/perl5/bin/d2> - relying only on
d2's unconditional re-exec into interpreted dashboard (whose own hook would
then fire) does not satisfy that: it costs an extra process hop through the
interpreter before the compiled binary is ever reached. This file is the
executable proof d2 checks itself directly.

=head1 WHEN TO USE

Run this file whenever the self-compile hook in bin/d2 changes, or whenever
PaxCache's cache file layout changes (this file seeds the cache directly
using that exact layout, so a layout change must update both this file and
its t/182 dashboard-side twin).

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/184-d2-self-compile.t

=head1 WHAT USES IT

Confirms the contract every real C<d2> invocation depends on: a fresh
compiled binary for d2 itself is used transparently when available, a miss
falls through to the existing sibling-dashboard re-exec unchanged, and the
shared guard prevents either entrypoint's hook from re-triggering the other.
DD-924's block additionally confirms that a REAL C<pax>-compiled d2 binary's
own internal fallback into C<dashboard> actually works at runtime, not just
that d2 dispatches to it - the sentinel-based blocks above cannot exercise
that, since a hand-written sentinel never runs any of d2's own compiled body.

=head1 EXAMPLES

Seeding a fake cached binary for d2 and confirming d2 execs it directly:

    my $bin_file = seed_cache_for_d2($home, "#!/usr/bin/env perl\nprint 'hi';\n");
    system($^X, '-I', $lib, $d2, 'version');    # runs the sentinel, not dashboard

Building and seeding a REAL compiled d2 binary (DD-924), then confirming its
own internal fallback into dashboard succeeds rather than failing on a
miscomputed C<$Bin>:

    system($^X, $pax, 'build', '--compact', $d2, '-o', $real_binary);
    seed_cache_for_d2($home, do { open my $fh, '<:raw', $real_binary; local $/; <$fh> });
    system($^X, '-I', $lib, $d2, 'version');    # runs the REAL compiled binary

=cut
