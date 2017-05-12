#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use Log::Parallel::Paths;
use File::Temp qw(tempdir);
use File::Slurp;
use File::Path;
use FindBin;
use YAML;
use File::Glob ':glob';

my $finished = 0;

END { ok($finished, 'finished') }

my $path_to_t = $FindBin::Bin;
my $tmpdir = tempdir(CLEANUP => 1);

chdir($tmpdir) or BAIL_OUT("chdir $!");

mkpath([qw(
	top
	bydate/2008/07/06
	bydate/2008/07/07
	bydate/2008/09/01
	bydate/208/09/02
	bydate/20a8/07/07
	bydate/2008/073/07
	bydate/2008/1a/07
)]);

my @tspec = (
	{
		YYYY	=> 2008,
		MM	=> 7,
		DD	=> 6,
		BUCKET	=> 1,
		v	=> 'bydate/2008/07/06/bucket00001.stuff',
	},
	{
		YYYY	=> 2008,
		MM	=> 7,
		DD	=> 6,
		BUCKET	=> 2,
		v	=> 'bydate/2008/07/06/bucket00002.stuff',
	},
	{
		YYYY	=> 2008,
		MM	=> 7,
		DD	=> 7,
		BUCKET	=> 3,
		v	=> 'bydate/2008/07/07/bucket00003.stuff',
	},
	{
		YYYY	=> 2008,
		MM	=> 9,
		DD	=> 1,
		BUCKET	=> 4,
		OTHER	=> 2009,
		v	=> 'bydate/2008/09/01/bucket00004.stuff',
	},
);

for my $i (@tspec) {
	my $f = path_to_filename("bydate/%YYYY%/%MM%/%DD%/bucket%BUCKET%.stuff", %$i);
	is($f, $i->{v}, "filename $i->{v}");
	write_file($i->{v}, Dump($i));
}

write_file("bydate/2008/09/01/bucket0009.stuff", "NO MATCH\n");
write_file("bydate/208/09/02/bucket0008.stuff", "NO MATCH\n");
write_file("bydate/20a8/07/07/bucket0008.stuff", "NO MATCH\n");
write_file("bydate/2008/073/07/bucket0008.stuff", "NO MATCH\n");
write_file("bydate/2008/1a/07/bucket0008.stuff", "NO MATCH\n");

ok(1, 'test tree made');

my $gp = path_to_shell_glob("bydate/%YYYY%/%MM%/%DD%/bucket%BUCKET%.stuff");

my (@gf) = bsd_glob($gp);

unlike($_, qr/20a8|073|1a|208/, 'glob mismatch') for @gf;

is(scalar(grep($_ eq 'bydate/2008/07/06/bucket00001.stuff', @gf)), 1, 'has required');
is(scalar(grep($_ eq 'bydate/2008/07/06/bucket00002.stuff', @gf)), 1, 'has required');
is(scalar(grep($_ eq 'bydate/2008/07/07/bucket00003.stuff', @gf)), 1, 'has required');
is(scalar(grep($_ eq 'bydate/2008/09/01/bucket00004.stuff', @gf)), 1, 'has required');

my ($re, $func) = path_to_regex("bydate/%YYYY%/%MM%/%DD%/bucket%BUCKET%.stuff");

ok($re, 'got a regex');
ok($func, 'got a regex');

my @wanted = sort map { $_->{v} } @tspec;

my @got = sort grep /$re/, @gf;

is("@got", "@wanted", "re works");

my %datas = map { $_->{v} => $_ } @tspec;

delete $_->{v} for values %datas;
delete $_->{OTHER} for values %datas;

for my $fn (@gf) {
	ok $fn =~ /$re/;
	my %d = &$func;
	my %nd;
	{
		no warnings;
		%nd = map { $_ => ( $d{$_} != 0 or $d{$_}+0 eq $d{$_} ) ? $d{$_}+0 : $d{$_} } keys %d;
	}

	is(Dump(\%nd), Dump($datas{$fn}), "data items for $fn");
}

my ($re2, $func2) = path_to_regex("/var/access_logs/%YYYY%.%MM%.%DD%{,.bz2}");

ok($re2, 'got a regex');
ok($func2, 'got a regex');

my @tests = qw(
	/var/access_logs/2009.03.19
	/var/access_logs/2008.03.18.bz2
	/var/access_logs/2008.03.17.gz
	/var/access_logs/x2008.03.15.gz
	/var/access_logs/2008.03.14.bz23
);

my (@matched) = grep { /$re2/ } @tests;

is("@matched", "/var/access_logs/2009.03.19 /var/access_logs/2008.03.18.bz2");

$finished = 1;
