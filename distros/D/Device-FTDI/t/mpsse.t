#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use MockFTDI qw( is_write is_writeread );

use Device::FTDI::MPSSE qw(
    CLOCK_RISING CLOCK_FALLING
);

my $mpsse = Device::FTDI::MPSSE->new( ftdi => "MockFTDI" );
$MockFTDI::MPSSE = $mpsse;

isa_ok( $mpsse, "Device::FTDI::MPSSE", '$mpsse' );

$mpsse->set_clock_edges( CLOCK_RISING, CLOCK_FALLING );

# Initial setup
is_write
    "\x80\x00\x0B" . # CMD_SET_DBUS
    "\x82\x00\x00",  # CMD_SET_CBUS
    'write_data for initialisation';

# write_bytes
{
    my $f = $mpsse->write_bytes( "\x55\xAA" );

    is_write
        "\x11\x01\x00\x55\xAA", # CMD_WRITE|CMD_CLK_ON_WRITE len=2
        'write_data for write_bytes';

    is( scalar $f->get, undef, '$f->get' );
}

# read_bytes
{
    my $f = $mpsse->read_bytes( 2 );

    is_writeread
        "\x20\x01\x00" . # CMD_READ len=1
            "\x87",      # CMD_SEND_IMMEDIATE
        "\x5A\xA5",
        'write_data for read_bytes';

    is( scalar $f->get, "\x5A\xA5", '$f->get for read_bytes' );
}

# write_bits
{
    my $f = $mpsse->write_bits( 4, "\x5A" );

    is_write
        "\x13\x03\x5A", # CMD_WRITE|CMD_BITMODE|CMD_CLK_ON_WRITE len=4
        'write_data for write_bits';

    is( scalar $f->get, undef, '$f->get' );
}

# read_bits
{
    my $f = $mpsse->read_bits( 4 );

    is_writeread
        "\x22\x03" . # CMD_READ|CMD_BITMODE len=4
            "\x87",  # CMD_SEND_IMMEDIATE
        "\x05",
        'write_data for read_bits';

    is( scalar $f->get, "\x50", '$f->get for read_bits' );
}

done_testing;
