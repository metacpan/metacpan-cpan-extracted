#!/usr/bin/perl -w

# CONTRACT_STRICT: the contract must not pass having checked nothing.
#
# Parts 2 and 3 of t/consumer-contract.t skip when a sibling checkout is absent,
# which is right for an installation and wrong for the CI job in
# .github/workflows/contract.yml: a job that was supposed to put the workspace
# there would go green having checked neither the consumers nor their
# registration.  These subtests run the real contract file in a workspace of
# their own, with the switch and without it, so the failure is shown to come
# from the switch rather than from the workspace being incomplete.

use strict;
use warnings;

use FindBin qw($Bin);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::Most;

# The workspace this checkout lives in, which is where the files come from.
my $WORKSPACE = File::Spec->catdir($Bin, File::Spec->updir(), File::Spec->updir());

# Without the workspace there is nothing to copy and nothing to prove: this file
# guards the CI job, it is not a test of an installed distribution.
plan skip_all => 'the sibling checkouts are not present'
	unless -d File::Spec->catdir($WORKSPACE, 'Test-Consumer-Contract')
		&& -d File::Spec->catdir($WORKSPACE, 'Geo-Location-Point');

# What the contract reads: the test itself, the value object it checks, the
# producers it holds to their keys, and the checker.  Database-BI and
# HTML-Genealogy-Map are left out on purpose - they are the checkouts whose
# absence the switch has to turn into a failure.
my @FILES = (
	'Geo-Coder-Free/t/consumer-contract.t',
	'Geo-Coder-Free/lib/Geo/Coder/Free.pm',
	'Geo-Coder-Free/lib/Geo/Coder/Free/OpenAddresses.pm',
	'Geo-Coder-Free/lib/Geo/Coder/Free/MaxMind.pm',
	'Geo-Coder-Free/lib/Geo/Coder/Free/Local.pm',
	'Geo-Location-Point/lib/Geo/Location/Point.pm',
	'Test-Consumer-Contract/lib/Test/Consumer/Contract.pm',
);

sub _copy_into
{
	my ($dir, $rel) = @_;

	my $from = File::Spec->catfile($WORKSPACE, split(m{/}, $rel));
	my $to   = File::Spec->catfile($dir, split(m{/}, $rel));

	make_path(dirname($to));
	copy($from, $to) or die "Cannot copy $from to $to: $!";

	return;
}

# A workspace holding everything above, minus whichever pieces the caller takes
# away.  CLEANUP removes it whatever the test does.
sub _workspace
{
	my (%opts) = @_;

	my $dir = tempdir(CLEANUP => 1);

	for my $rel (@FILES) {
		next if($opts{'without_checker'} && $rel =~ /Test-Consumer-Contract/);
		_copy_into($dir, $rel);
	}

	return ($dir, File::Spec->catfile($dir, 'Geo-Coder-Free', 't', 'consumer-contract.t'));
}

# A copy of the workspace without the checker is not enough to make it
# unloadable: a checker may also be installed, and then the child's require finds
# that one and the branch that fails the job is never reached.  This is a
# directory holding a Test::Consumer::Contract that does not compile, put first
# on the child's @INC so the load fails wherever the child is installed.
sub _unloadable_checker
{
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'Test', 'Consumer', 'Contract.pm');

	make_path(dirname($file));
	open(my $fh, '>', $file) or die "Cannot write $file: $!";
	# A brace left open: a compile error, which is what a checker that cannot be
	# loaded looks like from the child, rather than a die at run time.
	print $fh "package Test::Consumer::Contract;\n\nuse strict;\n\nsub _broken {\n";
	close($fh) or die "Cannot write $file: $!";

	return $dir;
}

# Run the contract file the way the CI job does, in a child process, with the
# switch set or unset in its environment - not in ours.
sub _run
{
	my ($test, $strict, $lib) = @_;

	local $ENV{'CONTRACT_STRICT'} = $strict;
	local $ENV{'PERL5LIB'};
	$ENV{'PERL5LIB'} = join(':', grep { length($_) } $lib // '', $ENV{'PERL5LIB'} // '');

	open(my $fh, '-|', $^X, '-w', $test) or die "Cannot run $^X: $!";
	local $/;
	my $output = <$fh> // '';
	close($fh);

	return ($? >> 8, $output);
}

subtest 'with the switch on, a workspace missing a checkout fails the job' => sub {
	my ($dir, $test) = _workspace();
	my ($status, $output) = _run($test, 1);

	isnt($status, 0, 'the job failed') or diag($output);
	like($output, qr/CONTRACT_STRICT is set and the workspace has no .*Database-BI/,
		'the failure says which checkout is missing') or diag($output);
	like($output, qr/HTML-Genealogy-Map/, 'and names every missing checkout') or diag($output);
};

subtest 'without it the same workspace passes, having checked neither part 2 nor 3' => sub {
	# The contrast that makes the subtest above evidence: nothing else about the
	# workspace changed, and this is what the job would have reported.
	my ($dir, $test) = _workspace();
	my ($status, $output) = _run($test, undef);

	is($status, 0, 'the job passed') or diag($output);
	like($output, qr/sibling checkouts are not present/,
		'and said so on its way to passing') or diag($output);
};

subtest 'with the switch on, a checker that cannot be loaded fails the job too' => sub {
	my ($dir, $test) = _workspace(without_checker => 1);
	my ($status, $output) = _run($test, 1, _unloadable_checker());

	isnt($status, 0, 'the job failed') or diag($output);
	like($output, qr/CONTRACT_STRICT is set and Test::Consumer::Contract cannot be loaded/,
		'and names the checker rather than the workspace') or diag($output);
};

done_testing();
