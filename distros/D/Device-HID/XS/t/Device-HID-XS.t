# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Device-HID-XS.t'

#########################

use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Device::HID::XS') };

is Device::HID::XS::hid_init(), 0;
#is Device::HID::XS::hid_open(0, 0, undef), undef; 

