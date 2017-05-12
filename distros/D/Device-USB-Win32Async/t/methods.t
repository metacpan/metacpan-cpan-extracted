#!/usr/bin/perl

use Test::More tests => 2;
use Carp;
use strict;
use warnings;

use Device::USB;
use Device::USB::Win32Async;

# Original methods all there
can_ok( 'Device::USB::Device',
        qw/filename configurations get_configuration
        bcdUSB bDeviceClass bDeviceSubClass
       bDeviceProtocol bMaxPacketSize0 idVendor idProduct
       bcdDevice iManufacturer iProduct iSerialNumber bNumConfigurations/
);

# New methods added
can_ok( 'Device::USB::Device',
    qw/free_async cancel_async reap_async_nocancel reap_async submit_async
    interrupt_setup_async bulk_setup_async isochronous_setup_async/
);
