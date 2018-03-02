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

my @stats = qw(
   lon
   lat
   alt
   climb
   speed
   track
);

$gps->poll;

{ # all methods

    for (@stats){
#        print $gps->$_ . "\n";
        is defined $gps->$_, 1, "$_ method is available";
    }

    if (! $sock) {
        is $gps->lon, '-114.11111111', "lon() has proper output";
        is $gps->lat, '51.1111111', "lat() has proper output";
        is $gps->alt, '1080.9', "alt() has proper output";
        is $gps->climb, '2.111', "climb() has proper output";
        is $gps->speed, '0.333', "speed() has proper output";
        is $gps->track, '31.23', "track() has proper output";
    }
}

done_testing;
