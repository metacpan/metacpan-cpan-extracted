use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use GPSD::Parse;

my $want = $ARGV[0];

my $gps = GPSD::Parse->new;

my $raw = $gps->poll(return => $want);

# print Dumper $gps->satellites;
# print Dumper $gps->sky;

# my $sat = $gps->satellites(16);

#say $gps->satellites(16, 'el');
#say $gps->tpv('speed');
#say $gps->time;
#say $gps->device;

print Dumper $raw;
