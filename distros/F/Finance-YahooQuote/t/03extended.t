#!/usr/bin/perl 

print "1..$tests\n";

use Finance::YahooQuote;
$Finance::YahooQuote::TIMEOUT = 60;

useExtendedQueryFormat();
$arrptr = getquote("IBM");
@array = @{$arrptr->[0]};
print "ok 1\n" if scalar(@array) == 36;

useRealtimeQueryFormat();
$arrptr = getquote("IBM");
@array = @{$arrptr->[0]};
print "ok 2\n" if scalar(@array) == 43;

BEGIN{$tests = 2;}
exit(0);
