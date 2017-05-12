# typical usages

use strict;
use warnings;

use Test::More;
use IPC::Run qw(run);

my $perl = $^X;

my $dump;
$ARGV[0] and ($dump = 1);

my @help_args = (
	['--help'],
	['-h'],
	[qw(-h this)],
	[qw(--help that)],
	[qw(--this --that --help)],
	[qw(--help --this)],
	[qw(--help --that --help)],
	[qw(--this --that)],
	);

plan(tests =>
	1 +
	scalar(@help_args) * 3 +
	0);

use Getopt::Helpful;
use File::Basename;

my $test = dirname($0);
length($test) and ($test =~ s#/*$#/#);
$test .= "help_args-run.pl";
my $exists = (-e $test);
ok($exists, "$test existence");
foreach my $args (@help_args) {
	SKIP: {
		$exists or skip("cannot find $test file", 3);
		my ($in, $out, $err);
		ok(run([$perl, $test, @$args], \$in, \$out, \$err), "$test @$args");
		$dump and print "$out\n";
		($dump and $err) and warn "$err";
		ok($err eq '', "no stderr");
		my $lookforit = basename($test);
		my $line = join(" ", @$args);
		my $no0 = ($line =~ m/th/);
		if($line =~ m/-h/) {
			ok((
				($out =~ m/options:/) and
				($no0 ? 1 : ($out =~ m/usage:/)) and
				($no0 ? 1 : ($out =~ m/$lookforit/))
			), "sane message");
		}
		else { # look for dirt
			ok($out eq '', 'nice and quiet');
		}
	}
}

