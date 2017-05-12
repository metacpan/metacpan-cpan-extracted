#! /usr/local/bin/perl

use blib;
use MP3::Player::PktConcert;

my $ipc = new MP3::Player::PktConcert;

$ipc->mount or die "Can't mount";
$ipc->open or die "Can't open";
$ipc->send( "The Kinks - Come Dancing" );
my ($free, $total) = $ipc->usage;
print "\n$free bytes out of $total remaining.\n";
$ipc->delete( "The Kinks - Come Dancing" );
$ipc->close;

