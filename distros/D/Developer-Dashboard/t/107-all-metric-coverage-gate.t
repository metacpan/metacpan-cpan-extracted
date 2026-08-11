use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

my $gate  = File::Spec->catfile( 'script', 'check-all-metric-coverage' );
my $entry = File::Spec->catfile( 'script', 'coverage-gate' );

sub run_gate {
    my ( $report, @arguments ) = @_;
    my ( $stdout, $stderr, $exit );
    ( $stdout, $stderr ) = capture {
        open my $input, '|-', $^X, $gate, @arguments or die "cannot run $gate: $!";
        print {$input} $report;
        close $input;
        $exit = $? >> 8;
    };
    return ( $exit, $stdout, $stderr );
}

# Purpose: plant a single coverage-database file whose leading bytes decide
#          which serialization format a sniffing reader will report.
# Input: the raw magic bytes to plant.
# Output: the temporary database directory holding them.
sub database_written_as {
    my ($magic) = @_;
    my $directory = tempdir( CLEANUP => 1 );
    my $file      = File::Spec->catfile( $directory, 'digests' );
    open my $handle, '>:raw', $file or die "cannot write $file: $!";
    print {$handle} $magic;
    close $handle or die "cannot close $file: $!";
    return $directory;
}

# Feature: enforce all four lib coverage metrics.
# Scenario: reject a report whose branch total is below 100.
# Given a Devel::Cover text report with statement, subroutine, and condition at
# 100 but branch at 99.9, when the coverage gate checks the report, then it
# exits nonzero and identifies the failing branch metric.
{
    my ( $exit, $stdout, $stderr ) = run_gate(<<'REPORT');
File              stmt   branch   cond    sub
Total            100.0     99.9  100.0  100.0
REPORT

    is( $exit, 1, 'coverage gate rejects a branch total below 100 with the shortfall status' );
    like( $stderr, qr/below 100\.0: branch 99\.9/, 'coverage gate identifies the failing branch total' );
    unlike( $stdout, qr/coverage gate:/, 'failed coverage gate emits no success message' );
}

# Scenario: parse the abbreviated columns emitted by Devel::Cover 1.52.
# Given its real header and aggregate total column, when checked, then the
# aggregate is ignored and the four required metrics are enforced by name.
{
    my ( $exit, $stdout, $stderr ) = run_gate(<<'REPORT');
File              stmt   bran   cond    sub  total
Total            100.0  100.0  100.0  100.0  100.0
REPORT

    is( $exit, 0, 'coverage gate accepts the Devel::Cover 1.52 report shape' );
    like( $stdout, qr/coverage gate:/, 'real report shape emits the success message' );
    is( $stderr, '', 'real report shape emits no error output' );
}

# Scenario: accept a report only when all four totals equal 100.0.
# Given exact 100.0 totals, when checked, then the gate succeeds and names all
# four enforced metrics.
{
    my ( $exit, $stdout, $stderr ) = run_gate(<<'REPORT');
File              stmt   branch   cond    sub
Total            100.0    100.0  100.0  100.0
REPORT

    is( $exit, 0, 'coverage gate accepts exact 100 totals for all four metrics' );
    like( $stdout, qr/statement.*branch.*condition.*subroutine/i, 'success names all four enforced metrics' );
    is( $stderr, '', 'successful coverage gate emits no error output' );
}

# Scenario: reject a malformed report instead of silently passing it.
# Given no parseable Total row, when checked, then the gate fails closed.
{
    my ( $exit, $stdout, $stderr ) = run_gate("File stmt branch cond sub\n");

    is( $exit, 2, 'coverage gate rejects a report with no Total row as unreadable' );
    like( $stderr, qr/missing Total row/i, 'malformed report explains the missing Total row' );
    unlike( $stdout, qr/coverage gate:/, 'malformed report emits no success message' );
}

# Scenario: no report at all is could-not-look, not nothing-to-report.
# Given entirely empty input, when checked, then the gate fails closed and says
# the report was never produced, distinctly from a report it could parse.
{
    my ( $exit, $stdout, $stderr ) = run_gate('');

    is( $exit, 2, 'coverage gate rejects an absent report as unreadable' );
    like( $stderr, qr/no coverage report/i, 'an absent report is named as such rather than as a missing row' );
    unlike( $stdout, qr/coverage gate:/, 'an absent report emits no success message' );
}

# Feature: a reader that cannot parse its own database says so.
# Scenario: Sereal data read by a Storable reader.
# Given the parse error Devel::Cover emits when the database was written by a
# different serializer, when the gate sees it, then it reports an instrument
# failure rather than a coverage verdict, and names both formats, the reader
# module path, and the fact that re-running cannot help.
{
    my ( $exit, $stdout, $stderr ) = run_gate(
        "Can't read /home/mv/projects/developer-dashboard/cover_db/digests: File is not a perl storable at /usr/share/perl5/Storable.pm line 411.\n"
    );

    is( $exit, 3, 'a serialization mismatch has its own exit status' );
    like( $stderr, qr/INSTRUMENT FAILURE/,       'the verdict is named an instrument failure' );
    like( $stderr, qr/Sereal/,                   'the verdict names the Sereal format' );
    like( $stderr, qr/Storable/,                 'the verdict names the Storable format' );
    like( $stderr, qr/Devel\/Cover\/DB\/IO\.pm/, 'the verdict names the reader module path' );
    like( $stderr, qr/not a corrupt database/i,  'the verdict says re-running will fail identically' );
    like( $stderr, qr/coverage-gate/,            'the verdict points at the canonical entrypoint' );
    unlike( $stdout, qr/coverage gate: statement/, 'an instrument failure reports no coverage figure' );
}

# Scenario: Storable data read by a Sereal reader.
# Given the mismatch in the opposite direction, when the gate sees it, then it
# reaches the same instrument-failure verdict.
{
    my ( $exit, $stdout, $stderr ) = run_gate("Bad Sereal header: Not a valid Sereal document. at offset 1\n");

    is( $exit, 3, 'the opposite mismatch direction also exits as an instrument failure' );
    like( $stderr, qr/INSTRUMENT FAILURE/, 'the opposite direction is also named an instrument failure' );
}

# Scenario: an instrument failure is distinguishable from every other verdict.
# Given the four verdicts the gate can reach, when their exit statuses are
# compared, then all four differ, so a caller can tell a shortfall from an
# unreadable report from an instrument failure without parsing prose.
{
    my ($pass)       = run_gate("File stmt bran cond sub total\nTotal 100.0 100.0 100.0 100.0 100.0\n");
    my ($shortfall)  = run_gate("File stmt bran cond sub total\nTotal 100.0 99.9 100.0 100.0 99.9\n");
    my ($unreadable) = run_gate("File stmt bran cond sub\n");
    my ($instrument) = run_gate("File is not a perl storable at Storable.pm line 411.\n");

    my %distinct = map { $_ => 1 } ( $pass, $shortfall, $unreadable, $instrument );
    is( scalar keys %distinct, 4, 'pass, shortfall, unreadable and instrument failure all have distinct exit statuses' );
    is( $pass, 0, 'only the passing verdict exits zero' );
}

# Scenario: the verdict names the format actually found on disk.
# Given a coverage database whose leading bytes identify its serializer, when an
# instrument failure is reported, then the written format is sniffed from the
# database rather than guessed, and an unrecognisable database is admitted as
# unknown instead of being invented.
for my $case (
    [ 'Sereal',   "=\xF3rl\x05\x00", qr/written as[^\n]*Sereal/i ],
    [ 'Storable', "pst0\x05\x0b",    qr/written as[^\n]*Storable/i ],
    [ 'JSON',     '{"runs":{}}',     qr/written as[^\n]*JSON/i ],
    [ 'unknown',  "not a database\n", qr/written as[^\n]*unknown/i ],
  )
{
    my ( $label, $magic, $expected ) = @{$case};
    my $database = database_written_as($magic);
    my ( $exit, $stdout, $stderr ) = run_gate( "File is not a perl storable\n", '--database', $database );

    is( $exit, 3, "a $label database still reaches the instrument-failure verdict" );
    like( $stderr, $expected, "the verdict reports the $label database format sniffed from disk" );
}

# Scenario: an unknown option is refused rather than silently ignored.
# Given an argument the checker does not understand, when it is invoked, then it
# exits as unusable and never reports a coverage figure.
{
    my ( $exit, $stdout, $stderr ) = run_gate( "File stmt bran cond sub total\nTotal 100.0 100.0 100.0 100.0 100.0\n", '--nonsense' );

    is( $exit, 2, 'an unknown option exits with the unreadable status' );
    unlike( $stdout, qr/coverage gate: statement/, 'an unknown option emits no success message' );
}

# Scenario: reject reports that omit an enforced metric.
# Given a report without branch and condition columns, when checked, then the
# gate fails closed rather than treating the three displayed 100s as complete.
{
    my ( $exit, $stdout, $stderr ) = run_gate(<<'REPORT');
File              stmt    sub
Total            100.0  100.0
REPORT

    isnt( $exit, 0, 'coverage gate rejects a report missing enforced metrics' );
    like( $stderr, qr/(?:missing metrics: branch, condition|duplicate or unknown metric columns)/i, 'missing metrics are identified' );
    unlike( $stdout, qr/coverage gate:/, 'incomplete report emits no success message' );
}

# Scenario: reject malformed numeric fields instead of extracting 100 from them.
# Given signed or suffixed values and unexplained extra fields, when checked,
# then the gate rejects each report without emitting a success message.
for my $case (
    [ 'signed totals', "File stmt bran cond sub total\nTotal -100.0 -100.0 -100.0 -100.0 -100.0\n" ],
    [ 'suffixed total', "File stmt bran cond sub total\nTotal 100.0x 100.0 100.0 100.0 100.0\n" ],
    [ 'unexplained extra value', "File stmt bran cond sub\nTotal 100.0 100.0 100.0 100.0 100.0\n" ],
) {
    my ( $label, $report ) = @{$case};
    my ( $exit, $stdout, $stderr ) = run_gate($report);
    isnt( $exit, 0, "coverage gate rejects $label" );
    like( $stderr, qr/coverage gate:/i, "$label produces a gate diagnostic" );
    unlike( $stdout, qr/coverage gate:/, "$label emits no success message" );
}

# Scenario: contributor guidance documents all four required metrics.
# Given the shipped contribution guide, when its coverage rule is inspected,
# then it names statement, subroutine, branch, and condition explicitly.
{
    my $guide = File::Spec->catfile('CONTRIBUTING.pod');
    open my $handle, '<', $guide or die "cannot read $guide: $!";
    my $body = do { local $/; <$handle> };
    close $handle or die "cannot close $guide: $!";

    like(
        $body,
        qr/100 percent statement, subroutine, branch,\s+and condition coverage/,
        'contributor guide documents all four mandatory metrics',
    );
}

# Purpose: read a repository file in full, failing loudly when it cannot be read.
# Input: a repository-relative path.
# Output: the file content as one string.
sub read_repository_file {
    my ($path) = @_;
    open my $handle, '<', $path or die "cannot read $path: $!";
    my $body = do { local $/; <$handle> };
    close $handle or die "cannot close $path: $!";
    return $body;
}

# Scenario: every CI path runs the one canonical coverage entrypoint.
# Given the repository test and release workflows, when their coverage steps are
# inspected, then each invokes the canonical entrypoint and none of them
# open-codes the three-command chain, because an open-coded chain is what lets
# one command of it run without the library path the others had.
for my $workflow_name (qw(test.yml release-cpan.yml release-github.yml)) {
    my $body = read_repository_file( File::Spec->catfile( '.github', 'workflows', $workflow_name ) );

    like(
        $body,
        qr/perl script\/coverage-gate/,
        "$workflow_name runs the canonical coverage-gate entrypoint",
    );
    unlike(
        $body,
        qr/cover -delete/,
        "$workflow_name does not open-code the coverage chain it could split",
    );
}

# Scenario: the canonical entrypoint still enforces all four metrics.
# Given the entrypoint the workflows now call, when it is inspected, then it
# collects every enforced metric restricted to lib/ and hands the result to the
# fail-closed checker, so relocating the chain did not weaken it.
{
    my $body = read_repository_file($entry);

    for my $metric (qw(statement branch condition subroutine)) {
        like( $body, qr/'\Q$metric\E'/, "the canonical entrypoint requests $metric coverage" );
    }
    like( $body, qr/\^lib\//,                     'the canonical entrypoint restricts the report to lib/' );
    like( $body, qr/check-all-metric-coverage/,   'the canonical entrypoint enforces the report through the checker' );
}

# Scenario: the documented gate is the executed gate.
# Given the contributor testing guide, when its coverage section is read, then
# it tells the reader to run the canonical entrypoint rather than the split
# chain the workflows no longer use.
{
    my $body = read_repository_file( File::Spec->catfile( 'doc', 'testing.md' ) );

    like( $body, qr/script\/coverage-gate/, 'the testing guide documents the canonical coverage entrypoint' );
    unlike(
        $body,
        qr/^cover -delete$/m,
        'the testing guide no longer instructs the reader to type the splittable chain',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/107-all-metric-coverage-gate.t - acceptance contract for the all-metric coverage gate

=head1 PURPOSE

This test verifies that the repository coverage gate accepts only a
Devel::Cover report whose C<lib/> Total row is 100.0 for statement,
subroutine, branch, and condition coverage. It also verifies that missing,
malformed, or below-target reports fail closed and that CI invokes the gate.

=head1 WHY IT EXISTS

The previous CI check requested only statement and subroutine coverage, so
branch and condition regressions could pass. These executable BDD scenarios
prevent the repository workflow and parser from weakening that contract.

=head1 WHEN TO USE

Use this test when changing the coverage workflow, the coverage-report parser,
or the mandatory all-four-metric quality gate.

=head1 HOW TO USE

Run C<prove -lv t/107-all-metric-coverage-gate.t> while iterating, then run
C<prove -lr t> and the live Devel::Cover command before integration.

=head1 WHAT USES IT

Developers, the full Perl test suite, and GitHub Actions use this acceptance
test to keep coverage enforcement at 100.0 for every required metric.

=head1 EXAMPLES

Example 1:

  prove -lv t/107-all-metric-coverage-gate.t

Run the focused acceptance scenarios.

Example 2:

  cover -report text -select_re '^lib/' \
    -coverage statement -coverage branch \
    -coverage condition -coverage subroutine \
    | perl script/check-all-metric-coverage

Verify a collected coverage database using the same gate as CI.

=cut
