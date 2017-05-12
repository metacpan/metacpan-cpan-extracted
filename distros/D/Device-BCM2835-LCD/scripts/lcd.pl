#!/usr/bin/perl
#
# Simple LCD demonstration script
#
# Usage: lcd.pl "text to display"
# or    lcd.pl -p row,column "text to display"

use Device::BCM2835::LCD;

my $msg = "Hello world";	

# Initialise our LCD object 
my $lcd = Device::BCM2835::LCD->new();
$lcd->init( Display => 2004, RPI_PIN => V2 );


if ( $ARGV[0] ) {
    if ( $ARGV[0] eq '-p' ) {
        my ( $row, $col ) = split /,/, $ARGV[1];
        $lcd->SetPos( $row, $col );
        $msg = $ARGV[2];
    }
    else {
        $msg = $ARGV[0];
    }
}
$lcd->PutMsg($msg);

