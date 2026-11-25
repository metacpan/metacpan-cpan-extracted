#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use Cwd qw(getcwd abs_path);

# The gate under test, resolved from THIS file's location so the spec works from
# any working directory - which is itself the property the spec is about.
my $GATE = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'script', 'coverage-gate' );

plan skip_all => "coverage-gate not found at $GATE" if !-f $GATE;

# Devel::Cover is an optional development tool, not a declared runtime
# dependency. Without it the gate takes a different and correct path - it
# reports that Devel::Cover::DB::IO could not be loaded and exits 2 before
# it ever announces a database - so the two blocks below, which need the
# gate to reach its announcement, cannot be measured at all, and their
# assertions would report an environmental gap as a defect. The divergence
# block needs no Devel::Cover (the refusal fires first) and still runs
# everywhere, including Windows. Same guard as t/148, t/151, t/149 and
# t/150. This file is NOT in t/170's @SPECS list: t/170's contract is for
# file-level skip_all specs, and this file runs 3 tests and skips 4, so
# adding it would fail t/170's first assertion.
my $HAS_COVER = eval { require Devel::Cover::DB::IO; 1 } ? 1 : 0;

# Purpose: build a throwaway directory that IS a real git checkout.
# Input:   nothing.
# Output:  the absolute path of the new checkout.
#
# It has to be a REAL checkout, not merely a directory: the whole point of the
# narrow phrasing under test is that the refusal fires only when BOTH sides
# resolve as checkouts, so a fixture that skips `git init` would silently
# exercise the other branch and pass for the wrong reason.
sub temp_checkout {
    my $dir = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $dir, 'script' ) );
    # List form, no shell: the old
    #   system("git init -q '$dir' >/dev/null 2>&1")
    # never ran git on Windows - cmd.exe has no /dev/null, so the redirect
    # itself failed with "The system cannot find the path specified" and no
    # .git was created (round 73, twice - once per checkout). -q keeps a
    # successful init silent, so no output suppression is needed.
    system( 'git', 'init', '-q', $dir ) == 0 or die "git init failed for $dir: $?";
    return abs_path($dir);
}

# Purpose: copy the gate (and its checker sibling, which it refuses without)
#          into a directory, making that directory look like a repository root.
# Input:   the destination root.
# Output:  the path of the copied gate.
sub install_gate {
    my ($root) = @_;
    my $dest = File::Spec->catfile( $root, 'script', 'coverage-gate' );
    _copy( $GATE, $dest );
    my $checker = File::Spec->catfile( $FindBin::Bin, File::Spec->updir, 'script', 'check-all-metric-coverage' );
    _copy( $checker, File::Spec->catfile( $root, 'script', 'check-all-metric-coverage' ) ) if -f $checker;
    chmod 0755, $dest;
    return $dest;
}

# Purpose: copy one file. Input: source and destination. Output: nothing; dies.
sub _copy {
    my ( $from, $to ) = @_;
    open my $in,  '<', $from or die "cannot read $from: $!";
    local $/ = undef;
    my $content = <$in>;
    close $in;
    open my $out, '>', $to or die "cannot write $to: $!";
    print {$out} $content;
    close $out or die "cannot close $to: $!";
    return;
}

# Purpose: run a gate with a chosen working directory and capture everything.
# Input:   the gate path, the directory to run from, and extra arguments.
# Output:  hashref with exit status, and the combined output.
#
# NO --database IS PASSED, deliberately. Every other coverage-gate spec in this
# repository overrides it for lock safety, which is exactly why none of them can
# see a defect in the DEFAULT resolution. --dry-run keeps that safe: it builds
# the delete command and returns before running it.
sub run_from {
    my ( $gate, $dir, @args ) = @_;
    my $prev = getcwd();
    chdir $dir or die "cannot enter $dir: $!";
    # Capture::Tiny + list form, no shell: the old
    #   system("perl '$gate' --dry-run ... > '$out' 2>&1")
    # never wrote $out on Windows - cmd.exe does not interpret Unix single
    # quotes, so the redirect target was invalid ("The filename, directory
    # name, or volume label syntax is incorrect") and the read below died
    # at line 76 (round 73). The refusal is printed on stderr, so both
    # streams are captured and concatenated. $^X is the selected Perl on
    # every platform, as the gate itself does for its child probe.
    my ( $stdout, $stderr, $status ) = capture { system( $^X, $gate, '--dry-run', @args ) };
    chdir $prev or die "cannot return to $prev: $!";
    return { status => $status, output => ( $stdout // '' ) . ( $stderr // '' ) };
}

# AC-2: BOTH sides are real checkouts and they DIFFER -> refuse, naming both.
{
    my $gate_root   = temp_checkout();
    my $caller_root = temp_checkout();
    my $gate        = install_gate($gate_root);

    my $r = run_from( $gate, $caller_root );

    isnt( $r->{status}, 0,
        'AC-2: the gate refuses when its own repository and the caller cwd are different checkouts' );
    like( $r->{output}, qr/\Q$gate_root\E/,
        'AC-2: the refusal names the tree it would have graded' );
    like( $r->{output}, qr/\Q$caller_root\E/,
        'AC-2: and names the tree the caller was standing in' );
}

# AC-3: only ONE side is a checkout -> proceed, exactly as t/151 depends on.
SKIP: {
    skip 'Devel::Cover is not installed, so the coverage gate cannot be exercised', 2
        if !$HAS_COVER;

    my $gate_root = tempdir( CLEANUP => 1 );      # NOT a git checkout
    make_path( File::Spec->catdir( $gate_root, 'script' ) );
    my $gate = install_gate($gate_root);

    my $r = run_from( $gate, getcwd() );          # cwd IS a checkout

    is( $r->{status}, 0,
        'AC-3: no refusal when the gate lives outside any checkout - the narrow phrasing t/151 depends on' );
    unlike( $r->{output}, qr/refus|different checkout/i,
        'AC-3: and it does not complain about a divergence that is not one' );
}

# AC-5: the resolved target is reported as an ABSOLUTE path.
SKIP: {
    skip 'Devel::Cover is not installed, so the coverage gate cannot be exercised', 2
        if !$HAS_COVER;

    my $gate_root = temp_checkout();
    my $gate      = install_gate($gate_root);

    my $r = run_from( $gate, $gate_root );        # same tree: no divergence

    is( $r->{status}, 0, 'AC-5: running inside its own checkout is not a divergence' );
    # The gate prints the resolved database with native separators while
    # abs_path spells the root with forward slashes on Windows, so compare
    # separator-normalised copies (t/146). Only the first alternative can
    # match there - the second needs a leading slash the drive letter
    # replaces - and that is enough: root + /cover_db IS the absolute path.
    ( my $db_out = $r->{output} ) =~ s{\\}{/}g;
    like( $db_out, qr{\Q$gate_root\E/cover_db|database\s*:\s*/},
        'AC-5: the database is reported as a RESOLVED ABSOLUTE path, not the relative name "cover_db" which is identical from every tree' );
}

done_testing;

__END__

=head1 NAME

t/169-gate-target-resolution.t - which tree the coverage gate actually measures

=head1 PURPOSE

Pins the tree-resolution contract of C<script/coverage-gate>: it refuses when
its own repository and the caller's working directory are two DIFFERENT git
checkouts, proceeds when only one side is a checkout, and reports the database
it resolved as an absolute path.

=head1 WHY IT EXISTS

The gate derives its repository from its own file location and changes into it.
Because the operator tooling is git-ignored, a sandbox can only reach the gate
through the main checkout's absolute path - and doing so measured the main
checkout while the caller believed the sandbox was being graded. The run
succeeded and printed nothing naming either tree.

No existing coverage-gate spec could catch this. They all pass an explicit
C<--database> so their runs cannot contend with a real gate holding that lock,
and that override is precisely what stops them exercising the default
resolution. This file passes no C<--database> for that reason.

=head1 WHEN TO USE

Run it after any change to how a gate tool resolves its repository, its database
or its test paths, and after any change to the refusal's wording - the assertions
require the refusal to NAME both trees, because a refusal that does not is one a
reader cannot act on.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/169-gate-target-resolution.t

=head1 WHAT USES IT

The full suite under C<prove -lr t>, and the coverage gate that reads it.

=head1 EXAMPLES

The failure this pins, reproduced by hand:

    cd /home/mv/Sandbox/ddd/dd-744
    perl /home/mv/projects/developer-dashboard/script/coverage-gate --dry-run

Before the fix this exits 0 and reports C<database : cover_db> - a relative name,
byte-identical from either tree, which is why reading that output cannot detect
the problem. The live child's working directory, read from C</proc/PID/cwd>,
showed C</home/mv/projects/developer-dashboard>.

=cut
