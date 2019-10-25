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
$ENV{GPSD_LIVE_TESTING} = 1 if $sock;

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

    if ($ENV{GPSD_LIVE_TESTING}){
        note "GPSD_LIVE_TESTING env var not set\n";
        is keys %$t, @stats -2, "tpv() key count matches number of stats";
    }
    else {
        is keys %$t, @stats, "tpv() key count matches number of stats";
    }

    for (@stats){
        if ($ENV{GPSD_LIVE_TESTING}){
            next if $_ eq 'epc';
            next if $_ eq 'tag';
        }
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

    is $gps->tpv('invalid'), '', "unknown stat param returns empty string";
}

done_testing;
