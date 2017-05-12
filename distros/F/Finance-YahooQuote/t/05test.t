#!/usr/bin/perl

print "1..$tests\n";

use Finance::YahooQuote;
$Finance::YahooQuote::TIMEOUT = 60;

use Data::Dumper;

$arrptr = getcustomquote(["IBM","DELL"], ["Name","PEG Ratio","Book Value"]);
print Dumper($arrptr);
@array = @{$arrptr->[0]};
print "ok 1\n" if scalar(@array) == 3;

BEGIN{$tests = 1;}
exit(0);
