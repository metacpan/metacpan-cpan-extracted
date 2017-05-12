#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# This test runs tests for the bootloader connecting over TCP

use strict;

use Test::More;
use Test::Requires qw/Test::SharedFork/;
use Test::SharedFork;
use IO::Select;
use IO::Socket::INET;

BEGIN { use_ok('Device::Microchip::Bootloader'); }

my $debug_mult = 10
    ; # Set this to a big number for longer timeouts when interactively debugging.

my $tcp = IO::Socket::INET->new(
    Listen    => 5,
    Proto     => 'tcp',
    LocalAddr => '127.0.0.1',
    LocalPort => 0
) or plan skip_all => "Failed to open TCP server on loopback address: $!";
my $tcp_port = $tcp->sockport;

my $pid = fork();

# Make a TCP test server in a spearate thread and connect to it with the bootloader from the parent thread
if ( $pid == 0 ) {

    # child
    my $sel = IO::Select->new($tcp);
    $sel->can_read( 10 * $debug_mult ) or die;
    my $client = $tcp->accept;
    ok $client, 'client accepted';
    $sel = IO::Select->new($client);
    $sel->can_read( 10 * $debug_mult ) or die;
    my ($buf, $bytes, $resp);

	# Handle autobaud character
	#$bytes = sysread $client, $buf, 2048;
    #is $bytes, 1, 'autobaud character';
    #is $buf, "\x0F", "Got autobaud traingin character";
    #$resp = "\x0F";
    #syswrite $client, $resp, length($resp);

    # Handle bootloader info request
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 5, 'sync packet length';
    is $buf, "\x0F\x00\x00\x00\x04", "Got bootloader info request";
    $resp = "\x0F\x00\x00\x05\x05\x01\xFF\x84\x01\x02\x03\x00\x31\x42\x04";
    syswrite $client, $resp, length($resp);

    # Handle PIC version request
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 11, 'PIC device packet length';
    is $buf, "\x0F\x01\xFE\xFF\x3F\x00\x02\x00\xB4\x6D\x04",
        "Got PIC type request";
    $resp = "\x0F\x71\x02\x00\x5A\x89\x04";
    syswrite $client, $resp, length($resp);

    # Handle EEPROM read request
    $sel->can_read( 10 * $debug_mult ) or die;
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 13, "Request EEPROM read count OK";
    is $buf, "\x0f\x05\x05\x00\x00\x00\x00\x05\x04\x00\x63\xb5\x04",
        "EEPROM read command OK";
    $resp = "\x0F\x31\x32\x33\x34\x89\xD7\x04";
    syswrite $client, $resp, length($resp);

    # Handle Flash read request
    $sel->can_read( 10 * $debug_mult ) or die;
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 11, "Request FLASH read count OK";
    is $buf, "\x0f\x01\x00\x00\x00\x00\x0a\x00\xaa\x57\x04",
        "FLASH read command OK";
    $resp
        = "\x0F\x01\x02\x03\x05\x04\x05\x05\x06\x07\x08\x09\x00\x01\x6C\x04";
    syswrite $client, $resp, length($resp);

    # Handle Flash erase page request
    $sel->can_read( 10 * $debug_mult ) or die;
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 10, "Request FLASH erase count OK";
    is $buf, "\x0f\x03\x00\x01\x00\x00\x02\x16\x98\x04",
        "FLASH erase command OK";
    $resp = "\x0F\x03\x63\x30\x04";
    syswrite $client, $resp, length($resp);

    # Handle the request for CRC of two pages
    $sel->can_read( 10 * $debug_mult ) or die;
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 11, "Request CRC of two pages OK";
    is $buf, "\x0f\x02\x00\x00\x00\x00\x02\x00\x81\x06\x04",
        "CRC request command OK";
    $resp = "\x0F\xAA\xBB\xCC\xDD\x04";
    syswrite $client, $resp, length($resp);

    # Handle the flash write request
    $sel->can_read( 10 * $debug_mult ) or die;
    $bytes = sysread $client, $buf, 2048;

    #is $bytes, 139, "Flash write request received";
    is $bytes, 75, "Flash write request received";
    my $header = substr( $buf, 0, 8 );
    is $header, "\x0f\x05\x04\x00\x10\x00\x00\x01",
        "Start of packet looks fine";
    $resp = "\x0F\x04\x84\x40\x04";
    syswrite $client, $resp, length($resp);

    # Handle the launch application request
    $sel->can_read( 10 * $debug_mult ) or die;
    $bytes = sysread $client, $buf, 2048;
    is $bytes, 5, "Request launch application size OK";
    is $buf, "\x0f\x08\x08\x81\x04", "Launch app command OK";

    syswrite $client, $resp, length($resp);

}
elsif ($pid) {

    #parent
    my $loader = Device::Microchip::Bootloader->new(
        firmware => 't/stim/test.hex',
        device   => '127.0.0.1' . ":" . $tcp_port,
        verbose  => 3
    );
    ok $loader, 'object created';

    # Connect to controller
    $loader->connect_target();

# Now we're connected to the mocked PIC and we have received the ID and software version
# Version should be 1.5 by now
    my $version = $loader->bootloader_version();
    is $version->{'major'},    1,   'Major version of the bootloader OK';
    is $version->{'minor'},    5,   'Minor version of the bootloader OK';
    is $loader->{'device_id'}, 625, 'Talking to the correct type of PIC';

    # Try to read an EEPROM location
    my $data = $loader->read_eeprom( 0, 4 );
    is $data, "31323334", "EEPROM reading";

    # Try to read a flash memory location
    $data = $loader->read_flash( 0, 10 );
    is $data, "01020304050607080900", "Flash reading";

    # Try to erase 2 flash pages
    $data = $loader->erase_flash( 0x100, 2 );
    is $data, "03", "Erased 2 pages";

    # Request the CRC of two pages
    $data = $loader->read_flash_crc( 0x0, 2 );
    is_deeply $data, { 0 => "BBAA", 1 => "DDCC" },
        "Read the CRC of two pages";

# Try to program a page
#$data = $loader->write_flash(0x1000, "0201000000000000000000000000000000000000020100000000000000000000000000000000000002010000000000000000000000000000000000000201000000000000000000000000000000000000020100000000000000000000000000000000000002010000000000000000000000000000000000001111222233334444");
    $data = $loader->write_flash( 0x1000,
        "00000000000000000000000000000000020100000000000000000000000000000000000002010000000000000000000000000000000000001111222233334444"
    );
    is $data, "04", "Write flash command OK";

    # Launch the application
    $loader->launch_app();

    #is ($loader->program, 1, 'Programming over TCP done');
    waitpid $pid, 0;
    done_testing();
}
else {
    die $!;
}
