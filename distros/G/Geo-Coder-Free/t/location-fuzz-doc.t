#!/usr/bin/env perl

# LOCATION-PREDICATE-FUZZ.md prints the harness's report for this workspace so
# that a reader can see what a run says, and so that a change in the rule or in
# one of the six shows up as a diff against it.  That only holds while the
# sample is the output: a heading, a count or a changed verdict would leave the
# document describing a run nobody can reproduce, and the file reads as if it
# were still right.  This runs the harness exactly as the document names it -
# 20,000 values and the default seed - and compares stdout with the sample.
#
# The sample is written rather than typed: --update-document rewrites that span
# of the document from a real run, so a wording change is one command.  This
# checks that command as well, on copies of the document: one with a table cell
# changed by hand has to be put back, and one with a section after the sample has
# to keep it - because a sample that can be regenerated and still be maintained
# by hand is a sample that will be.
#
# The document is this distribution's own - it lives beside this file rather than
# in the workspace - so the check runs wherever the eight checkouts are assembled,
# and skips only where they are not, in the same way as t/location-predicates.t
# does.  That is what makes it a check in CI rather than a skip: the workspace job
# in .github/workflows/location-predicates.yml runs this file.

use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use FindBin qw($Bin);
use Test::Most;

# The six that ask the rule, the distribution that holds it, and the facade the
# harness runs from.
my @DISTS = qw(
	Geo-Coder-Free
	Geo-Location-Predicate
	Geo-Coder-CA
	Geo-Coder-DataScienceToolkit
	Geo-Coder-GeoApify
	Geo-Coder-List
	Geo-Coder-Postcodes
	Geo-Coder-XYZ
);

# The run the document quotes, and the only number in it that a caller chooses:
# the seed is the harness's default, so a plain run has to reproduce it.
my $ITERATIONS = 20000;

# Under prove -t $Bin is tainted; detaint before it reaches a file name.
my $root = do {
	(my $d = File::Spec->catdir($Bin, File::Spec->updir())) =~ /\A(.*)\z/s;
	$1;
};

my $workspace = do {
	(my $d = File::Spec->catdir($root, File::Spec->updir())) =~ /\A(.*)\z/s;
	$1;
};

my $document = File::Spec->catfile($root, 'LOCATION-PREDICATE-FUZZ.md');
my $harness = File::Spec->catfile($root, 'scripts', 'location-predicate-fuzz.pl');

plan skip_all => "$document is not in this distribution" unless -f $document;

my @absent = grep { !-d File::Spec->catdir($workspace, $_, 'lib') } @DISTS;
plan skip_all => 'the sibling checkouts are not in the workspace: ' . join(', ', @absent)
	if @absent;

BAIL_OUT("$harness is not in the distribution") unless -f $harness;

my $dir = tempdir(CLEANUP => 1);

# ---------------------------------------------------------------------------
# Running the harness, and holding the document
# ---------------------------------------------------------------------------

# Run it as the document names it, plus whatever the caller adds, and read back
# both streams: the report on stdout, the log line on stderr.  -| rather than a
# shell, so a path with a space in it needs no quoting and nothing is inherited.
my $runs = 0;

sub run_harness
{
	my (@flags) = @_;

	my $echo = File::Spec->catfile($dir, 'stderr-' . ++$runs . '.txt');

	# The child's stderr is a file of ours rather than this test's, so the
	# harness's log line is readable here without appearing as bare text in the
	# TAP stream.
	open(my $saved, '>&', \*STDERR) or BAIL_OUT("Cannot save stderr: $!");
	open(STDERR, '>', $echo) or BAIL_OUT("Cannot write $echo: $!");

	my $pid = open(my $out, '-|', $^X, $harness, '--iterations', $ITERATIONS, @flags);
	BAIL_OUT("Cannot run $harness: $!") unless defined($pid);
	my $report = do { local $/; <$out> } // '';
	close($out);
	my $status = $? >> 8;

	open(STDERR, '>&', $saved) or BAIL_OUT("Cannot restore stderr: $!");

	my $errors;
	{
		open(my $err, '<', $echo) or BAIL_OUT("Cannot read $echo: $!");
		$errors = do { local $/; <$err> } // '';
		close($err) or BAIL_OUT("Cannot close $echo: $!");
	}

	return ($status, $report, $errors);
}

sub slurp
{
	my ($file) = @_;

	open(my $fh, '<', $file) or BAIL_OUT("Cannot read $file: $!");
	my $text = do { local $/; <$fh> } // '';
	close($fh) or BAIL_OUT("Cannot close $file: $!");

	return $text;
}

sub spew
{
	my ($file, $text) = @_;

	open(my $fh, '>', $file) or BAIL_OUT("Cannot write $file: $!");
	print {$fh} $text or BAIL_OUT("Cannot write $file: $!");
	close($fh) or BAIL_OUT("Cannot close $file: $!");
}

# ---------------------------------------------------------------------------
# The sample, as the document prints it
# ---------------------------------------------------------------------------

# The sample is the text from its own heading to the end of the file: it is the
# harness's Markdown printed as Markdown, not a code block, so the headings in
# it are the document's headings too.  Read raw so the comparison is of the
# bytes a run writes.
my $text = slurp($document);

# It runs to the end of the file today, but a section added after it is a
# heading of the document rather than a line of the report, so stop there too.
my ($sample) = $text =~ /\n## The run\n\n.*?\n\n(## Harness output\n.*?)(?=\n## |\z)/s;
BAIL_OUT("Cannot find the sample report under '## The run' in $document")
	unless defined($sample);
$sample .= "\n" unless $sample =~ /\n\z/;

# ---------------------------------------------------------------------------
# The report the harness prints now
# ---------------------------------------------------------------------------

my ($status, $actual, $errors) = run_harness();

# ---------------------------------------------------------------------------
# The comparison
# ---------------------------------------------------------------------------

# A failed run would differ from the sample in a dozen ways, all of them less
# useful than the reason it failed, so say that first.
is($status, 0, 'the run the document quotes passes')
	or diag($errors);

if($actual ne $sample) {
	my @documented = split(/\n/, $sample, -1);
	my @printed    = split(/\n/, $actual, -1);

	my $line = 0;
	$line++ while $line < @documented && $line < @printed
		&& $documented[$line] eq $printed[$line];

	diag('the document and the harness differ at line ' . ($line + 1));
	diag('documented: ' . (defined($documented[$line]) ? $documented[$line] : '(end of sample)'));
	diag('harness:    ' . (defined($printed[$line]) ? $printed[$line] : '(end of report)'));
	diag('the sample is under "## The run" in ' . $document);
}

ok($actual eq $sample, 'the sample report in LOCATION-PREDICATE-FUZZ.md is the report the harness prints');

# ---------------------------------------------------------------------------
# Regenerating it
# ---------------------------------------------------------------------------

# --update-document is what an author runs after a wording change.  It is tried
# on copies, never on the document: a test that could rewrite the thing it is
# checking could pass by making the two agree.
subtest 'the sample is regenerated by one command, not by hand' => sub {
	my $copy = File::Spec->catfile($dir, 'LOCATION-PREDICATE-FUZZ.md');

	# An edit of the kind a hand-maintained sample collects: one cell of the
	# table, which is exactly what a reader would not notice had gone stale.
	(my $edited = $text) =~ s/\| digits only \| REJECT \|/| digits only | ACCEPT |/;
	isnt($edited, $text, 'the copy now carries a hand edit');
	spew($copy, $edited);

	my ($st, $out, $err) = run_harness('--update-document', $copy);

	is($st, 0, 'the run that replaces the hand edit passes');
	like($err, qr/\bWrote the sample report into\b/, 'it says it rewrote the sample');
	is(slurp($copy), $text, 'the hand edit is replaced by what the run printed');
	is($out, $sample, 'the report is still stdout when it is written into the document');

	# A section added after the sample is the document's, not the report's:
	# the rewrite stops at it rather than swallowing what was written there.
	spew($copy, $text . "\n## Added later\n\nText.\n");

	($st, $out, $err) = run_harness('--update-document', $copy);

	is($st, 0, 'a document with a section after the sample is rewritten');
	like($err, qr/\balready contains this report\b/,
		'the sample itself needed no change, so nothing was written');
	is(slurp($copy), $text . "\n## Added later\n\nText.\n",
		'the section after the sample is left in place');
};

done_testing();
