#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

my $uidswritten = {};  # keep a record of if we have written to a tag in current invocation
my $infoblock  = 2;    # the block we will write to / read from 
my $infostring = 'HiPi Block Test';

my $key = $rfid->get_default_key;  # change if you changed it

sub handle_read_write {
    my( $uid, $uidstring) = @_;
    
    print qq(Tag ID   : $uidstring\n);
    my $picctype = $rfid->picc_get_type( $uid->{'sak'} );
    my $piccname = $rfid->picc_get_type_name( $picctype );
    print qq(Tag Type : $piccname\n);
    
    my $continue = 1;
    
    if(exists($uidswritten->{$uidstring})) {
        # read the data from info block
        my ( $bdstatus, $blockdata )  = $rfid->read_block_data( $infoblock, $uid, $key );
        if( $bdstatus == MFRC522_STATUS_OK ) {
            my $stringdata = '';
            my $bldata = '';
            for my $byte ( @$blockdata ) {
                $bldata .= ' ' if $bldata;
                $bldata .= sprintf('%02X', $byte);
                $stringdata .= chr($byte) if $byte; # ignore 0x00 == NULL - this is text
            }
            print qq(READ BLOCK $infoblock DATA : $bldata\n);
            print qq(BLOCK $infoblock STRING : $stringdata\n\n);
            $continue = 1; # wait for next tag
            print qq(present next tag ...\n\n);
        } else {
            print $rfid->get_status_code_name( $bdstatus ) . qq(\n);
        }
    } else {
        # write the data to the block
        my $writestring = $infostring;
        my @chars = split(//, $writestring);
        my @writedata = ();
        for (my $i = 0; $i < 16; $i ++) {  # block is 16 bytes
            my $char = $chars[$i];
            if(defined($char)) {
                $writedata[$i] = ord($char);
            } else {
                $writedata[$i] = 0;
            }
        }
        
        my $bdstatus = $rfid->write_block_data( $infoblock, $uid, \@writedata, $key );
        print qq(WRITE BLOCK $infoblock DATA RESULT : ) . $rfid->get_status_code_name( $bdstatus ) . qq(\n\n);
        if( $bdstatus == MFRC522_STATUS_OK ) {
            $uidswritten->{$uidstring} = 1;
            print qq(re-present tag to read block ....\n\n);
        }
        $continue = 1;
    }
    # end session so we can start communicating with same tag or new tag
    $rfid->picc_end_session;
    return $continue;    
}

$rfid->scan( \&handle_read_write );

1;