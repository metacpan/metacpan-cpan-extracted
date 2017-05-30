use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $fname = 't/data/gps.json';

{ # metric (default setting)

    my $gps = GPSD::Parse->new(file => $fname);

    $gps->poll;

    is $gps->tpv('alt'), 1080.9, "metric alt ok";
    is $gps->tpv('climb'), 2.111, "metric climb ok";
    is $gps->tpv('speed'), 0.333, "metric speed ok";
}

{ # imperial

    my $gps = GPSD::Parse->new(file => $fname, metric => 0);
    $gps->poll;

    is $gps->tpv('alt'), 3546.259, "feet alt ok";
    is $gps->tpv('climb'), 6.925, "feet climb ok";
    is $gps->tpv('speed'), 1.092, "feet speed ok";
}

done_testing;
