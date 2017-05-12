# Before ake install' is performed this script should be runnable with
# `make test'. After ake install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}

use lib qw( ./ );
require 'tz_test_adj.pl';
require LaBrea::Tarpit;
import LaBrea::Tarpit qw(
	process_log
	write_cache_file
	find_old_threads
	);

$loaded = 1;
print "ok 1\n";
$test = 2;

my $expect = new LaBrea::Tarpit::tz_test_adj;

sub ok {
  print "ok $test\n";
  ++$test;
}

my %tarpit;
my $logfile1 = './labrea_time.log';
my $logfile2 = './labrea_date.log';
my $cachefile = './labrea.cache.tmp';

print "failed to open $logfile\nnot "
	unless process_log(\%tarpit,$logfile1,1);
&ok;

print "failed to open $logfile\nnot "
	unless process_log(\%tarpit,$logfile2,1);
&ok;

##  took out test 4, too lazy to renumber everything
&ok;

# setup complete
## test 5
# test for all older than newest time +1
my %report;
my $rv = find_old_threads(\%tarpit,\%report,,0,1007243496);

print "found $rv items, not 5\nnot "
	unless $rv == 5;
&ok;

## test 6
my $expected = 
'63.227.234.71:4628 -> 80 = '.$expect->{1007241067}.'
63.87.135.216:3204 -> 80 = '.$expect->{1007241123}.'
63.222.243.6:2710 -> 80 = '.$expect->{1007241125}.'
216.82.114.82:3126 -> 80 = 1007243462
63.14.244.226:4166 -> 80 = 1007243495
';
my $response = '';
foreach(sort {$report{$a} <=> $report{$b}} keys %report) {
  $response .= "$_ = $report{$_}\n";
}
print "response\n$response
ne expected\n$expected\nnot "
	unless $response eq $expected;
&ok;

## test 7
# add 1200 seconds to lop off bottom two (newest)
%report = ();
$rv = find_old_threads(\%tarpit,\%report,0.0139,1007243496);

# should have 3 items
print "found $rv items, not 3\nnot "
	unless $rv == 3;
&ok;

## test 8
$expected = 
'63.227.234.71:4628 -> 80 = '.$expect->{1007241067}.'
63.87.135.216:3204 -> 80 = '.$expect->{1007241123}.'
63.222.243.6:2710 -> 80 = '.$expect->{1007241125}.'
';
$response = '';
foreach(sort {$report{$a} <=> $report{$b}} keys %report) {
  $response .= "$_ = $report{$_}\n";
}
print "response\n$response
ne expected\n$expected\nnot "
	unless $response eq $expected;
&ok;

## test 9
# time to earliest, should zap all
%report = ();
$rv = find_old_threads(\%tarpit,\%report,0,$expect->{1007241067});

# should have 3 items
print "found $rv items, not 0\nnot "
	if $rv;
&ok;

## test 10
$expected = '';
$response = '';
foreach(sort {$report{$a} <=> $report{$b}} keys %report) {
  $response .= "$_ = $report{$_}\n";
}
print "response\n$response
ne expected\n$expected\nnot "
	unless $response eq $expected;
&ok;

