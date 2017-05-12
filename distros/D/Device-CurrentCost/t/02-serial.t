#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG};
use Test::More;
use lib 't/lib';

$|=1;
use_ok('Device::CurrentCost');
BEGIN { use_ok('Device::CurrentCost::Constants'); }

my $dev = Device::CurrentCost->new(device => 't/log/envy.reading.xml');
ok $dev, 'envy serial device';
is_deeply
  $dev->serial_port->calls(),
  [
   [ 'Device::SerialPort::baudrate' => 57600 ],
   [ 'Device::SerialPort::databits' => 8 ],
   [ 'Device::SerialPort::parity' => 'none' ],
   [ 'Device::SerialPort::stopbits' => 1 ],
   [ 'Device::SerialPort::datatype' => 'raw' ],
   [ 'Device::SerialPort::write_settings' ],
  ], '... expected Device::SerialPort calls';

$dev = Device::CurrentCost->new(device => 't/log/classic.reading.xml',
                                   type => CURRENT_COST_CLASSIC);
ok $dev, 'classic serial device';
is_deeply
  $dev->serial_port->calls(),
  [
   [ 'Device::SerialPort::baudrate' => 9600 ],
   [ 'Device::SerialPort::databits' => 8 ],
   [ 'Device::SerialPort::parity' => 'none' ],
   [ 'Device::SerialPort::stopbits' => 1 ],
   [ 'Device::SerialPort::datatype' => 'raw' ],
   [ 'Device::SerialPort::write_settings' ],
  ], '... expected Device::SerialPort calls';

done_testing;
