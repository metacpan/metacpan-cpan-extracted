#!/usr/bin/env perl
use strict;
use warnings;
use Device::PiFace ':all_constants';
use Test::More;

plan tests => 4;

my $hw_addr = $ENV{PIFACE_HARDWARE_ADDRESS} // 0;
my $piface = Device::PiFace->new (hw_addr => $hw_addr);

# Test the file descriptor
like $piface->fd, qr/^\d+$/, 'mcp23s17 file descriptor is numeric';

# Test the hardware address
is $piface->hw_addr, $hw_addr, 'hw_addr is what we expect it to be';

# Test I/O direction
is $piface->read (register => IODIRA), 0, 'output port is A';
is $piface->read (register => IODIRB), 0xFF, 'input port is B';

# We can't really test inputs since they depend on external factors.
