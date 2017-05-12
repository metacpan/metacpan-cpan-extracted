use strict;
use warnings;

use Test::More tests => 1;
use MARC::Charset::Constants qw(:all);
use MARC::Charset qw(utf8_to_marc8);

# a composed unicode character c with a cedilla should
# be decomposed into the marc8 cedilla combining character
# and the letter c

is(utf8_to_marc8(chr(0x00E7)), chr(0xF0) . 'c' );

