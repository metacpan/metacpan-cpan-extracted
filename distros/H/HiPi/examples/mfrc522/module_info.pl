#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

my $versionstring = $rfid->get_firmware_version_string;
print qq(Module Version : $versionstring\n);

if( $rfid->self_test_ok ) {
    print qq(Self Test Result : SUCCESS\n);
} else {
    print qq(Self Test Result : FAILED\n);
}

# after self test we have to re init
$rfid->init;

1;