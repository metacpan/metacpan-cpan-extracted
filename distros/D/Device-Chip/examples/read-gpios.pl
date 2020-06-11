#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw( sleep );
use Getopt::Long;

use Device::Chip::Adapter;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
) or exit 1;

my $adapter = Device::Chip::Adapter->new_from_description( $ADAPTER );
my $proto = $adapter->make_protocol( "GPIO" )->get;

my @gpios = $proto->list_gpios;

while(1) {
    my $gpios = $proto->read_gpios( [@gpios] )->get;
    print "Read " .
        join( " ", map { "$_=" . ( $gpios->{$_} // "0" ) } sort keys %$gpios ) .
        "\n";

    sleep 0.5;
}

sleep 0.5;
