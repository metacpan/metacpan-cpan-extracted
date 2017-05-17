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

    my $t = $gps->time;

    is ref \$t, 'SCALAR', "time is returned as a string";
    like $t, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/, "...and is ok"; 
}

$gps->off;

done_testing;
