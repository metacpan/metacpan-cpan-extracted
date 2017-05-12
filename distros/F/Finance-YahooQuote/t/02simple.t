#!/usr/bin/perl 

print "1..$tests\n";

use Finance::YahooQuote;
$Finance::YahooQuote::TIMEOUT = 60;

@quote = getonequote "IBM";

print "ok 1\n" if $quote[1] eq "INTL BUS MACHINE" 
    or $quote[1] eq "INTL BUSINESS MAC"
    or $quote[1] eq "International Bus"
    or $quote[1] eq "International Business Machines";

$arrptr = getquote("IBM");
@array = @{$arrptr->[0]};
print "ok 2\n" if scalar(@array) == 22;

BEGIN{$tests = 2;}
exit(0);
