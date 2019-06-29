#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

# some clone cards allow a simple write to block 0
# and don't require the 'backdoor' method
# see examples/write_uid_block.pl

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

my $key = $rfid->get_default_key;  # change if you changed it

my $uidswritten = {};  # keep a record of if we have written to a tag in current invocation

my $newuid = [ 0x23, 0xCF, 0xC9, 0x3C ]; # uid should be the same size as the one it is replacing

my $uidsize = scalar( @$newuid );

my $newuidstring = '';
for (my $i = 0; $i < $uidsize; $i ++ ) {
    $newuidstring .= '-' if $newuidstring;
    $newuidstring .= sprintf('%02X', $newuid->[$i]);
}

sub handle_change_uid {
    my( $uid, $uidstring) = @_;
    
    print qq(Tag ID   : $uidstring\n);
    my $picctype = $rfid->picc_get_type( $uid->{'sak'} );
    my $piccname = $rfid->picc_get_type_name( $picctype );
    print qq(Tag Type : $piccname\n);
    
    my $continue = 1;
    
    unless( $uidsize == $uid->{'size'} ) {
        print qq(new uid is $uidsize bytes but existing uid is $uid->{'size'} bytes\n\n);
        $rfid->picc_end_session;
        return $continue;
    }
    
    if( $newuidstring eq $uidstring ) {
        print qq(Tag already has UID $newuidstring\n);
        my ( $uidstatus, $uidblockdata ) = $rfid->read_block_data( 0, $uid, $key );
        if( $uidstatus == MFRC522_STATUS_OK ) {
            my $bldata = '';
            for my $byte ( @$uidblockdata ) {
                $bldata .= ' ' if $bldata;
                $bldata .= sprintf('%02X', $byte);
            }
            print qq(Tag Block 0 : $bldata\n\n);
        } else {
            print qq(\n);
        }
        $rfid->picc_end_session;
        return $continue;
    }
    
    if( $rfid->mifare_set_uid( $uid, $newuid, $key ) ) {
        print qq(Tag UID set to $newuidstring\n\n);
        
    } else {
        print qq(Failed to set UID for tag $uidstring\n\n);
    }
    
    $rfid->picc_end_session;
    
    return $continue;    
}

$rfid->scan( \&handle_change_uid );

1;