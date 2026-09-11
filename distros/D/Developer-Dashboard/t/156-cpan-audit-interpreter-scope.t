#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

my $ROOT = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $GATE = File::Spec->catfile( $ROOT, 'script', 'cpan-audit-project' );

plan skip_all => "audit gate not present at $GATE" if !-f $GATE;

# WHY THIS FILE EXISTS (DD-567)
#   Five consecutive merges landed on master with no test verdict and no coverage
#   verdict. CI step 7 - "Audit isolated dependency root" - failed because the
#   PERL INTERPRETER had an advisory (CVE-2026-15534 against 5.44.0), and its
#   failure skipped steps 8 through 11: the declared-chain audit, the test run and
#   the coverage gate. Every local run reported PASS throughout, which is exactly
#   the shape this project has recorded before.
#
#   The interpreter is not a declared dependency of this product and is not
#   something it ships or can patch. Two places already say so: CLAUDE.md, which
#   classes host interpreter advisories as environmental rather than release
#   blockers, and script/cpan-audit-declared-chain, the gate CLAUDE.md names as
#   authoritative, which skips the interpreter outright ("next if $module eq
#   'perl'"). The two gates disagreed about scope and the one that said "in scope"
#   ran first, blocking the one that said "out of scope".
#
#   So this file pins the SCOPE, not the strictness. The distinction is the whole
#   point: a gate relaxed by one step is a gate, a gate relaxed by two is a
#   formality.

# _shim(%behaviour)
# Purpose: the sh prologue every cpan-audit double needs so the gate's corpus
#          probe is answered the way the real binary answers it.
# Input:   none.
# Output:  a shell snippet answering --version and falling through otherwise.
#
# The gate establishes which advisory database it is auditing against before it
# audits (DD-790), so a double that ignores --version is an incomplete model of
# the binary: the gate refuses it as UNUSABLE, correctly, and every case in this
# file fails for a reason none of them is about. The stamp is today's, computed
# rather than written, so this file cannot start failing by the calendar.
sub _version_prologue {
    my @now   = gmtime(time);
    my $stamp = sprintf '%04d%02d%02d.001', $now[5] + 1900, $now[4] + 1, $now[3];
    return
        qq{for a in "\$\@"; do\n}
      . qq{  if [ "\$a" = "--version" ]; then\n}
      . qq{    echo "cpan-audit version 1.503 using:"\n}
      . qq{    echo "\tCPANSA::DB       $stamp"\n}
      . qq{    exit 0\n}
      . qq{  fi\ndone\n};
}

# Purpose: put a deterministic cpan-audit on PATH, so these assertions test the
#          GATE rather than whichever advisories happen to be live tonight.
#          Depending on the real advisory database would make this file pass or
#          fail for reasons that have nothing to do with the code under test.
# Input:   perl_advisory => bool, dist_advisory => bool
# Output:  the directory to prepend to PATH
sub _shim {
    my (%behaviour) = @_;
    my $dir = tempdir( CLEANUP => 1 );
    my $bin = File::Spec->catfile( $dir, 'cpan-audit' );

    # The shim answers the two runs differently, which is the behaviour being
    # specified: the interpreter is in scope only when --perl is passed.
    # THE INTERPRETER APPEARS IN BOTH RUNS. The first version of this shim
    # emitted it only under --perl, which encoded the assumption under test:
    # the tests passed and the fix was void, because the real cpan-audit reports
    # perl either way (counted on 2026-08-17 - one perl line with the flag, one
    # without). A shim built from what I expected could only confirm it.
    my $perl_line = $behaviour{perl_advisory}
      ? q{echo "perl (have 5.044000) has 1 advisory"; echo "    CVEs: CVE-2026-15534"; found=1}
      : q{:};
    my $dist_line = $behaviour{dist_advisory}
      ? q{echo "Some-Dist (have ==1.00) has 1 advisory"; echo "    CPANSA-Some-Dist-2026-0001"; found=1}
      : q{:};

    my $prologue = _version_prologue();

    open my $fh, '>', $bin or die "cannot write shim: $!";
    print {$fh} <<"SHIM";
#!/bin/sh
$prologue
found=0
$dist_line
$perl_line
[ "\$found" = 1 ] && exit 65
exit 0
SHIM
    close $fh;
    chmod 0755, $bin;
    return $dir;
}

# _seed($dir) - a library root that passes the gate's own isolation guard.
sub _seed {
    my ($dir) = @_;
    my $root = File::Spec->catdir( $dir, 'local', 'lib', 'perl5' );
    make_path($root);
    return $root;
}

# _run($root, $shim_dir) - run the gate with the shim in front of PATH, reading
# the exit status directly. A pipe would report the pipe's status, which has
# already laundered a gate result on this project.
sub _run {
    my ( $root, $shim_dir ) = @_;
    local $ENV{PATH}                             = "$shim_dir:$ENV{PATH}";
    local $ENV{DD_CPAN_AUDIT_ALLOW_EXTERNAL_ROOT} = 1;
    my $out = `bash \Q$GATE\E \Q$root\E 2>&1`;
    return ( ${^CHILD_ERROR_NATIVE} >> 8, $out );
}

my $tmp  = tempdir( CLEANUP => 1 );
my $root = _seed($tmp);

# AC-1: an advisory whose only subject is the interpreter must not fail this gate.
{
    my ( $status, $out ) = _run( $root, _shim( perl_advisory => 1 ) );
    is( $status, 0, 'an interpreter-only advisory does NOT fail the isolated-dependency gate' );

    # AC-3: and it is still SAID. Silencing it would trade a blocking false alarm
    # for an invisible true one.
    like( $out, qr/CVE-2026-15534|perl .*advisory/,
        'the interpreter advisory is still reported rather than suppressed' );
}

# AC-2: the strictness is unchanged for anything this product actually declares.
{
    my ( $status, undef ) = _run( $root, _shim( dist_advisory => 1 ) );
    is( $status, 5, 'a distribution advisory in the isolated root still fails the gate' );
}

# DD-574: a gate that fails must NAME what failed it. The first version of this
# change printed only the interpreter run and decided on a second, unprinted one -
# so CI showed a perl advisory and exit 5, and a reader concluded the interpreter
# had failed the gate, which is the single thing this file exists to disprove.
{
    my ( $status, $out ) = _run( $root, _shim( dist_advisory => 1 ) );
    is( $status, 5, 'a distribution advisory fails the gate' );
    # Assert on the LABEL, not on the advisory text. The first version of this
    # assertion looked for the distribution name and PASSED with the print
    # removed - because the interpreter run prints that name too, so the check
    # could not tell the two runs apart. A check that cannot fail is not a check,
    # and it was caught only by trying to falsify it.
    like( $out, qr/advisories that decided this gate/,
        'the run that DECIDED the exit is printed, labelled as such' );
}

# Both at once must still fail - the interpreter finding must not become a way for
# a real advisory to ride along unnoticed.
{
    my ( $status, undef ) = _run( $root, _shim( dist_advisory => 1, perl_advisory => 1 ) );
    is( $status, 5,
        'a distribution advisory still fails even when an interpreter advisory is present too' );
}

# A clean root is clean.
{
    my ( $status, undef ) = _run( $root, _shim() );
    is( $status, 0, 'a root with no advisories at all passes' );
}

# AC-4: could-not-look must stay distinct from clean. cpan-audit exits non-zero
# without naming any advisory when it dies before auditing, and that must never be
# reported as a pass.
{
    my $dir = tempdir( CLEANUP => 1 );
    my $bin = File::Spec->catfile( $dir, 'cpan-audit' );
    open my $fh, '>', $bin or die $!;
    print {$fh} "#!/bin/sh\necho 'Can't locate Some/Module.pm in \@INC' >&2\nexit 2\n";
    close $fh;
    chmod 0755, $bin;
    my ( $status, undef ) = _run( $root, $dir );
    isnt( $status, 0, 'a cpan-audit that died before auditing is never reported as clean' );
    isnt( $status, 5, 'and is not reported as a finding either - it is its own answer' );
}


# CI OUTPUT IS COLOURED AND THE LOCAL SHIM IS NOT (DD-567).
#
# The real log shows ESC[31mperl (have 5.044000) - so a matcher written against
# the plain form would pass every assertion in this file and fail in the only
# place that matters, which is precisely how the first version of this fix
# survived to be pushed. These two cases run the same decisions through coloured
# output.
{
    my $dir = tempdir( CLEANUP => 1 );
    my $bin = File::Spec->catfile( $dir, 'cpan-audit' );
    open my $fh, '>', $bin or die $!;
    print {$fh} qq{#!/bin/sh\n} . _version_prologue() . qq{printf '\\033[31mperl (have 5.044000) has 1 advisory\\033[0m\\n'\nexit 65\n};
    close $fh;
    chmod 0755, $bin;
    my ( $status, undef ) = _run( $root, $dir );
    is( $status, 0, 'a COLOURED interpreter-only advisory still passes - ANSI is stripped before matching' );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $bin = File::Spec->catfile( $dir, 'cpan-audit' );
    open my $fh, '>', $bin or die $!;
    print {$fh} qq{#!/bin/sh\n} . _version_prologue() . qq{printf '\\033[31mSome-Dist (have ==1.00) has 1 advisory\\033[0m\\n'\nexit 65\n};
    close $fh;
    chmod 0755, $bin;
    my ( $status, undef ) = _run( $root, $dir );
    is( $status, 5, 'and a COLOURED distribution advisory still fails' );
}

done_testing;

__END__

=head1 NAME

t/156-cpan-audit-interpreter-scope.t - pin the SCOPE of the isolated-dependency
CPAN audit gate

=head1 PURPOSE

Assert that C<script/cpan-audit-project> judges the distributions installed in the
isolated library root it is given, and that an advisory against the Perl
interpreter itself is reported but does not decide its exit status.

=head1 WHY IT EXISTS

On 2026-08-16 an advisory against perl 5.44.0 failed CI step 7, and because every
later step depended on it, the declared-chain audit, the full test run and the
all-metric coverage gate were all skipped. Five merges reached master with no test
or coverage verdict while every local run reported PASS.

The interpreter is not a declared dependency of this distribution, is not shipped
by it, and cannot be patched from it. C<script/cpan-audit-declared-chain>, the gate
this project treats as authoritative for release decisions, already skips the
interpreter explicitly. This file makes the two gates agree, and makes the
agreement fail loudly if anybody widens the scope again.

=head1 WHEN TO USE

Whenever C<script/cpan-audit-project> or the CI step that calls it is changed,
and whenever an advisory against the interpreter appears and somebody is tempted
to widen this gate's scope to cover it.

=head1 WHAT IT DOES NOT DO

It does not relax the gate. A distribution advisory in the isolated root still
exits 5, including when an interpreter advisory is present in the same run, and a
C<cpan-audit> that died before auditing anything is still distinct from a clean
result.

=head1 HOW TO USE

  PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/156-cpan-audit-interpreter-scope.t

=head1 WHAT USES IT

The suite, through C<prove -lr t>. It exercises C<script/cpan-audit-project>,
which CI runs as the "Audit isolated dependency root" step of the Test
workflow.

=head1 EXAMPLES

To watch it fail, restore C<--perl> to the run whose status decides the gate's
exit in C<script/cpan-audit-project> and rerun: the interpreter-only case then
exits 5 instead of 0.

=cut
