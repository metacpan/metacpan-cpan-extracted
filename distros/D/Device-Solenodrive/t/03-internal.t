#!/bin/bin/perl
#
# Copyright (C) 2013 by Lieven Hollevoet

# Check internal functions of the module

use strict;

use Test::More;

BEGIN { use_ok 'Device::Solenodrive'; }
BEGIN { use_ok 'Test::Exception'; }
require Test::Exception;

my $soleno = Device::Solenodrive->new( device => '/dev/ttyUSB0' );
ok $soleno, 'object created';

# Verify the escaping/unescaping of communication
my $data = "\x00\x0F\x00\x05\x01\xFF\x84\x01\x02\x03\x05\x04\x05\x05\x04";

my $escaped = $soleno->_escape($data);
is $escaped,
    "\x00\x05\x0F\x00\x05\x05\x01\xFF\x84\x01\x02\x03\x05\x05\x05\x04\x05\x05\x05\x05\x05\x04",
    "Testing escape code for serialization";

my $unescaped = $soleno->_unescape($escaped);
is $unescaped, $data, "Unescaping yields original string";

$unescaped = $soleno->_unescape("\x00\x01\x02\x03\x05\x04\x05\x05\x06");
is $unescaped, "\x00\x01\x02\x03\x04\x05\x06", "Standalone unescape test";

# Verify the CRC funcions
my $input = "\x00\x04\x01\x05\xFF\x84\x00\xFC\x00\x00";
my $crc   = $soleno->_crc16($input);
is $crc, 0xCBC1, "CRC calculates according to the expected implementation";

# Verify invalid write_parameters cause the expected fails
throws_ok { $soleno->_write_packet( "BABE", "BE" ) } qr/Address should be 8/,
    "Check address length";
throws_ok { $soleno->_write_packet( "BABEFACE", "B" ) }
qr/Command should be 2 /, "Check command length";
lives_ok { $soleno->_write_packet( "BABEFACE", "FF" ) }
"No Mr. Powers, I expect you to die!";

done_testing();
