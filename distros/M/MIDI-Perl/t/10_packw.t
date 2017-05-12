
# Time-stamp: "2005-01-29 16:39:19 AST"

use strict;
use Test;
BEGIN { plan tests => 13 }

use MIDI;
ok 1;

# Just test the BER

ok pack("w", 0x00000000), "\x00";
ok pack("w", 0x00000040), "\x40";
ok pack("w", 0x0000007F), "\x7F";
ok pack("w", 0x00000080), "\x81\x00";
ok pack("w", 0x00002000), "\xC0\x00";
ok pack("w", 0x00003FFF), "\xFF\x7F";
ok pack("w", 0x00004000), "\x81\x80\x00";
ok pack("w", 0x00100000), "\xC0\x80\x00";
ok pack("w", 0x001FFFFF), "\xFF\xFF\x7F";
ok pack("w", 0x00200000), "\x81\x80\x80\x00";
ok pack("w", 0x08000000), "\xC0\x80\x80\x00";
ok pack("w", 0x0FFFFFFF), "\xFF\xFF\xFF\x7F";

print "# 'Alchemical machinery runs smoothest in the imagination.'\n",
      "#   -- Terence McKenna\n",
;
