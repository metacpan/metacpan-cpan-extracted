#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

# some clone cards allow a simple write to block 0
# see also examples/change_uid.pl

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

# 69 BC 2D 6A
my $newuid = [ 0xAA, 0xAB, 0xDC, 0x1D ];  # uid should be the same size as the one it is replacing
my $uidsize = scalar( @$newuid );

my $key = $rfid->get_default_key;  # change if you changed it

my $newuidstring = '';
for (my $i = 0; $i < $uidsize; $i ++ ) {
    $newuidstring .= '-' if $newuidstring;
    $newuidstring .= sprintf('%02X', $newuid->[$i]);
}

sub handle_write_uid_block {
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
        print qq(Tag already has UID $newuidstring\n\n);
        $rfid->picc_end_session;
        return $continue;
    }
    
    my ( $bdstatus, $blockdata )  = $rfid->read_block_data( 0, $uid, $key );
    if( $bdstatus == MFRC522_STATUS_OK ) {
        my @writedata = @$blockdata;
        my $uidsize = scalar @$newuid;
        my $bcc = 0;
        for ( my $i = 0; $i < $uidsize; $i++ ) {
            $writedata[$i] = $newuid->[$i];
            $bcc ^= $newuid->[$i];
        }
        $writedata[$uidsize] = $bcc;
        
        my $writestatus = $rfid->write_uid_block( $uid, \@writedata, $key );
        
        if( $writestatus == MFRC522_STATUS_OK ) {
            print qq(Tag set to UID $newuidstring\n\n);
        } else {
            print qq(Failed to set UID for tag $uidstring : ) . $rfid->get_status_code_name( $writestatus ) . qq(\n);
        }
        
    } else {
        print $rfid->get_status_code_name( $bdstatus ) . qq(\n);
    }
    
    $rfid->picc_end_session;
    
    return $continue;    
}

$rfid->scan( \&handle_write_uid_block );

1;