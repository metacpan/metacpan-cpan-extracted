#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;

use lib 't/lib';
use MockFTDI qw( is_write is_writeread );

use Device::FTDI::SPI;

my $spi = Device::FTDI::SPI->new( ftdi => "MockFTDI" );
$MockFTDI::MPSSE = $spi;

isa_ok( $spi, "Device::FTDI::SPI", '$spi' );

$spi->set_clock_rate( 1E6 );
$spi->set_spi_mode( 0 );

is_write
    "\x80\x00\x0B" .     # CMD_SET_DBUS
        "\x82\x00\x00" . # CMD_SET_CBUS
        "\x9E\x00\x00" . # CMD_SET_OPEN_COLLECTOR
        "\x80\x08\x0B" . # CMD_SET_DBUS release SS
        "\x8B" .         # CMD_CLKDIV5_ON
        "\x86\x05\x00" . # CMD_SET_CLOCK_DIVISOR
        "\x80\x08\x0B",  # CMD_SET_DBUS release SS, CLK idle
    'write_data for initialisation';

# write
{
    my $f = $spi->write( "\x55\xAA" );

    is_write
        "\x80\x00\x0B" .             # CMD_SET_DBUS assert SS
            "\x11\x01\x00\x55\xAA" . # CMD_WRITE|CMD_CLK_ON_WRITE len=2
            "\x80\x08\x0B",          # CMD_SET_DBUS release SS
        'write_data for write';

    is( scalar $f->get, undef, '$f->get' );
}

# read
{
    my $f = $spi->read( 2 );

    is_writeread
        "\x80\x00\x0B" .     # CMD_SET_DBUS assert SS
            "\x20\x01\x00" . # CMD_READ len=2
            "\x80\x08\x0B" . # CMD_SET_DBUS release SS
            "\x87",          # CMD_SEND_IMMEDIATE
        "\x5A\xA5",
        'write_data for read';

    is( scalar $f->get, "\x5A\xA5", '$f->get for read' );
}

# readwrite
{
    my $f = $spi->readwrite( "\xAA\x55" );

    is_writeread
        "\x80\x00\x0B" .             # CMD_SET_DBUS assert SS
            "\x31\x01\x00\xAA\x55" . # CMD_WRITE|CMD_READ|CMD_CLK_ON_WRITE len=2
            "\x80\x08\x0B" .         # CMD_SET_DBUS release SS
            "\x87",                  # CMD_SEND_IMMEDIATE
        "\xA5\x5A",
        'write_data for readwrite';

    is( scalar $f->get, "\xA5\x5A", '$f->get for readwrite' );
}

# readwrite without SS
{
    my $f = $spi->readwrite( "\xAA\x55", "NO_SS" );

    is_writeread
        "\x31\x01\x00\xAA\x55" . # CMD_WRITE|CMD_READ|CMD_CLK_ON_WRITE len=2
            "\x87",              # CMD_SEND_IMMEDIATE
        "\xA5\x5A",
        'write_data for readwrite with NO_SS';

    is( scalar $f->get, "\xA5\x5A", '$f->get for readwrite with NO_SS' );
}

# write/read at wordsize=7
{
    $spi->set_wordsize( 7 );

    $spi->write( "\x3A\x4F" );

    # at 7bits: 3A 1F => 0111010 1001111
    # at 8bits: 01110101 001111(00) => 75 3C

    is_write
        "\x80\x00\x0B" .             # CMD_SET_DBUS assert SS
            "\x11\x00\x00\x75" .     # CMD_WRITE|CMD_CLK_ON_WRITE len=1
            "\x13\x05\x3C" .         # CMD_WRITE|CMD_CLK_ON_WRITE|CMD_BITMODE len=6
            "\x80\x08\x0B",          # CMD_SET_DBUS release SS
        'write_data for write at wordsize=7';

    my $f = $spi->read( 2 );

    # reads back as 8bits: 01110101 (00)001111 => 75 0F

    is_writeread
        "\x80\x00\x0B" .     # CMD_SET_DBUS assert SS
            "\x20\x00\x00" . # CMD_READ len=1
            "\x22\x05" .     # CMD_READ|CMD_BITMODE len=6
            "\x80\x08\x0B" . # CMD_SET_DBUS release SS
            "\x87",          # CMD_SEND_IMMEDIATE
        "\x75\x0F",
        'write_data for read at wordsize=7';

    is_hexstr( scalar $f->get, "\x3A\x4F", '$f->get for read at wordsize=7' );
}

# write/read at wordsize=9
{
    $spi->set_wordsize( 9 );

    $spi->write( "\xE9\x{172}" );

    # at 9bits: E9 172 => 011101001 101110010
    # at 8bits: 01110100 11011100 10(00000000) => 74 DC 80

    is_write
        "\x80\x00\x0B" .             # CMD_SET_DBUS assert SS
            "\x11\x01\x00\x74\xDC" . # CMD_WRITE|CMD_CLK_ON_WRITE len=2
            "\x13\x01\x80" .         # CMD_WRITE|CMD_CLK_ON_WRITE|CMD_BITMODE len=2
            "\x80\x08\x0B",          # CMD_SET_DBUS release SS
        'write_data for write at wordsize=9';

    my $f = $spi->read( 2 );

    # reads back as 8bits: 01110100 11011100 (000000)10 => 74 DC 02

    is_writeread
        "\x80\x00\x0B" .     # CMD_SET_DBUS assert SS
            "\x20\x01\x00" . # CMD_READ len=2
            "\x22\x01" .     # CMD_READ|CMD_BITMODE len=2
            "\x80\x08\x0B" . # CMD_SET_DBUS release SS
            "\x87",          # CMD_SEND_IMMEDIATE
        "\x74\xDC\x02",
        'write_data for read at wordsize=9';

    is_hexstr( scalar $f->get, "\xE9\x{172}", '$f->get for read at wordsize=9' );
}

# write/read at wordsize=16
{
    $spi->set_wordsize( 16 );

    $spi->write( "\x{1234}\x{5678}" );

    is_write
        "\x80\x00\x0B" .                     # CMD_SET_DBUS assert SS
            "\x11\x03\x00\x12\x34\x56\x78" . # CMD_WRITE|CMD_CLK_ON_WRITE len=4
            "\x80\x08\x0B",                  # CMD_SET_DBUS release SS
        'write_data for write at wordsize=16';

    my $f = $spi->read( 2 );

    is_writeread
        "\x80\x00\x0B" .     # CMD_SET_DBUS assert SS
            "\x20\x03\x00" . # CMD_READ len=4
            "\x80\x08\x0B" . # CMD_SET_DBUS release SS
            "\x87",          # CMD_SEND_IMMEDIATE
        "\x12\x34\x56\x78",
        'write_data for read at wordsize=16';

    is_hexstr( scalar $f->get, "\x{1234}\x{5678}", '$f->get for read at wordsize=16' );
}

# write/read at wordsize=7 LSB
{
    $spi->set_wordsize( 7 );
    $spi->set_bit_order( Device::FTDI::MPSSE::LSBFIRST );

    $spi->write( "\x3A\x4F" );

    # at 7bits: 3A 1F => 0111010 1001111
    # at 8bits: 10111010 (00)100111 => BA 27

    is_write
        "\x80\x00\x0B" .             # CMD_SET_DBUS assert SS
            "\x19\x00\x00\xBA" .     # CMD_WRITE|CMD_CLK_ON_WRITE|CMD_LSBFIRST len=1
            "\x1b\x05\x27" .         # CMD_WRITE|CMD_CLK_ON_WRITE|CMD_LSBFIRST CMD_BITMODE len=6
            "\x80\x08\x0B",          # CMD_SET_DBUS release SS
        'write_data for write at wordsize=7';

    my $f = $spi->read( 2 );

    # reads back as 8bits: 10111010 100111(00) => BA 9C

    is_writeread
        "\x80\x00\x0B" .     # CMD_SET_DBUS assert SS
            "\x28\x00\x00" . # CMD_READ|CMD_LSBFIRST len=1
            "\x2A\x05" .     # CMD_READ|CMD_LSBFIRST|CMD_BITMODE len=6
            "\x80\x08\x0B" . # CMD_SET_DBUS release SS
            "\x87",          # CMD_SEND_IMMEDIATE
        "\xBA\x9C",
        'write_data for read at wordsize=7';

    is_hexstr( scalar $f->get, "\x3A\x4F", '$f->get for read at wordsize=7' );
}

done_testing;
