#!/usr/bin/perl

print "1..$tests\n";

use Finance::YahooQuote;
$Finance::YahooQuote::TIMEOUT = 60;

@symbols = ("IBM","DELL");
@columns = ("Name","PEG Ratio","Book Value");

$arrptr = getcustomquote(\@symbols, \@columns);
@array = @{$arrptr->[0]};
print "ok 1\n" if scalar(@array) == 3;

BEGIN{$tests = 1;}
exit(0);
