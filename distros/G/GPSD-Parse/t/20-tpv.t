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

my @stats = qw(
   time
   lon
   lat
   alt
   climb
   speed
   track
   device
   mode
   epx
   epy
   epc
   ept
   epv
   eps
   class
   tag
);

$gps->poll;

{ # default, no param 

    my $t = $gps->tpv;

    is ref $t, 'HASH', "tpv() returns a hash ref ok";

    is keys %$t, @stats, "tpv() key count matches number of stats";

    for (@stats){
        is exists $t->{$_}, 1, "$_ stat exists in return";
    }

    for (qw(lat lon)){
        like $t->{$_}, qr/^-?\d+\.\d{4,9}$/, "$_ is in proper format";
    }
}

{ # stat param

    for (@stats){
        is ref \$gps->tpv($_), 'SCALAR', "$_ stat param ok";
    }

    is $gps->tpv('invalid'), undef, "unknown stat param returns undef";
}

$gps->off;

done_testing;
