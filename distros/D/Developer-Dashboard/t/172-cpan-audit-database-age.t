#!/usr/bin/env perl

use strict;
use warnings;

use Developer::Dashboard::PerlEnv;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use POSIX qw(strftime);
use Time::Local qw(timegm);
use Test::More;

my $ROOT       = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $PERL_GATE  = File::Spec->catfile( $ROOT, 'script', 'cpan-audit-declared-chain' );
my $BASH_GATE  = File::Spec->catfile( $ROOT, 'script', 'cpan-audit-project' );
my $GATE_SRC   = $PERL_GATE;

plan skip_all => "declared-chain gate not present at $PERL_GATE" if !-f $PERL_GATE;
plan skip_all => "project gate not present at $BASH_GATE"        if !-f $BASH_GATE;

# WHY THIS FILE EXISTS (DD-790)
#   On 2026-09-06 both CVE gates reported the declared runtime closure clean.
#   The verdict was true of what they read and useless as an answer: the advisory
#   database was CPANSA::DB 20260807.001, thirty days old, and did not contain URI
#   at all. A real advisory against the installed URI 5.34 could not have been
#   reported by that run - not missed, but STRUCTURALLY UNREPORTABLE. The gate said
#   "clean" with exactly the confidence it uses when it has looked.
#
#   Upstream already knows a stale database is worth mentioning: cpan-audit --fresh
#   prints "Database is N days old" through CPAN::Audit::FreshnessCheck, with the
#   threshold in CPAN_AUDIT_FRESH_DAYS. Measured on 2026-09-06, that warning goes to
#   STDERR and does NOT change the exit code - 91 with the flag and 91 without. So no
#   caller reading a status can see it. That is the right call for an interactive
#   audit and the wrong one for a release gate, and this file pins the escalation:
#   the age reaches the VERDICT, and the corpus is NAMED on every run.
#
# WHAT THIS FILE DELIBERATELY DOES NOT ASSERT
#   It never accepts a bare exit 2 as proof of an age refusal. Both gates already
#   exit 2 for unrelated reasons - an unreadable root, absent .meta files, a
#   cpanfile with no runtime requirements - so an assertion on the status alone
#   would pass against the UNMODIFIED gates and certify nothing. Every check here
#   requires a positive marker that only the new code can emit: the database stamp
#   itself, or a refusal naming the age in days. This is the project's own
#   "verify the subject actually ran" rule, applied to an exit code that is already
#   reachable by another path.

# Purpose: an advisory-database stamp N days from today, in CPANSA's own
#          YYYYMMDD.NNN form.
# Input:   $days_ago - integer days before today.
# Output:  the stamp string.
#
# Computed from time() rather than written as a literal, so the file does not rot:
# a hardcoded "fresh" stamp becomes stale by the calendar and the test starts
# failing for a reason that has nothing to do with the code.
sub _stamp {
    my ($days_ago) = @_;
    return strftime( '%Y%m%d', localtime( time - $days_ago * 86_400 ) ) . '.001';
}

# Purpose: a library directory shadowing CPAN::Audit::DB with a chosen stamp.
# Input:   $stamp - the version the fake database reports.
# Output:  the directory to prepend to PERL5LIB.
#
# The Perl gate loads the database IN-PROCESS (require CPAN::Audit::DB), so a PATH
# shim cannot reach it - the mechanism that works for the bash gate is useless here.
# db() returns an empty dists map so the audit itself finds nothing: this file is
# about the CORPUS, and depending on the real advisory set would make it pass or
# fail for reasons unrelated to the code under test.
sub _fake_db_lib {
    my ($stamp) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    my $pkg = File::Spec->catdir( $dir, 'CPAN', 'Audit' );
    make_path($pkg);
    open my $fh, '>', File::Spec->catfile( $pkg, 'DB.pm' ) or die "cannot write fake DB: $!";
    print {$fh} <<"FAKE";
package CPAN::Audit::DB;
our \$VERSION = '$stamp';
sub db { return { dists => {} } }
1;
FAKE
    close $fh;

    # CPAN::Audit::Version IS FAKED TOO, and leaving it out is what turned master
    # red (DD-799). The gate requires BOTH modules; shadowing only the database
    # left this file depending on the REAL CPAN::Audit reaching @INC by ambient
    # PERL5LIB. On this host it always does - prove runs with ~/perl5 on the path,
    # so the fake is merely PREPENDED to a tree that already has the real one. In
    # CI it never does: CPAN::Audit is installed into a separate audit-local prefix
    # whose BIN is added to PATH while the "Run tests" step keeps
    # PERL5LIB=local/lib/perl5. The gate then exits 2 and every assertion that runs
    # it fails, in a file whose POD claimed to be hermetic.
    #
    # in_range is never reached by these cases - the fake database has an empty
    # dists map, so the findings loop iterates nothing - but it returns a definite
    # 0 rather than dying, so a future case that DOES reach it fails on an
    # assertion instead of on a missing method.
    open my $vfh, '>', File::Spec->catfile( $pkg, 'Version.pm' ) or die "cannot write fake Version: $!";
    print {$vfh} <<'FAKEVER';
package CPAN::Audit::Version;
sub new      { return bless {}, shift }
sub in_range { return 0 }
1;
FAKEVER
    close $vfh;

    return $dir;
}

# Purpose: run the Perl gate against a chosen database stamp.
# Input:   $stamp, %env - extra environment (CPAN_AUDIT_FRESH_DAYS).
# Output:  ($exit, $combined_output)
#
# The status is read from CHILD_ERROR_NATIVE, never through a pipe: a pipe reports
# the LAST stage's status, which has already laundered a gate result on this project
# and did so again while this card was being researched.
sub _run_perl_gate {
    my ( $stamp, %env ) = @_;
    my $lib  = _fake_db_lib($stamp);
    my $root = tempdir( CLEANUP => 1 );
    local $ENV{PERL5LIB} = join Developer::Dashboard::PerlEnv::path_separator(), $lib, ( $ENV{PERL5LIB} // () );
    local @ENV{ keys %env } = values %env;
    my $out = `$^X \Q$PERL_GATE\E \Q$root\E 2>&1`;
    return ( ${^CHILD_ERROR_NATIVE} >> 8, $out );
}

# Purpose: a cpan-audit shim whose --version names a chosen database stamp.
# Input:   $stamp
# Output:  the directory to prepend to PATH.
#
# It answers --version in cpan-audit's real layout, indented under "using:", because
# the gate has to parse what the binary actually prints. The audit runs report no
# advisories, so any refusal observed here is about the CORPUS and not the findings.
sub _version_shim {
    my ($stamp) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    my $bin = File::Spec->catfile( $dir, 'cpan-audit' );
    open my $fh, '>', $bin or die "cannot write shim: $!";
    print {$fh} <<"SHIM";
#!/bin/sh
for a in "\$@"; do
  if [ "\$a" = "--version" ]; then
    echo "cpan-audit version 1.503 using:"
    echo "	CPAN::Audit      20260622.001"
    echo "	CPANSA::DB       $stamp"
    exit 0
  fi
done
exit 0
SHIM
    close $fh;
    chmod 0755, $bin;
    return $dir;
}

# Purpose: run the bash gate with a shimmed cpan-audit.
# Input:   $stamp, %env
# Output:  ($exit, $combined_output)
sub _run_bash_gate {
    my ( $stamp, %env ) = @_;
    my $tmp  = tempdir( CLEANUP => 1 );
    my $root = File::Spec->catdir( $tmp, 'local', 'lib', 'perl5' );
    make_path($root);
    local $ENV{PATH} = join ':', _version_shim($stamp), $ENV{PATH};
    local $ENV{DD_CPAN_AUDIT_ALLOW_EXTERNAL_ROOT} = 1;
    local @ENV{ keys %env } = values %env;
    my $out = `bash \Q$BASH_GATE\E \Q$root\E 2>&1`;
    return ( ${^CHILD_ERROR_NATIVE} >> 8, $out );
}

my $FRESH = _stamp(0);
my $STALE = _stamp(400);
my $MID   = _stamp(5);      # inside the default limit, outside a tightened one

# The phrase "N days old" appears in the CORPUS REPORT by design, on every run,
# including accepted ones. So a matcher looking for it cannot tell a report from a
# refusal - the first version of this file used exactly that matcher and reported
# a refusal on a run that had accepted the database. That is this file's own subject
# in miniature: a signal being PRESENT is not the verdict having CHANGED, and the
# assertion has to name the half it means. REFUSAL matches only the declining
# sentence, which carries the configured limit; the report never does.
my $REFUSAL = qr/advisory database is \d+ days? old .* and the limit is \d+/i;

# AC-0: the date arithmetic itself, against an INDEPENDENT ORACLE.
#
# The gate deliberately does its own days-from-civil arithmetic rather than using
# Time::Local, so that no timezone rule or year-interpretation heuristic can move a
# release decision. That choice is only safe if the arithmetic is right, and until
# now it was exercised only indirectly, through two stamps that happen to sit far
# apart. Leap years and century rules were untested.
#
# The oracle is Time::Local rather than hand-written constants, and that is not
# fussiness: writing this check the first time with constants I worked out myself,
# one of eight was wrong - the CODE was correct and MY EXPECTATION was not. A test
# whose expected values come from the same head as the argument for the code proves
# only that the head is self-consistent.
{
    my $gate_src = do {
        open my $fh, '<', $GATE_SRC or die "cannot read gate: $!";
        local $/;
        <$fh>;
    };
    my ($body) = $gate_src =~ /(sub _days_from_civil \{.*?\n\})/s;
    ok $body, 'the gate still defines _days_from_civil (this spec reads the real one)';

    my $dfc = eval "$body; \\&_days_from_civil";
    die "could not load _days_from_civil: $@" if !$dfc;

    # Cases chosen for the rules that actually differ between calendars, not for
    # coverage of a range: both century rules, an ordinary leap year, and a date
    # before the epoch so a negative result is exercised.
    for my $case (
        [ 1970, 1,  1,  'the civil epoch' ],
        [ 1969, 12, 31, 'the day before the epoch - a negative result' ],
        [ 2000, 2,  29, '2000 IS a leap year: divisible by 400' ],
        [ 1900, 3,  1,  '1900 is NOT a leap year: divisible by 100, not 400' ],
        [ 2024, 2,  29, 'an ordinary leap year' ],
        [ 2026, 9,  6,  'a date in the range this gate actually sees' ],
      )
    {
        my ( $y, $m, $d, $why ) = @{$case};
        my $oracle = timegm( 0, 0, 0, $d, $m - 1, $y ) / 86_400;
        is $dfc->( $y, $m, $d ), $oracle, "days_from_civil agrees with Time::Local: $why";
    }
}

# AC-1: the Perl gate names its corpus on EVERY run, including a clean one.
# The clean path is the one people believe, so it is the one that must carry the
# stamp. A gate that names the database only when refusing tells you what it read
# exactly when you no longer need to know.
{
    my ( undef, $out ) = _run_perl_gate($FRESH);
    like $out, qr/\Q$FRESH\E/,
      'declared-chain names the advisory database stamp it audited against';
}

# AC-2: a database past the threshold is refused, and the refusal NAMES the age.
# Asserting on the message, not on the status: exit 2 is already reachable here
# through _unusable for an unreadable root or absent metadata, so a status-only
# assertion would pass against the unmodified gate.
{
    my ( $exit, $out ) = _run_perl_gate($STALE);
    like $out, $REFUSAL,
      'declared-chain refuses a stale database with a message naming its age';
    like $out, qr/\Q$STALE\E/,
      'the stale refusal names the offending stamp, not just the fact of staleness';
    # THIS ASSERTION CANNOT STAND ALONE, measured rather than supposed: run against
    # the unmodified gate it PASSED, because _unusable already exits 2 for an
    # unreadable root. It is meaningful only beside the two message assertions
    # above. Deleting either of them leaves a check that certifies nothing while
    # still going green.
    is $exit, 2,
      'the stale refusal uses the existing UNUSABLE exit rather than a new code';
}

# AC-3: the threshold is upstream's knob, and it moves the verdict BOTH ways.
# A guard only ever seen to fire proves it can fire, not that it discriminates.
{
    my ( undef, $default ) = _run_perl_gate($MID);
    unlike $default, $REFUSAL,
      'a 5-day-old database is accepted under the default limit';

    my ( undef, $tight ) = _run_perl_gate( $MID, CPAN_AUDIT_FRESH_DAYS => 2 );
    like $tight, $REFUSAL,
      'the SAME database is refused once CPAN_AUDIT_FRESH_DAYS drops below its age';

    my ( undef, $loose ) = _run_perl_gate( $STALE, CPAN_AUDIT_FRESH_DAYS => 9999 );
    unlike $loose, $REFUSAL,
      'CPAN_AUDIT_FRESH_DAYS=9999 accepts a 400-day database (guard is not stuck on)';
    like $loose, qr/\Q$STALE\E/,
      'and the stamp is still named when the age is accepted - reporting is not conditional on judging';
}

# AC-4: the bash gate takes its stamp from the binary it actually shells out to.
# A perl one-liner here could resolve a different @INC than the cpan-audit on PATH
# and report a stamp for a database no verdict came from - this card's own defect,
# reproduced inside its fix.
{
    my ( undef, $out ) = _run_bash_gate($FRESH);
    like $out, qr/\Q$FRESH\E/,
      'cpan-audit-project names the database stamp reported by the binary it invokes';
}

# AC-5: the bash gate refuses a stale database, naming the age.
{
    my ( $exit, $out ) = _run_bash_gate($STALE);
    like $out, $REFUSAL,
      'cpan-audit-project refuses a stale database with a message naming its age';

    # FOUR, not two. The two gates do not share an exit vocabulary and this file
    # originally assumed they did: in cpan-audit-project, 2 is a USAGE error and 4
    # is "the gate could not run at all". The script's own header states the reason
    # this distinction was bought - "a gate that cannot look must never be mistaken
    # for a gate that looked and found something" (DD-517) - which is exactly what
    # an unusably old advisory database is. Collapsing it into 2 would tell CI the
    # caller mistyped an argument.
    is $exit, 4,
      'and uses cpan-audit-project OWN could-not-run exit, not the Perl gate 2';
}

# AC-6: the same knob, the same both-direction behaviour, in the bash gate.
{
    my ( undef, $loose ) = _run_bash_gate( $STALE, CPAN_AUDIT_FRESH_DAYS => 9999 );
    unlike $loose, $REFUSAL,
      'CPAN_AUDIT_FRESH_DAYS=9999 accepts a stale database in the bash gate too';
    like $loose, qr/\Q$STALE\E/,
      'and the stamp is still printed when accepted';
}

# DD-798 AC-1..AC-3 and AC-5: the refusal RECOMMENDS a command, and a recommendation
# is shipped code - the user pastes it into a shell with their own privileges. Both
# gates used to name a FIXED path under world-writable /tmp and then put it FIRST on
# PERL5LIB. /tmp is 1777, so the sticky bit stops a user DELETING another's files but
# not CREATING that directory first; cpanm then REUSES an existing directory rather
# than refusing it. On the host where this was found the directory already existed,
# mode 775, already holding CPAN/Audit/DB.pm and CPANSA/DB.pm - the very modules the
# instruction says to prepend. CWE-377/378; the published twin is CVE-2026-19953's
# neighbour CVE-2026-25645 in Requests.
#
# These assert on the EMITTED TEXT, never on the source line, so a refactor of how
# the message is built cannot silently drop the property.
{
    my ( $perl_exit, $perl_out ) = _run_perl_gate($STALE);
    my ( $bash_exit, $bash_out ) = _run_bash_gate($STALE);

    for my $case ( [ 'declared-chain', $perl_out ], [ 'cpan-audit-project', $bash_out ] ) {
        my ( $name, $out ) = @{$case};

        # AC-1: no FIXED /tmp path in the RECOMMENDED COMMANDS. Scoped to the recipe
        # lines rather than the whole message, and that narrowing was forced by the
        # test failing: the gate legitimately echoes the root it was asked to audit,
        # and in this spec that root IS a tempdir under /tmp. A whole-output ban
        # therefore reported a defect that did not exist - the assertion was wrong,
        # not the code. Still deliberately wider than the one name that was there,
        # because banning only dd-fresh-cpansa is satisfied by inventing a different
        # fixed name, which is the same defect renamed.
        my @advice = grep { /^\s{4}\S/ } split /\n/, $out;

        # The property is NOT "no /tmp appears" - the last recipe line ends with the
        # root the CALLER asked to audit, echoed back so the command can be re-run,
        # and in this spec that root is itself a tempdir. Twice this assertion was
        # written too wide and twice the test said so. What must hold is narrower and
        # is the actual defect: the directory the recipe CREATES and PREPENDS must not
        # be a path of the tool's own invention.
        my ($install) = grep { /--local-lib-contained/ } @advice;
        unlike $install, qr{/tmp/},
          "$name installs into a directory it creates, not a fixed /tmp path";
        my ($prepend) = grep { /^\s*PERL5LIB=/ } @advice;
        my ($value)   = $prepend =~ /PERL5LIB="([^"]*)"/;
        unlike $value, qr{/tmp/},
          "$name prepends its created directory, not a fixed /tmp path";
        unlike $out, qr/dd-fresh-cpansa/,
          "$name output does not mention the scratch name at all";

        # AC-2: it still tells the user what to DO. Being actionable is why a fix is
        # named at all; a refusal with no way forward gets worked around, not followed.
        like $out, qr/\bmktemp -d\b/,
          "$name refusal creates a private directory with mktemp -d";
        like $out, qr/\$DIR/,
          "$name refusal refers to the directory it just created";

        # AC-5: the corpus verdict itself must not move. Only the recommended path
        # changes, and a fix that quietly altered a security gate's verdict would be
        # far worse than the bug it replaced.
        like $out, $REFUSAL,
          "$name still names the age and the limit";
        like $out, qr/\Q$STALE\E/,
          "$name still names the offending stamp";
    }

    # AC-5 continued: each gate keeps its OWN could-not-run code.
    is $perl_exit, 2, 'declared-chain still exits 2';
    is $bash_exit, 4, 'cpan-audit-project still exits 4 - its own code, not the Perl gate 2';

    # AC-3: what is printed must actually RUN. A refusal that prints a recipe with a
    # syntax error is worse than one printing nothing: the user believes it, pastes
    # it, and then debugs our message. Nothing else in this suite checks that.
    for my $case ( [ 'declared-chain', $perl_out ], [ 'cpan-audit-project', $bash_out ] ) {
        my ( $name, $out ) = @{$case};
        my @recipe = grep { /^\s{4}\S/ } split /\n/, $out;
        cmp_ok scalar @recipe, '>=', 3,
          "$name prints a recipe of at least three lines";
        my $script = File::Spec->catfile( tempdir( CLEANUP => 1 ), 'recipe.sh' );
        open my $rfh, '>', $script or die "cannot write recipe: $!";
        print {$rfh} join( "\n", map { s/^\s{4}//r } @recipe ), "\n";
        close $rfh;
        system 'sh', '-n', $script;
        is ${^CHILD_ERROR_NATIVE} >> 8, 0,
          "$name printed recipe parses as shell - sh -n accepts it";
    }
}

done_testing;

__END__

=head1 NAME

t/172-cpan-audit-database-age.t - the CVE gates must name the advisory database
they audited against, and refuse to answer from a stale one

=head1 PURPOSE

Assert that both CVE gates - C<script/cpan-audit-declared-chain> and
C<script/cpan-audit-project> - report the identity of the advisory database
behind every verdict, and decline to produce a verdict at all once that database
is older than C<CPAN_AUDIT_FRESH_DAYS>.

=head1 WHY IT EXISTS

On 2026-09-06 both gates reported the declared runtime closure clean while the
advisory database was thirty days old and did not contain C<URI> at all. The
installed C<URI> was 5.34 and a real advisory against it existed upstream. The
clean verdict was not a miss; the run was structurally incapable of producing the
finding, and said "clean" in the same words it uses when it has genuinely looked.

Two clean runs were then cited as evidence in a cross-session investigation and
narrowed another agent's search away from the true cause. A verdict whose validity
rests on a corpus the tool never names cannot be audited by its reader, because
nothing in the output distinguishes "nothing is wrong" from "nothing could have
been found".

Upstream already treats database age as worth reporting - C<cpan-audit --fresh>
warns through C<CPAN::Audit::FreshnessCheck> - but the warning goes to STDERR and
leaves the exit status unchanged (measured: 91 with the flag and 91 without). This
file pins the escalation of that existing signal into the verdict, rather than the
invention of a competing age policy.

=head1 WHEN TO USE

Whenever either CVE gate script changes, whenever the advisory database module or
its accessor changes, and before trusting any archived gate output as evidence
that a release was audited.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/172-cpan-audit-database-age.t

The file is hermetic, and that is CHECKABLE rather than asserted - run it with
C<env -u PERL5LIB> and it must still pass. It did not, before DD-799: the spec
shadowed C<CPAN::Audit::DB> and relied on the REAL C<CPAN::Audit::Version> arriving
through ambient C<PERL5LIB>, which is true on a developer host and false in CI.
Both modules are faked now. The Perl gate is exercised against a temporary library
that shadows both; the bash gate is exercised against
a C<cpan-audit> shim whose C<--version> names one. Neither reads the host's real
advisory database, so the file cannot pass or fail because of what upstream
published today.

=head1 WHAT USES IT

The suite, through C<prove -lr t>, and therefore the unit-test gate on every card
touching either script. CI runs it at the same step as the other audit specs.

=head1 EXAMPLES

To see the specs fail the way they were written to fail, remove the age check from
C<script/cpan-audit-declared-chain>: AC-1 through AC-3 then report a gate that
audits, answers, and never says what it read.

=cut
