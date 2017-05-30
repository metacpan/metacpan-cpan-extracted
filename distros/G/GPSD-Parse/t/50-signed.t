use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $fname = 't/data/gps.json';
my $m = 'GPSD::Parse';

{ # function

    my ($lat, $lon);

    ($lat, $lon) = $m->signed(qw(1.234N 3.456E));
    is $lat, '1.234', "unsigned positive lat ok";
    is $lon, '3.456', "unsigned positive lon ok";

    ($lat, $lon) = $m->signed(qw(1.234S 3.456W));
    is $lat, '-1.234', "unsigned negative lat ok";
    is $lon, '-3.456', "unsigned negative lon ok";

    ($lat, $lon) = $m->signed(qw(1.234N 3.456W));
    is $lat, '1.234', "unsigned positive lat ok";
    is $lon, '-3.456', "unsigned negative lon ok";

    ($lat, $lon) = $m->signed(qw(1.234S 3.456E));
    is $lat, '-1.234', "unsigned negative lat ok";
    is $lon, '3.456', "unsigned positive lon ok";
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
