#!/usr/bin/perl

use 5.026;
use utf8;
use strict;
use warnings;

use Device::Yeelight;

my $yeelight = Device::Yeelight->new;
foreach my $device ( @{ $yeelight->search } ) {
    my $power = %{ $device->get_prop(qw/power/) }{power};
    say "Device $device->{name} is currently " . $power;
    if ( $power eq 'on' ) {
        my %props = %{ $device->get_prop(qw/bright ct/) };
        say "Brightness: $props{bright}";
        say "Color temperature: $props{ct}";
    }
}
