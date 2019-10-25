use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $mod = 'GPSD::Parse';

my $fname = 't/data/gps.json';

my $gps;

my $sock = eval {
    $gps = $mod->new;
    1;
};

$gps = GPSD::Parse->new(file => $fname) if ! $sock;

{ # default return

    $gps->poll;

    my $t = $gps->device;

    is ref \$t, 'SCALAR', "device is returned as a string";
    like $t, qr|^/dev/tty|, "...and is ok";
}

done_testing;
