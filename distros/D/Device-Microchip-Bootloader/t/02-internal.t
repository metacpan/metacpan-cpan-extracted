#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# Check the regexp for de-escaping the communication stream between the
# controller and the software

use strict;

use Test::More;

BEGIN { use_ok 'Device::Microchip::Bootloader'; }

my $loader = Device::Microchip::Bootloader->new(
    firmware => 't/stim/short.hex',
    device   => '/dev/ttyUSB0'
);
ok $loader, 'object created';

# Verify the default baudrate is 115200
is $loader->{baudrate}, 115200, 'Default baudrate is 115200';

# Verify the escaping/unescaping of communication between the bootloader and the software
my $data = "\x00\x0F\x00\x05\x01\xFF\x84\x01\x02\x03\x05\x04\x05\x05\x04";

my $escaped = $loader->_escape($data);
is $escaped,
    "\x00\x05\x0F\x00\x05\x05\x01\xFF\x84\x01\x02\x03\x05\x05\x05\x04\x05\x05\x05\x05\x05\x04",
    "Testing escape code for serialization";

my $unescaped = $loader->_unescape($escaped);
is $unescaped, $data, "Unescaping yields original string";

$unescaped = $loader->_unescape("\x00\x01\x02\x03\x05\x04\x05\x05\x06");
is $unescaped, "\x00\x01\x02\x03\x04\x05\x06", "Standalone unescape test";

# Verify the int to string and reverse functions
my $smallint = 10;
my $bigint   = 1025;
my $str      = "BEBA";

my $small_string = $loader->_int2str($smallint);
my $big_string   = $loader->_int2str($bigint);
my $babe         = $loader->_str2int($str);

is $small_string, "0A00", "Small int2str";
is $big_string,   "0104", "Big int2str";
is $babe, hex("BABE"), "str2int check";

# Verify the CRC funcions
my $input = "\x00\x04\x01\x05\xFF\x84\x00\xFC\x00\x00";
my $crc   = $loader->_crc16($input);
is $crc, 0xCBC1, "CRC calculates according to Microchip implementation";

# Verify the swapping of the program memory
# Two words need to be rewritten otherwize the long jumps fail.
my $app_entry = 0xFC00 - 4;
$loader->_rewrite_entrypoints("BABEFACE");
is $loader->{_program}->{0}->{data}, "BABE",
    "Rewrote bootloader entry point #1";
is $loader->{_program}->{2}->{data}, "FACE",
    "Rewrote bootloader entry point #2";
is $loader->{_program}->{$app_entry}->{data}, "57EF",
    "Relocated application entry point #1";
is $loader->{_program}->{ $app_entry + 2 }->{data}, "00F0",
    "Relocated application entry point #2";

# Verify the function to get blocks from the source hex to program
$data = $loader->_get_writeblock(0);
is $data,
    "BABEFACEFFFFFFFFFACF12F0FBCF13F0E9CF14F059EF00F0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
    "Got correct write block";
$data = $loader->_get_writeblock(100);
is $data, "", "Empty write block returns empty string";

# Verify we can set the baudrate to non-default values
$loader = Device::Microchip::Bootloader->new(
    firmware => 't/stim/short.hex',
    device   => '/dev/ttyUSB0',
    baudrate => 9600
);
ok $loader, 'object created';

# Verify the default baudrate is 115200
is $loader->{baudrate}, 9600, 'Could override the baudrate to 9600';

done_testing();
