#!/usr/bin/perl -w

# One lint job, thirteen copies.
#
# .github/workflows/actionlint.yml is carried unchanged by every distribution
# whose workflows are copies of another's: the reader/producer contract's four
# callers and the siblings its body checks out, and the eight distributions the
# location-predicate fuzz assembles.  That file is what catches a workflow
# GitHub would refuse whole - a job-level env reading ${{ runner.temp }} turned
# Database-BI's browser.yml into "Unrecognized named-value: 'runner'" and ran
# none of its four jobs - and it only catches it in the repository that has it.
# A fix applied to one copy and not the others therefore leaves the others
# unguarded, silently, which is the state this file exists to make loud.
#
# The copies are compared byte for byte rather than by their steps.  A quiet
# difference in the pinned version, the checksum or the comment that says what
# the job is for is exactly the change that makes one distribution lint by
# different rules from the rest, and a comparison of the steps would not see it.
#
# No job assembles all thirteen: the contract body has seven checkouts and the
# fuzz job eight, with Geo-Coder-List in both.  So a sibling that is not beside
# this distribution is reported and not failed - it is not that this run's
# workspace is incomplete, it is that this job was never asked about it - and
# every sibling that *is* checked out must carry the copy.  A checkout that has
# the file but no longer matches fails, and so does a directory that has adopted
# the file without being listed here, since otherwise a fourteenth copy would be
# the one nobody compares.
#
# Because landing an edit to the file is a change to all thirteen, the state of
# the rollout is written to the job summary as a table - each distribution and
# what its copy is - rather than left to be reassembled from the failures of
# thirteen runs: the remaining work then reads the same wherever it is looked at,
# and the two jobs that assemble the workspace between them state all of it.
# GITHUB_STEP_SUMMARY is set by GitHub for every step and unset in a local run,
# which is when there is no summary to write and nothing to write it for; the
# Markdown goes to that file and never to stdout, which is TAP.
#
# The file is not shipped (.github is not in the MANIFEST), so an installed copy
# of this distribution says it has nothing to compare and skips; the same is true
# of this distribution's own CI, which checks out no siblings.  The two jobs that
# do assemble the workspace run this file and treat a skip as a failure, which is
# what keeps a silent skip from looking like a pass.

use strict;
use warnings;

use Cwd qw(abs_path);
use FindBin qw($Bin);
use File::Spec::Functions qw(catdir catfile updir);
use Test::Most;

# Every distribution that carries the file, as of 0.52.  A distribution that
# adopts it has to be added here: the last test in this file fails until it is,
# because a copy this list does not name is one no run compares.
my @FAMILY = qw(
	Database-BI
	Geo-Coder-CA
	Geo-Coder-DataScienceToolkit
	Geo-Coder-Free
	Geo-Coder-GeoApify
	Geo-Coder-List
	Geo-Coder-Postcodes
	Geo-Coder-XYZ
	Geo-Location-Point
	Geo-Location-Predicate
	HTML-Genealogy-Map
	HTML-OSM
	Test-Consumer-Contract
);

# This distribution, whose copy is the one the others are compared with.
my $SELF = 'Geo-Coder-Free';

# The directory holding the sibling distributions: the parent of this checkout.
# Resolved, so the labels below name a directory rather than a path with ..s.
my $WORKSPACE = abs_path(catdir($Bin, updir(), updir()))
	// catdir($Bin, updir(), updir());

my $REFERENCE = catfile(abs_path(catdir($Bin, updir())), '.github', 'workflows', 'actionlint.yml');

my $reference = _slurp($REFERENCE);

plan skip_all => '.github is not part of the distribution, so there is no copy here to compare'
	unless defined $reference;

my @present = grep { -d catdir($WORKSPACE, $_) } @FAMILY;

plan skip_all => "no distribution that carries the lint job is checked out under $WORKSPACE"
	unless grep { $_ ne $SELF } @present;

note("Comparing the copies under $WORKSPACE with $REFERENCE");

sub _slurp {
	my ($file) = @_;

	open(my $fh, '<', $file) or return;
	local $/;
	my $text = <$fh>;
	close($fh);

	return $text;
}

# The first line on which two copies differ, so a failure names the edit rather
# than printing two workflows at each other: the line number, and both lines.
sub _difference {
	my ($ours, $theirs) = @_;

	my @ours   = split(/\n/, $ours);
	my @theirs = split(/\n/, $theirs);

	for my $i (0 .. $#ours) {
		next if $i <= $#theirs && $ours[$i] eq $theirs[$i];

		return (
			$i + 1,
			$ours[$i],
			$i <= $#theirs ? $theirs[$i] : '',
			$i > $#theirs ? 'the copy there is shorter' : '',
		);
	}

	return ($#theirs + 2, '', $theirs[$#theirs + 1], 'the copy here is shorter')
		if $#theirs > $#ours;

	return;
}

# The checkouts under the workspace: hidden directories are not checkouts, and
# neither are plain files.
sub _directories {
	opendir(my $dh, $WORKSPACE) or return ();
	my @names = sort grep { !/\A\./ && -d catdir($WORKSPACE, $_) } readdir($dh);
	closedir($dh);

	return @names;
}

# What each copy is, as the job summary says it: the table is the rollout's
# remaining work, so every distribution appears in it, including the ones this
# job does not have - "not checked out here" is a different claim from "same".
my %copy = ($SELF => 'the copy the others are compared with');

for my $dist (@FAMILY) {
	next if $dist eq $SELF;

	my $root = catdir($WORKSPACE, $dist);

	unless (-d $root) {
		$copy{$dist} = 'not checked out here';
		note("$dist is not checked out here, so its copy was not compared");
		next;
	}

	my $candidate = catfile($root, '.github', 'workflows', 'actionlint.yml');
	my $text = _slurp($candidate);

	unless (defined $text) {
		$copy{$dist} = 'no copy';
		fail("$dist carries .github/workflows/actionlint.yml");
		diag("$root is checked out, so a distribution without the file is one that never got the job;"
			. ' the copy to add is ' . $REFERENCE);
		next;
	}

	if (ok($text eq $reference, "$dist carries the same actionlint.yml")) {
		$copy{$dist} = 'same';
		next;
	}

	my ($line, $ours, $theirs, $shorter) = _difference($reference, $text);

	$copy{$dist} = defined $line ? "differs at line $line" : 'differs';

	diag($dist . "'s copy differs at line $line:");
	diag('  here:  ' . $ours);
	diag('  there: ' . $theirs);
	diag('  ' . $shorter) if $shorter;
	diag('a difference in the file is a difference in the rules that repository is linted by,'
		. " so the copy in $dist should be made the same as $REFERENCE");
}

my %family = map { $_ => 1 } @FAMILY;
my @strangers = grep {
	-f catfile($WORKSPACE, $_, '.github', 'workflows', 'actionlint.yml')
} grep { !$family{$_} } _directories();

is_deeply \@strangers, [], 'every checkout with a copy of the job is one this test compares'
	or diag('a distribution that adopted the file has to be named in @FAMILY,'
		. ' or its copy is the one no run checks: ' . join(' ', @strangers));

# Appends rather than writes: the contract job runs four test files and the fuzz
# job has already put the fuzz report here, and a test that truncated the
# summary would take another step's finding with it.
sub _report {
	my ($copy, $strangers) = @_;

	my $summary = $ENV{GITHUB_STEP_SUMMARY};
	return unless defined $summary && length $summary;

	open(my $fh, '>>', $summary) or do {
		note("could not append the copy report to $summary: $!");
		return;
	};

	my @compared = grep { $copy->{$_} ne 'not checked out here' } grep { $_ ne $SELF } @FAMILY;
	my @stale = grep { $copy->{$_} =~ /\A(?:differs|no copy)/ } @FAMILY;
	my @absent = grep { $copy->{$_} eq 'not checked out here' } @FAMILY;

	# Separated from whatever the step above wrote, which this file is appended to
	# rather than replacing.
	print $fh "\n" if -s $summary;
	print $fh "## Workflow lint copies\n\n";

	if (@stale) {
		printf $fh '%s checked out here %s not the same as **%s**\'s: %s.'
			. "  Make each one below the same as **%s**'s, so no repository is left"
			. " linted by a different rule.\n\n",
			@stale > 1 ? scalar(@stale) . ' copies' : 'One copy',
			@stale > 1 ? 'are' : 'is', $SELF,
			join(', ', map { $_ . ' (' . $copy->{$_} . ')' } @stale), $SELF;
	} elsif (@compared) {
		printf $fh "All %d copies checked out here are the same as **%s**'s.\n\n",
			scalar(@compared), $SELF;
	}

	print $fh "| Distribution | Copy |\n| --- | --- |\n";
	printf $fh "| %s | %s |\n", $_, $copy->{$_} for @FAMILY;

	if (@absent) {
		printf $fh "\n%d %s not checked out in this job: %s.  No job assembles all %d -"
			. " the contract body has seven checkouts and the fuzz job eight, Geo-Coder-List"
			. " in both - so each job compares the copies it was given.\n",
			scalar(@absent), @absent == 1 ? 'is' : 'are', join(', ', @absent), scalar(@FAMILY);
	}

	if (@$strangers) {
		printf $fh "\nA copy is also in %s, which this test does not name, so no run compares it:\n"
			. " add it to \@FAMILY in t/actionlint-drift.t.\n", join(', ', @$strangers);
	}

	print $fh "\n";
	close($fh);

	note("wrote the copy report to $summary");
}

_report(\%copy, \@strangers);

done_testing();
