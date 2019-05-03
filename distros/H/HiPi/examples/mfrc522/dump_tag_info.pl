#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

sub handle_scan {
    my $continue = 1;
    my( $uid, $uidstring) = @_;
    my $output = $rfid->picc_dump_details( $uid );
    print $output . qq(\n);
    $rfid->picc_end_session;
    return $continue;
}

sub handle_timeout {
    #warn q(timeout called);
    return 1;
}

$rfid->scan( \&handle_scan, \&handle_timeout, 10 );


1;