
# $Id: test.pl,v 1.3 1999/02/07 04:27:55 msolomon Exp $

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Geo::WeatherNOAA;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $test2 = process_city_zone('boston','ma','','get');
print 'not ' unless $test2;
print "ok 2\n";

my $test3 = make_noaa_table('boston','ma','test_wx','save');
unlink "test_wx_zone";
unlink "test_wx_hourly";
print "not " unless $test3;
print "ok 3";

print "\n";
