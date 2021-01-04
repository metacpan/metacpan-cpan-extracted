#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw( sleep );
use Getopt::Long;

use Future::AsyncAwait 0.47;

use Device::Chip::Adapter;

GetOptions(
   'adapter|A=s' => \( my $ADAPTER ),
) or exit 1;

my $adapter = Device::Chip::Adapter->new_from_description( $ADAPTER );
my $proto = await $adapter->make_protocol( "GPIO" );

my @gpios = $proto->list_gpios;

while(1) {
    my $gpios = await $proto->read_gpios( [@gpios] );
    print "Read " .
        join( " ", map { "$_=" . ( $gpios->{$_} // "0" ) } sort keys %$gpios ) .
        "\n";

    sleep 0.5;
}

sleep 0.5;
