use warnings;
use strict;
use feature 'say';

use Data::Dumper;
use GPSD::Parse;

my $gps = GPSD::Parse->new;

my $raw;

while (1){
    $raw = $gps->poll;
    print "$raw->{tpv}\n";
    last if $raw->{tpv};
    sleep 1;
}

# print Dumper $gps->satellites;
# print Dumper $gps->sky;

# my $sat = $gps->satellites(16);

#say $gps->satellites(16, 'el');
#say $gps->tpv('speed');
#say $gps->time;
#say $gps->device;

print Dumper $raw;
