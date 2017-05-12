#!/usr/bin/perl
#
#

use Device::Quasar3108;
use strict;
use Time::HiRes qw( sleep );



my $io = new Device::Quasar3108( '/dev/ttyS0' );

$io->ping() or die "Module isn't there.";


my $version = $io->firmware_version();
print "Firmware Version: $version\n";




# Turn all relays off
$io->relay_set( 0 );
sleep( 1 );


$io->relay_flash( 1 );
sleep( 1 );
$io->relay_flash( 2 );
sleep( 1 );
$io->relay_flash( 3 );
sleep( 1 );
$io->relay_flash( 4 );
sleep( 1 );


$io->relay_on( 7 );
print "relay status: ".$io->relay_status()."\n";
$io->relay_off( 7 );


print "input status: ".$io->input_status()."\n";
