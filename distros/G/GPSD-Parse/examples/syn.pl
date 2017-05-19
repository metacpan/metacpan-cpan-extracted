use warnings;
use strict;
use feature 'say';

use GPSD::Parse;

my $fname = 't/data/gps.json';

my $gps = GPSD::Parse->new(file => $fname, signed => 0);

$gps->poll;

my $lat = $gps->tpv('lat');
my $lon = $gps->tpv('lon');

my $heading = $gps->tpv('track');
my $direction = $gps->direction($heading);

my $altitude = $gps->tpv('alt');

my $speed = $gps->tpv('speed');

say "latitude:  $lat";
say "longitude: $lon\n";

say "heading:   $heading degrees";
say "direction: $direction\n";

say "altitude:  $altitude metres\n";

say "speed:     $speed metres/sec";

__END__

latitude:  51.1111111N
longitude: 114.11111111W

heading:   31.23 degrees
direction: NNE

altitude:  1080.9 metres

speed:     0.333 metres/sec

