#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use Test::More;

my $ROOT   = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $SUBJECT = File::Spec->catfile( $ROOT, 't', '158-operator-tool-specs.t' );

plan skip_all => "subject spec not present at $SUBJECT" if !-f $SUBJECT;

# Purpose: build a synthetic source tree and run the subject spec inside it.
# Input:   %opt - git => 1 to create a .git marker, tools => 1 to create
#          .claude/tools with one spec-shaped file in it.
# Output:  the subject's combined output.
#
# $ROOT in the subject is FindBin::Bin/updir, so copying it into <tmp>/t/ makes
# <tmp> its root. That is the whole mechanism, and it is why this can exercise
# the guard without touching the real checkout. The idiom - copy a spec into a
# scratch tree and run it under capture - is t/139's, which guards the sibling
# `-e` versus `-d` property of the same condition.
sub _run_subject {
    my (%opt) = @_;
    my $tree = tempdir( CLEANUP => 1 );
    make_path( File::Spec->catdir( $tree, 't' ) );
    copy( $SUBJECT, File::Spec->catfile( $tree, 't', '158-operator-tool-specs.t' ) )
      or die "cannot copy subject: $!";

    if ( $opt{git} ) {
        open my $fh, '>', File::Spec->catfile( $tree, '.git' )
          or die "cannot write .git marker: $!";
        print {$fh} "gitdir: /nonexistent\n";
        close $fh;
    }
    if ( $opt{tools} ) {
        my $tools = File::Spec->catdir( $tree, '.claude', 'tools' );
        make_path($tools);
        open my $fh, '>', File::Spec->catfile( $tools, 't-placeholder' )
          or die "cannot write placeholder tool spec: $!";
        print {$fh} "#!/bin/sh\nexit 0\n";
        close $fh;
    }

    my ( $out, $err ) = capture {
        system( $^X, File::Spec->catfile( $tree, 't', '158-operator-tool-specs.t' ) );
    };
    return "$out$err";
}

# THE THREE TREE STATES. Only A and B are skips; C must still RUN, and it is here
# because a fix that made every state skip informatively would satisfy the two
# skip assertions and be a regression.
my $case_a = _run_subject( git => 1, tools => 0 );   # source tree, tools absent - every CI run
my $case_b = _run_subject( git => 0, tools => 0 );   # installed copy - nothing to run
my $case_c = _run_subject( git => 1, tools => 1 );   # both present - must RUN

like $case_a, qr/\bSKIP\b/i, 'case A (source tree, no tools) skips';
like $case_b, qr/\bSKIP\b/i, 'case B (installed copy) skips';

# AC-1. THE DEFECT: both causes print one sentence, so a CI skip is announced in
# the words of the benign installed-copy skip. Asserting on the EMITTED TEXT, not
# on the source line, so a refactor of how the message is built cannot drop it.
my ($reason_a) = $case_a =~ /SKIP\s+(.*)/i;
my ($reason_b) = $case_b =~ /SKIP\s+(.*)/i;
isnt $reason_a, $reason_b,
  'the two skip causes report DIFFERENTLY - a source tree missing its tools is not an installed copy';

# AC-2. The CI case must name what did not run, not just a path that is absent.
like $case_a, qr/spec/i,
  'the source-tree skip names the specs that did not run here';

# AC-3 in the other direction: the benign case keeps a benign message, so this
# cannot be satisfied by making every skip alarming.
unlike $case_b, qr/spec/i,
  'the installed-copy skip stays quiet - it has genuinely nothing to run';

# AC-5. The case a careless fix breaks, and neither skip assertion would catch.
unlike $case_c, qr/\bSKIP\b/i,
  'case C (both present) still RUNS - the fix must not turn a working tree into a skip';

done_testing;

__END__

=head1 NAME

t/174-a-skip-that-cannot-say-why.t - grade whether t/158's skip says WHICH condition fired

=head1 PURPOSE

Assert that C<t/158-operator-tool-specs.t> reports its two skip causes
differently: a source tree whose operator tools are absent is not the same
event as an installed copy that has nothing to run, and today both print one
sentence.

=head1 WHY IT EXISTS

C<.claude/> is operator-local and carries zero paths on C<origin/master>, so
C<t/158>'s guard is false on every CI run - its twenty operator specs have never
executed there. That skip is announced in the words of the benign
installed-copy case, so it reads as expected rather than as a gap.

This project already requires every checker to distinguish B<clean> from
B<could-not-look>, because a checker that dies quietly reads exactly like one
that found nothing. A skip is the same decision-not-to-measure, in test output,
and it is the one place the rule was never applied. See the SYSTEM-scoped page
in the docs vault on why a skip that cannot say WHY is a checker that cannot
say could-not-look.

The file count cannot substitute for this: C<prove> counts a C<skip_all> file in
C<Files=>, so a skipping run and a running one report the same total.

=head1 WHEN TO USE

On any change to C<t/158>'s guard, its message, or the layout of C<.claude/>.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/174-a-skip-that-cannot-say-why.t

=head1 WHAT USES IT

The full suite (C<prove -lr t>), and therefore every gate that runs it.

=head1 EXAMPLES

The output this file is written against, which both states produce today:

    1..0 # SKIP not a source tree, or no operator tools directory

Case A is a source tree missing its tools - every CI run and every sandbox.
Case B is an installed copy. They must not read alike.

=cut
