use strict;
use warnings;

use GPSD::Parse;
use Test::More;

my $mod = 'GPSD::Parse';

my $gps;

eval {
    $gps = $mod->new;
};

plan skip_all => "no socket available" if $@;

$gps->on;

{ # default return

    $gps->poll;

    my $t = $gps->device;

    is ref \$t, 'SCALAR', "device is returned as a string";
    like $t, qr|^/dev/ttyS0$|, "...and is ok"; 
}

$gps->off;

done_testing;
