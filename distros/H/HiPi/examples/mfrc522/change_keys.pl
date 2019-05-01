#!/usr/bin/perl
use strict;
use warnings;
use HiPi qw( :rpi :mfrc522);
use HiPi::Interface::MFRC522;

my $resetpin = RPI_PIN_38; # the pin connected to reset

my $rfid = HiPi::Interface::MFRC522->new( reset_pin => $resetpin, devicename => '/dev/spidev0.1' );

my $reverse = 0;  # change $reverse to 1 to switch back a tag to defaults
                  # ( the current key must be the one in $replaceA below, of course);

my $defaultkey = $rfid->get_default_key;
my $replaceA   = [ 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6 ]; # New Key A
my $replaceB   = [ 0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6 ]; # New Key B

my $blockswritten = {};

$rfid->scan( \&handle_scan );

sub handle_scan {
    my $continue = 1;
    my( $uid, $uidstring) = @_;
    print qq(Tag UID: $uidstring\n);
    
    # record which blocks we wrote successfully so
    # that we can retry other blocks without failing
    # authentication.
    # This only lasts while the script is running 
    
    if(!exists($blockswritten->{$uidstring})) {
        $blockswritten->{$uidstring} = {};
    }
    
    # These are the default existing access bits.
    # We won't pass this value and existing bits will remain
    
    my $accessbits = [
        0b000, 0b000, 0b000, 0b001
    ];
    
    # General Purpose Bit. We won't pass this value and all existing
    # values will remain
    my $gpb = 0x69;
    
    my $key  = ( $reverse ) ? $replaceA : $defaultkey;
    my $newkeyA = ( $reverse ) ? $defaultkey : $replaceA;
    my $newkeyB = ( $reverse ) ? $defaultkey : $replaceB;
    
    my $picctype = $rfid->picc_get_type( $uid->{'sak'} );
    my $blocks   = $rfid->get_sector_trailer_blocks( $picctype );
    
    my $success = 1;
    
    for my $block( sort { $a <=> $b } ( keys %$blocks ) ) {
        if($blockswritten->{$uidstring}->{$block}) {
            print qq(skipping written block $block\n);
            next;
        }
        my $status = $rfid->write_sector_trailer( $block, $key, $uid, $newkeyA, $newkeyB, undef, undef  );
        if( $status == MFRC522_STATUS_OK ) {
            $blockswritten->{$uidstring}->{$block} = 1;
        } else {
            $success = 0;
        }
        
        print qq(result sector trailer write $block : ) . $rfid->get_status_code_name( $status ) . qq(\n);
        # now read back in
        my( $rstatus, $rdata ) = $rfid->read_block_data( $block, $uid, $newkeyA );
        if( $rstatus == MFRC522_STATUS_OK ) {
            printf(qq(result sector trailer read  %03d  %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X\n), $block, @$rdata );
        } else {
            print  qq(result sector trailer read  $block : ) . $rfid->get_status_code_name( $rstatus ) . qq(\n);
        }
        
        $rfid->sleep_milliseconds(1);
    }

    if( $success ) {
        my $setype = ( $reverse ) ? 'Default' : 'New Custom';
        print qq(Tag Access Set to $setype Key On All Sectors\n);
    } else {
        print qq(Failed - 1 or more sector trailers were not written. Re-present tag / card\n);
    }
    
    $rfid->picc_end_session;
    return $continue;
}


1;