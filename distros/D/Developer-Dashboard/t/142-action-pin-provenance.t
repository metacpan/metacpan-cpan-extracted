#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use JSON::XS ();
use Test::More;

my $ROOT   = abs_path( File::Spec->catdir( $RealBin, File::Spec->updir ) );
my $GATE   = File::Spec->catfile( $ROOT, 'script', 'audit-action-pins' );
my $SOURCE = _slurp($GATE);

# Two SHAs that differ, so "the comment names a tag that resolves elsewhere" can
# be expressed without any real upstream involvement.
my $SHA_PINNED = 'a' x 40;
my $SHA_OTHER  = 'b' x 40;

# ---------------------------------------------------------------------------
# Source contracts. These hold with or without a network, so they run first.
# ---------------------------------------------------------------------------

ok( -f $GATE, 'the action-pin provenance gate is tracked in script/' );
ok( -x $GATE, 'the action-pin provenance gate is executable' );
like( $SOURCE, qr{\A\#!/usr/bin/env perl\n}, 'the gate uses the portable env shebang' );
like( $SOURCE, qr/^use strict;$/m,   'the gate runs under strict' );
like( $SOURCE, qr/^use warnings;$/m, 'the gate runs under warnings' );
unlike( $SOURCE, qr/JSON::PP|LWP::Simple|HTTP::Tiny|capture_merged/,
    'the gate uses no forbidden library' );
like( $SOURCE, qr/LWP::UserAgent/, 'the gate uses the mandated HTTP client' );
like( $SOURCE, qr/EXIT_UNUSABLE/, 'the gate has a distinct exit code for "could not audit"' );

# The reason this file exists at all: a version comment that nothing resolves is
# trusted and can still be false, so the gate must compare the comment to the
# tag rather than parse it for plausibility.
like( $SOURCE, qr/resolve_tag/, 'the gate resolves the commented tag against the upstream API' );
like( $SOURCE, qr/MINIMUM_NODE_RUNTIME/, 'the gate enforces a floor on the declared node runtime' );

# ---------------------------------------------------------------------------
# Behaviour. Every case below drives the gate through DD_ACTION_PIN_FIXTURE, so
# the suite stays hermetic and none of these assertions depend on GitHub being
# reachable or on what any upstream action happens to declare today.
# ---------------------------------------------------------------------------

# Fail-closed contract. A gate that cannot audit must never look like a gate
# that found nothing wrong, so both of these are non-zero and distinct from the
# "found a defect" code.
{
    my ( $rc, $out, $err ) = _run_gate( ['--help'] );
    is( $rc, 2, 'the gate exits 2 on a usage error' );
    like( $err, qr/Usage:/, 'the gate prints a usage diagnostic' );
}

{
    my $missing = File::Spec->catdir( tempdir( CLEANUP => 1 ), 'no-such-dir' );
    my ( $rc, $out, $err ) = _run_gate( [$missing] );
    is( $rc, 3, 'the gate exits 3 when the workflow directory does not exist' );
    like( $err, qr/not a directory/, 'the gate says why it could not audit' );
}

{
    my $empty = tempdir( CLEANUP => 1 );
    my ( $rc, $out, $err ) = _run_gate( [$empty] );
    is( $rc, 3, 'the gate exits 3 rather than 0 when it finds no pins to audit' );
    like( $err, qr/no SHA-pinned actions/, 'the gate reports an empty pin set as unusable, not clean' );
}

# The clean case.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => _uses( 'actions/checkout', $SHA_PINNED, 'v7.0.1' ) },
        contents  => { "actions/checkout|action.yml|$SHA_PINNED" => "runs:\n  using: node24\n" },
        tags      => { 'actions/checkout|v7.0.1' => $SHA_PINNED },
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 0, 'a pin whose comment resolves to its own SHA on a node24 runtime passes' );
    like( $out, qr/examined 1 SHA-pinned action\b/, 'the gate reports how many pins it examined' );
    like( $out, qr/FIXTURE MODE/, 'a fixture-backed run announces that it is not network-verified' );
}

# The runtime floor - the defect that broke CI for ten days. A node20 action is
# force-run on node24 by GitHub and may or may not survive it, so it is a latent
# failure rather than a warning.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => _uses( 'shogo82148/actions-setup-perl', $SHA_PINNED, 'v1.31.3' ) },
        contents  => { "shogo82148/actions-setup-perl|action.yml|$SHA_PINNED" => qq{runs:\n  using: "node20"\n} },
        tags      => { 'shogo82148/actions-setup-perl|v1.31.3' => $SHA_PINNED },
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 1, 'a pin declaring node20 is a finding' );
    like( $err, qr/declares node20, below the node24 floor/, 'the gate names the runtime it rejected' );
}

# The provenance defect itself: the comment is trusted by t/34's version floors,
# so a comment naming a tag that resolves to a different commit is exactly the
# failure this gate exists to catch, and it must NOT be reported as unusable.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => _uses( 'actions/checkout', $SHA_PINNED, 'v5.2.2' ) },
        contents  => { "actions/checkout|action.yml|$SHA_PINNED" => "runs:\n  using: node24\n" },
        tags      => { 'actions/checkout|v5.2.2' => $SHA_OTHER },
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 1, 'a comment naming a tag that resolves to another commit is a finding' );
    like( $err, qr/does not describe the pinned commit/,
        'the gate explains that the comment and the SHA disagree' );
}

# An unresolvable tag is "could not audit", not "clean" and not "wrong".
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => _uses( 'actions/checkout', $SHA_PINNED, 'v9.9.9' ) },
        contents  => { "actions/checkout|action.yml|$SHA_PINNED" => "runs:\n  using: node24\n" },
        tags      => {},
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 3, 'a tag that cannot be resolved is reported as unusable' );
    like( $err, qr/could not resolve upstream tag v9\.9\.9/, 'the gate names the tag it could not resolve' );
}

# An unreadable manifest is likewise unusable. This is the case the round that
# wrote this gate hit for real: /repos/.../commits/{sha} answers "No commit
# found" for github/codeql-action even for a current release tag, so an
# endpoint saying no is not proof that a pin is bad.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => _uses( 'actions/checkout', $SHA_PINNED, undef ) },
        contents  => {},
        tags      => {},
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 3, 'a pin whose action.yml cannot be read is reported as unusable' );
    like( $err, qr/could not read action\.yml at the pinned SHA/,
        'the gate distinguishes "could not look" from "looked and it is wrong"' );
}

# Docker and composite actions declare no node runtime at all, so the floor must
# not invent one for them.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => _uses( 'some/docker-action', $SHA_PINNED, undef ) },
        contents  => { "some/docker-action|action.yml|$SHA_PINNED" => "runs:\n  using: docker\n  image: Dockerfile\n" },
        tags      => {},
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 0, 'an action with no node runtime is not judged against the node floor' );
}

# A monorepo action lives at a subdirectory, so the manifest lookup has to use
# the sub-path rather than the repository root.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'codeql.yml' => _uses( 'github/codeql-action/init', $SHA_PINNED, 'v4.37.6' ) },
        contents  => { "github/codeql-action|init/action.yml|$SHA_PINNED" => "runs:\n  using: node24\n" },
        tags      => { 'github/codeql-action|v4.37.6' => $SHA_PINNED },
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 0, 'an action published from a monorepo subdirectory resolves through its sub-path' );
}

# checkout is pinned in five workflows here, so the report has to collapse the
# repeats into one audited pin while still naming every file that carries it -
# otherwise a five-file pin produces five identical findings.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => {
            'test.yml'    => _uses( 'actions/checkout', $SHA_PINNED, 'v7.0.1' ),
            'codeql.yml'  => _uses( 'actions/checkout', $SHA_PINNED, 'v7.0.1' ),
        },
        contents => { "actions/checkout|action.yml|$SHA_PINNED" => qq{runs:\n  using: 'node20'\n} },
        tags     => { 'actions/checkout|v7.0.1' => $SHA_PINNED },
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 1, 'a repeated pin still fails once its runtime is below the floor' );
    like( $out, qr/examined 1 SHA-pinned action\b/, 'a pin repeated across workflows is audited once' );
    like( $err, qr/codeql\.yml, test\.yml/, 'the finding names every workflow carrying the pin' );
}

# A floating tag carries no 40-hex SHA and so is not a pin at all; t/34 is what
# forbids those. This gate must simply not claim to have audited one.
{
    my ( $dir, $fixture ) = _scenario(
        workflows => { 'test.yml' => "jobs:\n  a:\n    steps:\n      - uses: actions/checkout\@v4\n" },
        contents  => {},
        tags      => {},
    );
    my ( $rc, $out, $err ) = _run_gate( [$dir], $fixture );
    is( $rc, 3, 'a floating tag is not counted as an audited pin' );
}

done_testing;

# Purpose: build a scenario on disk - a workflow directory plus the JSON fixture
#          that answers the gate's upstream lookups for it.
# Input:   a hash with workflows => { filename => yaml }, contents => {}, tags => {}.
# Output:  ($workflow_dir, $fixture_path).
sub _scenario {
    my (%spec) = @_;

    my $base = tempdir( CLEANUP => 1 );
    my $dir  = File::Spec->catdir( $base, 'workflows' );
    make_path($dir);

    for my $file ( sort keys %{ $spec{workflows} } ) {
        my $path = File::Spec->catfile( $dir, $file );
        open my $fh, '>:raw', $path or die "Unable to write $path: $!";
        print {$fh} $spec{workflows}{$file};
        close $fh or die "Unable to close $path: $!";
    }

    my $fixture = File::Spec->catfile( $base, 'fixture.json' );
    open my $fh, '>:raw', $fixture or die "Unable to write $fixture: $!";
    print {$fh} JSON::XS->new->encode( { contents => $spec{contents}, tags => $spec{tags} } );
    close $fh or die "Unable to close $fixture: $!";

    return ( $dir, $fixture );
}

# Purpose: render one workflow step pinning an action, with or without the
#          trailing version comment.
# Input:   $action, $sha, $version (undef for an unlabelled pin).
# Output:  the YAML text.
sub _uses {
    my ( $action, $sha, $version ) = @_;
    my $comment = defined $version ? "  # $version" : '';
    return "jobs:\n  a:\n    steps:\n      - uses: $action\@$sha$comment\n";
}

# Purpose: execute the gate under a controlled environment.
# Input:   $argv arrayref; $fixture optional path to the offline resolver JSON.
# Output:  ($exit_code, $stdout, $stderr).
sub _run_gate {
    my ( $argv, $fixture ) = @_;

    local $ENV{DD_ACTION_PIN_FIXTURE} = $fixture // '';
    my ( $stdout, $stderr, $exit ) = capture {
        system( $^X, $GATE, @{$argv} );
    };
    return ( $exit >> 8, $stdout, $stderr );
}

# Purpose: read a whole file.
# Input:   $path.
# Output:  its contents.
sub _slurp {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Unable to read $path: $!";
    local $/;
    my $text = <$fh>;
    close $fh or die "Unable to close $path: $!";
    return $text;
}

__END__

=pod

=head1 NAME

t/142-action-pin-provenance.t - the action-pin provenance gate's own regression
suite

=head1 PURPOSE

Prove that C<script/audit-action-pins> reaches the right verdict for every shape
of action pin: correct, stale-runtime, falsely-commented, and unresolvable. It
covers the gate's decision logic, not GitHub's behaviour.

=head1 WHY IT EXISTS

DD-449. Every C<uses:> line in this repository is pinned to an immutable 40-hex
SHA and annotated with a C<# vX.Y.Z> comment, and
C<t/34-scorecard-guardrails.t> reads its node24 version floors out of those
comments. Nothing verified a comment against the SHA it annotated, so three pins
carried versions written from intent: C<actions/checkout> claimed C<# v5.2.2>, a
tag that has never existed upstream, over a commit that is really v4.2.2.

All three were node20 actions, and GitHub now force-runs node20 actions on
node24. C<actions/checkout> survives that; C<shogo82148/actions-setup-perl>
v1.31.3 fails with C<Error: unable to get latest version>. The C<Setup Perl>
step failed on every CI run for ten days - skipping the suite, the coverage gate
and both dependency audits - while the guardrail test certified the migration as
complete. C<script/audit-action-pins> is the check that resolves the SHA, and
this file is what keeps that check honest.

=head1 WHEN TO USE

Run it whenever C<script/audit-action-pins> changes, and as part of the full
suite. It needs no network and no credentials.

=head1 HOW TO USE

    prove -lv t/142-action-pin-provenance.t
    prove -lr t

=head1 WHAT USES IT

The full C<prove -lr t> gate, and the CI workflow that runs it.

=head1 HOW IT WORKS

Each case writes a throwaway workflow directory and a JSON fixture into a
temporary directory, then runs the gate with C<DD_ACTION_PIN_FIXTURE> pointing
at that fixture so the upstream lookups are answered from disk. That keeps the
suite hermetic and makes cases like "this tag resolves to a different commit"
expressible at all - they cannot be staged against a real upstream repository.

=head1 EXAMPLES

Check just the fail-closed behaviour while editing the gate's exit codes:

    prove -lv t/142-action-pin-provenance.t 2>&1 | grep -i unusable

Run the real, network-backed audit that this file's fixtures stand in for:

    script/audit-action-pins

=cut
