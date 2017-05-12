#!/usr/local/bin/perl -I. -w

use Getopt::Tiny;

my @td;
my $records;
my $batchsize;
my $remote;
my $rsh;
my $onefile;
my $sleep;
my $gzip;
my $rprocess;
my @archive;
my %months;
my $delete;
my $preserve;
my $forcestop;
my %zmonths;

# begin usage info
my (%flags) = (
	'batchsize'	=> \$batchsize,	# cn 12
	'records'	=> \$records,	# cn 17
	'gzip'		=> \$gzip,	# cn 14
	'month'		=> \%months,	# cn 15
	'dir'		=> \@td,	# cn 13
	'rsh'		=> \$rsh,	# cn 20
	'sleep'		=> \$sleep,	# cn 21
	'onefile'	=> \$onefile,	# cn 16
	'rprocess'	=> \$rprocess,	# cn 19
	'archive'	=> \@archive,	# cn 11
	'remote'	=> \$remote,	# cn 18
);
my (%switches) = (
	'delete'	=> \$delete,	# cn 22
	'preserve'	=> \$preserve,	# cn 24
	'force'		=> \$forcestop,	# cn 23
);
# end usage info

my (@av) = qw(
	-dir a
	-dir b
	-batchsize 9
	-delete
	-noforce
	-month August=9
	-month July=32 November=92
	-archive 10 20 30
	-archive 40
);

getopt(\@av, \%flags, \%switches);

print "1..28\n";

print $#td == 1			? "ok 1\n" : "not ok 1\n";
print $td[0] eq 'a'		? "ok 2\n" : "not ok 2\n";
print $td[1] eq 'b'		? "ok 3\n" : "not ok 3\n";
print $batchsize eq '9'		? "ok 4\n" : "not ok 4\n";
print $delete			? "ok 5\n" : "not ok 5\n";
print ! $forcestop		? "ok 6\n" : "not ok 6\n";
print $archive[1] eq '20'	? "ok 7\n" : "not ok 7\n";
print $archive[2] eq '30'	? "ok 8\n" : "not ok 8\n";
print $archive[3] eq '40'	? "ok 9\n" : "not ok 9\n";

sub usage {
	print $_[0] eq 'foobar'	? "ok 10\n" : "not ok 10\n";
}

getopt([ 'foobar' ], \%flags, \%switches);

undef &usage;

$Getopt::Tiny::usageHandle = 'STDOUT';

open(USAGE, "-|") or do {
	getopt([ 'foobar' ], \%flags, \%switches);
	exit(0);
};
while(<USAGE>) {
	if (/cn (\d+)/) {
		print "ok $1\n";
	}
}

print $archive[0] eq '10'	? "ok 25\n" : "not ok 25\n";
print $months{August} eq '9'	? "ok 26\n" : "not ok 26\n";
print $months{July} eq '32'	? "ok 27\n" : "not ok 27\n";
print $months{November} eq '92'	? "ok 28\n" : "not ok 28\n";

if (-t STDOUT) {
	getopt([ 'foobar' ], \%flags, \%switches);
}
