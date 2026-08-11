use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $TEST_DIR = File::Spec->catdir( $ROOT, 't' );

plan skip_all => 'worktree source-tree detection is a source-tree-only check'
  if !-e File::Spec->catdir( $ROOT, '.git' ) || !-d $TEST_DIR;

plan skip_all => 'worktree source-tree detection requires git on PATH'
  if !_find_command('git');

# --------------------------------------------------------------------------
# 1. Pin the underlying fact: in a LINKED worktree, .git is a FILE, not a dir.
#    This is the whole root cause, so it is asserted directly rather than
#    assumed. If a future git ever changes this, the guard below stops being
#    necessary and this assertion is what will say so.
# --------------------------------------------------------------------------
my $scratch = tempdir( CLEANUP => 1 );
my $linked = File::Spec->catdir( $scratch, 'linked' );

my ( $add_out, $add_err, $add_exit ) = capture {
    system( 'git', '-C', $ROOT, 'worktree', 'add', '--detach', '--quiet', $linked, 'HEAD' );
};

if ( $add_exit != 0 ) {
    diag("git worktree add failed:\n$add_err$add_out");
    plan skip_all => 'this checkout cannot create a linked git worktree';
}

my $linked_git = File::Spec->catdir( $linked, '.git' );

ok( -e $linked_git, 'a linked worktree has a .git entry' );
ok( !-d $linked_git, 'a linked worktree .git is NOT a directory - a -d gate would miss it' );
ok( -f $linked_git, 'a linked worktree .git is a regular file' );
like( _slurp_path($linked_git), qr/\Agitdir:\s*\S/, 'the linked worktree .git file holds a gitdir pointer' );

# --------------------------------------------------------------------------
# 2. Prove the consequence end to end: the Scorecard guardrail file must
#    actually run inside that worktree instead of skipping itself away. This
#    is the assertion that was red before the detection fix.
# --------------------------------------------------------------------------
my $guardrail_name = '34-scorecard-guardrails.t';
my $guardrail = File::Spec->catfile( $linked, 't', $guardrail_name );

ok( -f $guardrail, "the linked worktree carries t/$guardrail_name" );

# Grade the WORKING TREE, not the one git checked out. A linked worktree is
# created from a commit, so without this the gate would only ever see the last
# committed state - it would pass while an uncommitted regression sat in the
# tree, and fail an otherwise correct fix until it was committed. Staging the
# live files in makes this a pre-commit gate, which is the only useful kind.
#
# Staging only the file under test is not enough, because t/34 is a guardrail
# file ABOUT other repo files: it reads LICENSE, SECURITY.md, the Dependabot
# config, four workflow files, the ClusterFuzzLite Dockerfile, package.json and
# package-lock.json. Leaving those at their committed content broke the gate in
# both directions - an uncommitted guardrail fix read as a failure, and, far
# worse, an uncommitted guardrail REGRESSION read as a pass because the nested
# run never saw it. Mirror every tracked path that differs from HEAD instead.
#
# Bounded to `git diff --name-only HEAD` on purpose: that covers tracked
# modifications and staged additions, while an untracked sweep from the repo
# root would drag in .worktrees/ and dogfood-output/, which are untracked but
# deliberately NOT git-ignored. A brand-new file must therefore be `git add`ed
# to be graded here, which is how it would join the change anyway.
my ( $dirty_out, $dirty_err, $dirty_exit ) = capture {
    system( 'git', '-C', $ROOT, 'diff', '--name-only', 'HEAD' );
};
is( $dirty_exit, 0, 'the working-tree difference against HEAD can be listed' )
  or diag("git diff failed:\n$dirty_err");

my @staged;
for my $relative ( grep { length } split /\n/, ( $dirty_out // q{} ) ) {
    my @parts = split m{/}, $relative;
    my $source = File::Spec->catfile( $ROOT,   @parts );
    my $target = File::Spec->catfile( $linked, @parts );

    # A path can differ from HEAD by having been deleted in the working tree,
    # in which case it must disappear from the nested run too rather than be
    # copied.
    if ( !-f $source ) {
        unlink $target or die "Unable to unstage $relative from the linked worktree: $!"
          if -e $target;
        next;
    }

    my $target_dir = dirname($target);
    make_path($target_dir) if !-d $target_dir;
    copy( $source, $target )
      or die "Unable to stage $relative into the linked worktree: $!";
    push @staged, $relative;
}

# The file under test is staged explicitly as well, so the gate still grades the
# live guardrail file even when it is the one thing that has not been modified.
copy( File::Spec->catfile( $TEST_DIR, $guardrail_name ), $guardrail )
  or die "Unable to stage $guardrail_name into the linked worktree: $!";

# Whenever the tree actually is mid-change, prove the mirror is byte-exact. On a
# clean tree there is nothing to compare and this is vacuous - the load-bearing
# proof in that case is the nested run below, which reads the real files.
my @unmirrored =
  grep { _slurp_path( File::Spec->catfile( $ROOT, split m{/}, $_ ) ) ne
         _slurp_path( File::Spec->catfile( $linked, split m{/}, $_ ) ) } @staged;
is_deeply( \@unmirrored, [],
    'every working-tree modification is mirrored byte-for-byte into the linked worktree' )
  or diag( "paths that did not mirror:\n" . join( "\n", @unmirrored ) );

my ( $tap, $tap_err, $tap_exit ) = capture {
    local %ENV = %ENV;

    # The nested run only has to answer "did this file plan any assertions",
    # so keep the parent's coverage instrumentation out of it.
    delete $ENV{HARNESS_PERL_SWITCHES};
    delete $ENV{PERL5OPT};

    system( $^X, $guardrail );
};

unlike( $tap, qr/^1\.\.0\b/m,
    "t/$guardrail_name does not skip itself inside a linked worktree" );
like( $tap, qr/^ok\s+1\b/m,
    "t/$guardrail_name runs real assertions inside a linked worktree" );
is( $tap_exit, 0, "t/$guardrail_name passes inside a linked worktree" )
  or diag("STDOUT:\n$tap\nSTDERR:\n$tap_err");

my ( undef, undef, $remove_exit ) = capture {
    system( 'git', '-C', $ROOT, 'worktree', 'remove', '--force', $linked );
};
is( $remove_exit, 0, 'the scratch linked worktree is removed again' );
remove_tree($linked) if -d $linked;

my ( undef, undef, $prune_exit ) = capture {
    system( 'git', '-C', $ROOT, 'worktree', 'prune' );
};
is( $prune_exit, 0, 'git worktree bookkeeping is pruned after the scratch worktree' );

# --------------------------------------------------------------------------
# 3. Stop the pattern coming back anywhere else. A source-tree gate is one
#    that asks about the checkout root - either a bare relative '.git' or a
#    path built from the file's own $ROOT. Fixture code that builds a fake
#    checkout inside a tempdir legitimately creates and tests directories, so
#    only those two rooted forms are swept.
# --------------------------------------------------------------------------
opendir my $dh, $TEST_DIR or die "Unable to open $TEST_DIR: $!";
my @test_files = sort grep { /\.t\z/ } readdir $dh;
closedir $dh or die "Unable to close $TEST_DIR: $!";

cmp_ok( scalar @test_files, '>', 0, 'the sweep found test files to inspect' );

my @offenders;
for my $file (@test_files) {
    my $text = _slurp_path( File::Spec->catfile( $TEST_DIR, $file ) );
    my $line_number = 0;

    for my $line ( split /\n/, $text ) {
        $line_number++;
        next if $line =~ /^\s*#/;

        push @offenders, "t/$file:$line_number: $line"
          if $line =~ m{-d \s* ['"]\.git['"]}x
          || $line =~ m{-d [^;\n]* \$ROOT [^;\n]* ['"]\.git['"]}x;
    }
}

is_deeply( \@offenders, [],
    'no test decides it is in a source checkout by testing .git as a directory' )
  or diag( "directory-only .git source-tree gates found:\n" . join( "\n", @offenders ) );

done_testing;

# Purpose: locate an executable by name on PATH.
# Input:   the command name.
# Output:  the full path to the executable, or undef when it is not on PATH.
sub _find_command {
    my ($name) = @_;
    for my $dir ( split /:/, ( $ENV{PATH} || q{} ) ) {
        my $candidate = File::Spec->catfile( $dir, $name );
        return $candidate if -x $candidate;
    }
    return;
}

# Purpose: read a whole file as raw bytes.
# Input:   an absolute path.
# Output:  the file contents as a single string; dies when it cannot be read.
sub _slurp_path {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

__END__

=head1 NAME

t/139-worktree-source-tree-detection.t - keep source-tree gates awake inside git worktrees

=head1 PURPOSE

A regression gate for DD-437. It pins that no test in this repository decides
whether it is running inside a source checkout by testing C<.git> as a
directory, and it proves end to end that the Scorecard guardrail file really
executes inside a linked git worktree instead of skipping itself away.

=head1 WHY IT EXISTS

In the primary checkout C<.git> is a directory. In a linked worktree it is a
regular file holding a C<gitdir:> pointer to the shared repository. A gate
written as C<-d .git> is therefore false in every worktree, and a file that
opens with C<plan skip_all> on that gate deletes itself there completely.

That is exactly what happened to the Scorecard and supply-chain guardrails.
All ticket work in this repository is done in per-ticket worktrees, so the file
holding the action SHA pins, the workflow permission-scoping assertions and the
dependency major-version floors was silently inert at the precise moment a
change was being authored and first verified. It only woke up later, on a run
from the primary checkout. A guardrail absent at authorship time is worse than
a missing one, because a green worktree run reads as evidence it never was.

=head1 WHAT IT GRADES

The scratch worktree is created from a commit, so on its own it would only ever
see committed content. Every tracked path that differs from C<HEAD> is therefore
mirrored into it before the nested run, and the mirror is asserted to be
byte-exact.

That breadth is the point, and DD-438 exists because staging only the file under
test was not enough. C<t/34-scorecard-guardrails.t> is a guardrail file I<about>
other repository files - it reads the root licence and security policy, the
Dependabot config, four workflow files, the ClusterFuzzLite Dockerfile,
C<package.json> and C<package-lock.json>. While those stayed at their committed
content the gate was
wrong in both directions: an uncommitted guardrail fix was reported as a
failure, and an uncommitted guardrail B<regression> was reported as a pass. The
second is the dangerous one - an action SHA unpinned in the working tree, or a
dependency floored back onto an abandoned major, passed here while the guardrail
file itself failed on the same tree.

The mirror is bounded to C<git diff --name-only HEAD>, which covers tracked
modifications and staged additions. A brand-new file must be added to the index
to be graded, because an untracked sweep from the repository root would pull in
the per-ticket worktree and dogfood output directories, which are untracked but
deliberately not ignored.

=head1 WHEN TO USE

Run it whenever a test gains a source-tree detection gate, whenever a file
gains a C<plan skip_all> that depends on the checkout layout, and after any git
upgrade that could change how linked worktrees are represented on disk.

=head1 HOW TO USE

  prove -lv t/139-worktree-source-tree-detection.t

=head1 WHAT USES IT

The repository test suite, through C<prove -lr t>, and any round of work done
inside a per-ticket worktree that relies on the guardrail files being awake.

=head1 EXAMPLES

Run the gate on its own:

  prove -lv t/139-worktree-source-tree-detection.t

Run it beside the two files whose detection it protects:

  prove -lv t/13-integration-assets.t t/34-scorecard-guardrails.t t/139-worktree-source-tree-detection.t

Run it from inside a linked worktree, which is where the defect it guards
against used to hide:

  git worktree add ../scratch-check HEAD
  cd ../scratch-check && prove -lv t/139-worktree-source-tree-detection.t

=cut
