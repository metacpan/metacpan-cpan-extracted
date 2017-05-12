#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Device::Router::RTX;
my $rtx = Device::Router::RTX->new (address => '12.34.56.78',);
my $arp = $rtx->arp();
if ($arp) {
    for my $entry (@$arp) {
	print "MAC: $entry->{mac} IP: $entry->{ip}.\n";
    } 
} 
