#!/usr/bin/perl

use Device::Modem;
use Device::Modem::Protocol::Xmodem;

my $port = $ARGV[0] || '/dev/pts/1';

my $mdm = Device::Modem->new( port => $port );
$mdm->connect( baudrate => 9600 ) or die "Can't connect to port $port";

print "Ok, connected. Press a key to begin transfer...";
<STDIN>;

my $recv = Xmodem::Receiver->new( modem => $mdm );
die "Receiver object undef!" if ! $recv;
$recv->run() or die "Cannot receive!";

