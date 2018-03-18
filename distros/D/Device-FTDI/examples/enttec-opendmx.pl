#!/usr/bin/perl

use strict;
use warnings;

use Device::FTDI qw( :bits :stop :parity :flow :break );
use Time::HiRes qw( sleep );

# Default VID/PID should be fine
my $dmx = Device::FTDI->new();

# Initialise
$dmx->reset;

$dmx->set_baudrate( 250_000 );

$dmx->set_line_property( BITS_8, STOP_BIT_2, PARITY_NONE );

$dmx->set_flow_control( FLOW_DISABLE );

$dmx->purge_tx_buffer;
$dmx->purge_rx_buffer;

my @channels = ( 0 ) x 512;

sub writedmx
{
    $dmx->set_line_property( BITS_8, STOP_BIT_2, PARITY_NONE, BREAK_ON );
    $dmx->set_line_property( BITS_8, STOP_BIT_2, PARITY_NONE, BREAK_OFF );
    $dmx->write_data( pack "C C512", 0, @channels );
}

foreach my $val ( 0 .. 255 ) {
    $channels[0] = $val;
    writedmx();

    sleep 0.05;  # 20Hz
}
