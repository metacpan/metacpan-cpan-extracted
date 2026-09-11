#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec;
use FindBin;
use Test::More;

my $ROOT  = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $TOOLS = File::Spec->catdir( $ROOT, '.claude', 'tools' );

# .claude/ is operator-local and excluded from the tarball by dist.ini, so an
# installed copy has no tools directory and nothing here to run. -e rather than -d
# on .git, because a linked worktree keeps .git as a FILE holding a gitdir
# pointer, and a -d test switched a whole guard off in exactly the place all
# ticket work is authored (t/139 guards that pattern).
# TWO CAUSES, TWO MESSAGES (DD-797). These are not the same event and reporting
# them in one sentence is what hid the second for as long as .claude/ has been
# out of git:
#
#   no .git        an installed copy from the tarball. There is genuinely nothing
#                  here to run, skipping is correct, and it needs no attention.
#   .git, no tools a SOURCE TREE MISSING ITS OPERATOR TOOLS - every CI run, since
#                  origin/master carries zero .claude paths, and every sandbox.
#                  The specs exist; they are not reachable from here. That is a
#                  gap, and it used to announce itself in the words of the case
#                  above.
#
# This project already requires every checker to separate CLEAN from
# COULD-NOT-LOOK. A skip is the same decision-not-to-measure, and this is where
# that rule was missing. It still SKIPS rather than fails: the absence is a
# deliberate operator-local choice, and reddening CI for it would punish everyone
# for a decision made on purpose.
plan skip_all => 'not a source tree - no .git here, so this is an installed copy with nothing to run'
  if !-e File::Spec->catdir( $ROOT, '.git' );

plan skip_all => "operator tool specs are not reachable from this tree: $TOOLS does not exist, "
  . 'so none of them ran here. .claude/ is operator-local and carries no paths on origin/master, '
  . 'which is why this skip is the normal state in CI and in every sandbox'
  if !-d $TOOLS;

# WHY THIS FILE EXISTS (DD-573)
#   Thirteen spec files sat under .claude/tools/ and NOTHING executed any of
#   them. prove -lr t reaches only t/; no cron line named them; no workflow or
#   script referenced them. Five of the thirteen were written in a single night
#   by an author who believed that writing a spec protects the tool.
#
#   It does not. A spec nobody runs cannot fail, so it protects nothing while
#   LOOKING like protection - the shape this project has recorded twice already,
#   as a guardrail whose clean report nobody had seen it earn, and as a sweep
#   whose cron line failed before the script was reached, silently, for its whole
#   life.

opendir my $dh, $TOOLS or die "cannot read $TOOLS: $!";
my @specs = sort grep { /\At-/ && !/\.py\z/ } readdir $dh;
closedir $dh;

# A test aimed at an empty set can only return the answer it hoped for. If the
# prefix or the directory ever changes, this must go red rather than pass by
# finding nothing to check.
cmp_ok( scalar @specs, '>=', 13,
    'the operator tools directory still holds its specs (found ' . scalar(@specs) . ')' );

for my $spec (@specs) {
    my $path = File::Spec->catfile( $TOOLS, $spec );

    # THE INTERPRETER COMES FROM THE SHEBANG, and that is not a nicety. Running
    # the Perl specs under bash once reported 11 of 13 as failing when every one
    # of them was fine. A runner that hard-codes an interpreter reproduces that
    # false alarm on every run, and a checker that cries wolf immediately is one
    # nobody keeps.
    open my $fh, '<', $path or do { fail("$spec is unreadable: $!"); next };
    my $shebang = <$fh>;
    close $fh;
    my $interpreter = ( $shebang // '' ) =~ /perl/ ? 'perl' : 'bash';

    my $output = `$interpreter \Q$path\E 2>&1`;
    my $status = ${^CHILD_ERROR_NATIVE} >> 8;
    is( $status, 0, "$spec passes (run under $interpreter)" )
      or diag( "--- $spec output ---\n" . ( $output // '' ) );
}

done_testing;

__END__

=head1 NAME

t/158-operator-tool-specs.t - run the specs that guard this project's operator
tools

=head1 PURPOSE

Discover every specification file under C<.claude/tools/> and execute it, so the
guards written for the operator tooling are exercised by the suite rather than
sitting unexecuted beside it.

=head1 WHY IT EXISTS

Thirteen spec files existed and nothing ran any of them: the suite reaches only
F<t/>, no schedule named them, and no workflow referenced them. They all passed
when finally run by hand - which is the point rather than the reassurance. They
were correct that day, and nothing would have reported the day they stopped
being.

=head1 WHEN TO USE

Every suite run. Also whenever a new operator tool gains a spec, since this file
discovers specs rather than listing them, and a new one is picked up with no
change here.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/158-operator-tool-specs.t

=head1 WHAT USES IT

The suite, through C<prove -lr t>, and therefore CI. Its subjects are the
C<t-*> files in F<.claude/tools/>.

=head1 EXAMPLES

To watch it fail, break an assertion in any spec under the tools directory and
rerun; the failing spec is named and its output shown.

=cut
