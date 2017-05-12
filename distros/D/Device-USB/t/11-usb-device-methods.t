#!perl -T

use Test::More tests => 2;
use Device::USB;
use strict;
use warnings;

#
# Just testing the existence of methods at this point, not their
#  functionality.
#

# Synthetics
can_ok( "Device::USB::Device",
        qw/DESTROY manufacturer product serial_number/ );

# libusb methods
can_ok( "Device::USB::Device",
        qw/open set_configuration set_altinterface clear_halt reset
           claim_interface release_interface control_msg get_string
           get_string_simple get_descriptor get_descriptor_by_endpoint
           bulk_read interrupt_read bulk_write interrupt_write/ );

