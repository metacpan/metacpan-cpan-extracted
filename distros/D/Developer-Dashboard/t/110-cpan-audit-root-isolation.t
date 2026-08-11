#!/usr/bin/env perl

use strict;
use warnings;

use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;
use Test::More;

my $ROOT = File::Spec->rel2abs( File::Spec->catdir( $FindBin::Bin, File::Spec->updir ) );
my $GATE = File::Spec->catfile( $ROOT, 'script', 'cpan-audit-project' );

plan skip_all => "audit gate not present at $GATE" if !-f $GATE;

# _run_gate($root, %env)
# Purpose: execute the audit gate against a library root and report exactly what
#          it did, without letting a pipe launder the exit status.
# Input:   $root = the library root to audit; %env = extra environment pairs.
# Output:  a two-element list ($exit_status, $combined_output).
sub _run_gate {
    my ( $root, %env ) = @_;

    local @ENV{ keys %env } = values %env;
    my $out = `bash \Q$GATE\E \Q$root\E 2>&1`;
    return ( ${^CHILD_ERROR_NATIVE} >> 8, $out );
}

# _seed_root($dir)
# Purpose: make a directory look enough like a Perl library root that the gate
#          gets past its argument checks and reaches the isolation precondition.
# Input:   $dir = the directory to populate.
# Output:  the same directory path, now containing a distribution metadata dir.
sub _seed_root {
    my ($dir) = @_;
    make_path( File::Spec->catdir( $dir, '.meta', 'Fake-Dist-1.00' ) );
    return $dir;
}

# _slurp($path)
# Purpose: read a repository documentation file whole, failing loudly if it is
#          missing rather than letting an empty string satisfy an assertion.
# Input:   $path = absolute path to the file.
# Output:  the file's contents as a single string.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<', $path or die "cannot read $path: $!";
    local $/ = undef;
    my $contents = <$fh>;
    close $fh or die "cannot close $path: $!";
    return $contents;
}

# A root OUTSIDE the repository working tree is a shared library tree, not an
# isolated product root. The gate must refuse it rather than reporting whatever
# unrelated software happens to be installed there as this product's exposure.
{
    my $outside = _seed_root( tempdir( CLEANUP => 1 ) );
    my ( $rc, $out ) = _run_gate($outside);

    is( $rc, 3, 'gate exits 3 - distinct from clean, finding and usage - on a non-isolated root' );
    like( $out, qr/not an isolated/i, 'gate says the root is not isolated' );
    like(
        $out,
        qr/cpan-audit-declared-chain/,
        'gate names the instrument that does answer the question for a shared tree'
    );
    like( $out, qr/\Q$outside\E/, 'gate states the subject it was pointed at' );
}

# The escape hatch exists so a genuinely isolated root built outside the
# checkout (a container path, a scratch directory) stays auditable. It must be
# explicit: the default is refusal, and the caller has to say so on purpose.
{
    my $outside = _seed_root( tempdir( CLEANUP => 1 ) );
    my ( $rc, $out ) = _run_gate( $outside, DD_CPAN_AUDIT_ALLOW_EXTERNAL_ROOT => '1' );

    isnt( $rc, 3, 'explicit opt-in suppresses the isolation refusal' );
    unlike( $out, qr/not an isolated/i, 'opt-in root is not reported as non-isolated' );
}

# A root INSIDE the repository working tree is what CI builds and audits
# (.github/workflows/test.yml runs the gate against local/lib/perl5), so the
# precondition must never fire there - a guard that red-lines CI is worse than
# the misreading it set out to prevent.
{
    my $inside = File::Spec->catdir( $ROOT, '.t110-isolated-root' );
    remove_tree($inside) if -d $inside;
    _seed_root($inside);

    my ( $rc, $out ) = _run_gate($inside);

    isnt( $rc, 3, 'a root inside the checkout is never refused as non-isolated' );
    unlike( $out, qr/not an isolated/i, 'in-tree root produces no isolation complaint' );

    remove_tree($inside);
}

# The refusal is only half the fix. What produced DD-499 was an operator
# following the documentation, and the documentation named the invocation the
# gate now rejects. Docs that instruct a refused command reproduce the original
# failure with an extra step, so they are pinned here rather than left to drift
# away from the script they describe.
{
    my $security  = _slurp( File::Spec->catfile( $ROOT, 'doc',  'security.md' ) );
    my $gate_map  = _slurp( File::Spec->catfile( $ROOT, 'docs', 'gate-map.md' ) );
    my ($cve_row) = $gate_map =~ /^(.*100% CVE FREE.*)$/m;

    like( $security, qr/\bexit status 3\b/, 'security doc states the distinct refusal status the gate returns' );
    like(
        $security,
        qr/DD_CPAN_AUDIT_ALLOW_EXTERNAL_ROOT/,
        'security doc records the explicit opt-in, so the escape hatch is discoverable without reading the script'
    );

    ok( defined $cve_row, 'gate map still carries a CVE FREE row to check' );
    like(
        $cve_row // '',
        qr/cpan-audit-declared-chain/,
        'gate map sends a shared tree to the instrument whose subject is the product'
    );
    unlike(
        $cve_row // '',
        qr/cpan-audit-project` against the pinned chain/,
        'gate map no longer instructs the invocation the gate refuses with exit 3'
    );
}

done_testing();

__END__

=head1 NAME

t/110-cpan-audit-root-isolation.t - prove the CPAN audit gate refuses a library
root that is not an isolated product root

=head1 PURPOSE

An executable guard over the isolation precondition in
C<script/cpan-audit-project>, covering both halves of that precondition: what
the gate DOES, and what the repository TELLS an operator to do. It runs the real
gate as a subprocess against purpose-built library roots and asserts the outcome
of each, then asserts that the operator-facing documentation still describes the
contract the gate actually implements.

C<script/cpan-audit-project> asks "is the set of distributions installed in this
root vulnerable?". That question is only meaningful about the product when the
root contains the product's dependencies and nothing else. Pointed at a shared
CPAN tree it faithfully reports every advisory affecting every module any
project on that machine ever installed - an answer that is true about the tree
and worthless about the product.

=head1 WHY IT EXISTS

Under DD-499 the gate was found exiting 88 against C<$HOME/perl5/lib/perl5>,
reporting twenty-four advisories across seven distributions. Not one of those
distributions was a declared runtime dependency: C<DBI> is a develop-time
recommendation and the rest - CryptX, Sereal, Crypt-PBKDF2,
String-Compare-ConstantTime and the host interpreter - were not declared
anywhere. The product's real position was clean, which
C<script/cpan-audit-declared-chain> established over 81 distributions.

Three separate rounds read that red as a release blocker before anyone checked
what it had measured. A gate that reports its own environment as a product
defect is a guardrail pointed the wrong way, and the cost is paid every time
somebody believes it.

The documentation assertions exist because the first attempt at that fix was
incomplete. Hardening the gate while leaving the repository's gate map and its
project rules naming the now-refused invocation would have turned exit 88 into
exit 3 for the next operator who followed the instructions - a different
unexplained red on the same gate, and a fresh ticket. Prose describing a tool's
contract is part of that contract, so it is pinned here and cannot drift away
from the script in silence.

=head1 WHEN TO USE

It runs with the suite. Extend it when the isolation precondition changes -
particularly if the definition of an isolated root is tightened, since the
in-tree case below is what stops such a change from red-lining CI. A change to
the gate's exit statuses or its opt-in variable must be made here and in the
project's security documentation together, because the last block asserts that
the two agree.

=head1 HOW TO USE

  prove -lv t/110-cpan-audit-root-isolation.t

To watch the guard fail on purpose - which is the only way to know it can -
remove the isolation check from C<script/cpan-audit-project> and rerun.

=head1 WHAT USES IT

The suite, through C<prove -lr t>. It exercises C<script/cpan-audit-project>
directly and shares its subject with C<t/108-cpan-security-metadata.t>, which
covers the gate's other preconditions.

=head1 EXAMPLES

Refusing a shared tree, which is the case that caused DD-499:

  bash script/cpan-audit-project "$HOME/perl5/lib/perl5"
  # exit 3, naming cpan-audit-declared-chain as the right instrument

Auditing the isolated root CI builds:

  bash script/cpan-audit-project local/lib/perl5

Auditing a genuinely isolated root built outside the checkout:

  DD_CPAN_AUDIT_ALLOW_EXTERNAL_ROOT=1 bash script/cpan-audit-project /opt/deps/lib/perl5

=cut
