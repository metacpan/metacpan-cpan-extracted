use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $fname = 't/data/gps.json';
my $m = 'GPSD::Parse';

{ # function

    my ($lat, $lon);

    ($lat, $lon) = $m->unsigned(1.234, 3.456);
    is $lat, '1.234N', "unsigned positive lat ok";
    is $lon, '3.456E', "unsigned positive lon ok";

    ($lat, $lon) = $m->unsigned(-1.234, -3.456);
    is $lat, '1.234S', "unsigned negative lat ok";
    is $lon, '3.456W', "unsigned negative lon ok";

    ($lat, $lon) = $m->unsigned(1.234, -3.456);
    is $lat, '1.234N', "unsigned positive lat ok";
    is $lon, '3.456W', "unsigned negative lon ok";

    ($lat, $lon) = $m->unsigned(-1.234, 3.456);
    is $lat, '1.234S', "unsigned negative lat ok";
    is $lon, '3.456E', "unsigned positive lon ok";
}

{ # test file (signed)

    my $gps = $m->new(file => $fname);
    $gps->poll;

    is $gps->tpv('lat'), 51.1111111, "signed lat ok";
    is $gps->tpv('lon'), -114.11111111, "signed lon ok";
}

{ # test file (unsigned)

    my $gps = $m->new(file => $fname, signed => 0);
    $gps->poll;

    is $gps->tpv('lat'), '51.1111111N', "signed lat ok";
    is $gps->tpv('lon'), '114.11111111W', "signed lon ok";
}

done_testing;
