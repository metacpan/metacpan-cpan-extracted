#!/usr/bin/env perl
#
# README.md is generated from the POD of the module the distribution is named
# after, so the two can only drift when one is edited and the other is not -
# which is invisible until the next regeneration quietly undoes the edit.  This
# compares them, and says which line differs.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;

use File::Basename qw(dirname);
use File::Spec;
use File::Temp qw(tempdir);

my $ROOT = File::Spec->catdir(dirname(File::Spec->rel2abs($0)), File::Spec->updir());

# Written down once: the same path is what the generator is given, what the
# skip message names and what the advice on failure repeats.
my $MODULE = File::Spec->catfile('lib', 'Mail', 'Send', 'DKIM.pm');
my $SOURCE = File::Spec->catfile($ROOT, $MODULE);
my $README = File::Spec->catfile($ROOT, 'README.md');
my $HEADER = File::Spec->catfile($ROOT, '.pod2github-header.md');

plan skip_all => "Cannot find $SOURCE" unless(-r $SOURCE);
plan skip_all => "Cannot find $README" unless(-r $README);
plan skip_all => "Cannot find $HEADER" unless(-r $HEADER);

sub slurp
{
	my $path = shift;

	local $/;
	open(my $fh, '<', $path) or return '';
	my $text = <$fh>;
	close($fh);

	return $text;
}

# The test may run under a perl that is not the one pod2github was installed
# with, so look beside it first, then on PATH.
sub find_pod2github
{
	my $beside_perl = File::Spec->catfile(dirname($^X), 'pod2github');
	return $beside_perl if(-x $beside_perl);

	foreach my $dir (File::Spec->path()) {
		my $candidate = File::Spec->catfile($dir, 'pod2github');
		return $candidate if(-x $candidate);
	}

	return undef;
}

my $pod2github = $ENV{'POD2GITHUB'} || find_pod2github();
plan skip_all => 'pod2github is not installed (cpanm Pod::Github)' unless($pod2github);

my $tmp = tempdir(CLEANUP => 1);
my $out = File::Spec->catfile($tmp, 'README.md');
my $err = File::Spec->catfile($tmp, 'stderr.txt');

my $pid = fork();
die "fork: $!" unless(defined($pid));

if(!$pid) {
	# The config is found by looking in the current directory, so the generator
	# has to run where a person would run it: the root of the project.
	chdir($ROOT) or exit 127;
	# The Z specifications in the POD are not ASCII; without a UTF-8 layer on
	# STDOUT the generator warns "Wide character" once for each.
	$ENV{'PERL_UNICODE'} = 'S';
	open(STDOUT, '>', $out) or exit 127;
	open(STDERR, '>', $err) or exit 127;
	exec($pod2github, $MODULE) or exit 127;
}

waitpid($pid, 0);

is($?, 0, 'pod2github runs without error');
is(slurp($err), '', 'and without warnings');

my $generated = slurp($out);
my $committed = slurp($README);

# The heading shift leaves the document with no H1, which is what the header
# file is for; if the config is ignored the output begins with a '##' instead.
# Compared against the header itself rather than against a title retyped here,
# so the title can be changed in the one place it lives.
my $header = slurp($HEADER);
is(substr($generated, 0, length($header)), $header, 'the header file supplies the H1 title');

if($generated ne $committed) {
	my @generated = split(/\n/, $generated);
	my @committed = split(/\n/, $committed);

	my $first = 0;
	while($first < @generated && $first < @committed && $generated[$first] eq $committed[$first]) {
		$first++;
	}

	diag('README.md is out of date; regenerate it with:');
	diag("    PERL_UNICODE=S pod2github $MODULE > README.md");
	diag('first difference at line ' . ($first + 1) . ':');
	diag('  generated: ' . ($generated[$first] // '(end of file)'));
	diag('  README.md: ' . ($committed[$first] // '(end of file)'));
}

is($generated, $committed, 'README.md is what the POD generates');

done_testing();
