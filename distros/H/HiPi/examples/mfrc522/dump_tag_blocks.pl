#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

$rfid->scan( \&handle_scan );

sub handle_scan {
    my $continue = 1;
    my( $uid, $uidstring) = @_;
    print qq(\nReading Tag UID $uidstring Blocks\n);
    print qq(   do not remove tag from field ....\n);
    my $output = $rfid->picc_dump_tag_info( $uid );
    print $output;
    # set the card inactive
    $rfid->picc_end_session;
    print qq(\nTag $uidstring read complete\n\n);
    return $continue;
}


1;