use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $fname = 't/data/gps.json';
my $m = 'GPSD::Parse';

{ # test file (signed)

    my $gps = $m->new(file => $fname);
    $gps->poll;

    is $gps->tpv('lat'), 51.1111111, "signed lat ok";
    is $gps->tpv('lon'), -114.11111111, "signed lon ok";

    $gps->unsigned;
    $gps->poll;

    is $gps->tpv('lat'), '51.1111111N', "unsigned() lat ok";
    is $gps->tpv('lon'), '114.11111111W', "unsigned() lon ok";

    $gps->signed;
    $gps->poll;

    is $gps->tpv('lat'), 51.1111111, "signed() lat ok";
    is $gps->tpv('lon'), -114.11111111, "signed() lon ok";

}

done_testing;
