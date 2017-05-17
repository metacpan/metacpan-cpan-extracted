use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok( 'GPSD::Parse' ) || print "Bail out!\n";
}

my $gps;

eval {
    $gps = GPSD::Parse->new;
};

SKIP: {
    skip "no socket available", 1 if $@;
    isa_ok $gps, 'GPSD::Parse', "obj is of appropriate class"
}

done_testing;
