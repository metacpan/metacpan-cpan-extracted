use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $fname = 't/data/gps.json';

{ # default
    my $gps = GPSD::Parse->new(file => $fname);

    $gps->poll;

    is $gps->tpv('alt'), 1080.9, "default alt ok";
    is $gps->tpv('climb'), 2.111, "default climb ok";
    is $gps->tpv('speed'), 0.333, "default speed ok";

    $gps->feet;
    $gps->poll;

    is $gps->tpv('alt'), 3546.259, "feet alt ok";
    is $gps->tpv('climb'), 6.925, "feet climb ok";
    is $gps->tpv('speed'), 1.092, "feet speed ok";

    $gps->metres;
    $gps->poll;

    is $gps->tpv('alt'), 1080.9, "metres alt ok";
    is $gps->tpv('climb'), 2.111, "metres climb ok";
    is $gps->tpv('speed'), 0.333, "metres speed ok";

    $gps->feet;
    $gps->poll;

    is $gps->tpv('alt'), 3546.259, "feet alt ok";
    is $gps->tpv('climb'), 6.925, "feet climb ok";
    is $gps->tpv('speed'), 1.092, "feet speed ok";

    $gps->metres;
    $gps->poll;

    is $gps->tpv('alt'), 1080.9, "metres alt ok";
    is $gps->tpv('climb'), 2.111, "metres climb ok";
    is $gps->tpv('speed'), 0.333, "metres speed ok";
}

{ # non-default
    my $gps = GPSD::Parse->new(file => $fname, metric => 0);

    $gps->poll;

    is $gps->tpv('alt'), 3546.259, "feet alt ok";
    is $gps->tpv('climb'), 6.925, "feet climb ok";
    is $gps->tpv('speed'), 1.092, "feet speed ok";

    $gps->metres;
    $gps->poll;

    is $gps->tpv('alt'), 1080.9, "metres alt ok";
    is $gps->tpv('climb'), 2.111, "metres climb ok";
    is $gps->tpv('speed'), 0.333, "metres speed ok";

    $gps->feet;
    $gps->poll;

    is $gps->tpv('alt'), 3546.259, "feet alt ok";
    is $gps->tpv('climb'), 6.925, "feet climb ok";
    is $gps->tpv('speed'), 1.092, "feet speed ok";

    $gps->metres;
    $gps->poll;

    is $gps->tpv('alt'), 1080.9, "metres alt ok";
    is $gps->tpv('climb'), 2.111, "metres climb ok";
    is $gps->tpv('speed'), 0.333, "metres speed ok";
}
done_testing;
