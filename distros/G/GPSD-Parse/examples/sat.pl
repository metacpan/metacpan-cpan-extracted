use warnings;
use strict;

use GPSD::Parse;

my $gps = GPSD::Parse->new;

while (1){
    $gps->poll;
    my $sats = $gps->satellites;

    for my $sat (keys %$sats){
        if (! $gps->satellites($sat, 'used')){
            print "$sat: unused\n";
        }
        else {
            print "$sat: used\n";
            for (keys %{ $sats->{$sat} }){
                print "\t$_: $sats->{$sat}{$_}\n";
            }
        }
    }
    sleep 3;
}
