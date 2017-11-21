#!/usr/bin/perl 

print "1..$tests\n";

require Finance::YahooQuote;
print "ok 1\n";

import Finance::YahooQuote;
print "ok 2\n";

BEGIN{$tests = 2;}
exit(0);
