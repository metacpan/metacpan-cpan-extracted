#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_RX_TEST_DEBUG}
};

$|=1;

BEGIN {
  require Test::More;
  eval { require AnyEvent; import AnyEvent;
         require AnyEvent::Handle; import AnyEvent::Handle;
         require AnyEvent::Socket; import AnyEvent::Socket };
  if ($@) {
    import Test::More skip_all => 'Missing AnyEvent module(s): '.$@;
  }
  eval { require AnyEvent::MockTCPServer; import AnyEvent::MockTCPServer };
  if ($@) {
    import Test::More skip_all => 'No AnyEvent::MockTCPServer module: '.$@;
  }
  import Test::More;
}

my @connections =
  (
   [
    [ packrecv => 'F020', 'version check' ],
    [ packsend => '4d26', 'version check response' ],

    [ packrecv => 'F02A', 'enable all possible receiving modes' ],
    [ packsend => '41', 'enable all possible receiving modes response' ],

    [ packrecv => 'F041', 'set variable length mode' ],
    [ packsend => '2c',
      # mode is still 0x41 really but differs here for coverage
      'set variable length mode response' ],

    [ packsend => '20609f08f7', 'x10 message' ],

    [ packsend => '80', 'empty message' ],
   ],
  );

my $server;
eval { $server = AnyEvent::MockTCPServer->new(connections => \@connections); };
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
my $addr = join ':', $host, $port;

import Test::More tests => 47;

use_ok('Device::RFXCOM::RX');

my $init = 0;

my $rx = Device::RFXCOM::RX->new(device => $addr,
                                 init_callback => sub { $init++ });

ok($rx, 'instantiate Device::RFXCOM::RX object');

is($rx->queue, 2, 'queued initialization');
is($rx->baud, 4800, 'baud initialization');

my $cv = AnyEvent->condvar;
my $res;
my $w = AnyEvent->io(fh => $rx->filehandle, poll => 'r',
                     cb => sub { $cv->send($rx->read()) });
$res = $cv->recv;
is($res->type, 'version', 'got version check response');
is($res->header_byte, 0x4d, '... correct header_byte');
ok($res->master, '... from master receiver');
is($res->length, 1, '... correct data length');
is_deeply($res->bytes, [0x26], '... correct data bytes');
is($res->summary, 'master version 4d.26', '... correct summary string');
is($init, 0, '... initialization incomplete');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res->type, 'mode', 'got 1st mode acknowledgement');
is($res->header_byte, 0x41, '... correct header_byte');
ok($res->master, '... from master receiver');
is($res->length, 0, '... correct data length');
is(@{$res->bytes}, 0, '... no data bytes');
is($res->summary, 'master mode 41.', '... correct summary string');
is($init, 0, '... initialization incomplete');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res->type, 'mode', 'got 2nd mode acknowledgement');
is($res->header_byte, 0x2c, '... correct header_byte');
ok($res->master, '... from master receiver');
is($res->length, 0, '... correct data length');
is(@{$res->bytes}, 0, '... no data bytes');
is($res->summary, 'master mode 2c.', '... correct summary string');
is($init, 1, '... initialization complete');

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res->type, 'x10', 'got x10 message');
is($res->header_byte, 0x20, '... correct header_byte');
ok($res->master, '... from master receiver');
is($res->length, 4, '... correct data length');
is($res->hex_data, '609f08f7', '... correct data');
is($res->summary,
   'master x10 20.609f08f7: x10/a3/on',
   '... correct summary string');

is(scalar @{$res->messages}, 1, '... correct number of messages');
my $message = $res->messages->[0];
is($message->type, 'x10', '... correct message type');
is($message->command, 'on', '... correct message command');
is($message->device, 'a3', '... correct message device');
undef $message;

$cv = AnyEvent->condvar;
$res = $cv->recv;
is($res->type, 'empty', 'got empty message');
is($res->header_byte, 0x80, '... correct header_byte');
ok(!$res->master, '... from slave receiver');
is($res->length, 0, '... correct data length');
is($res->hex_data, '', '... no data');
is($res->summary, 'slave empty 80.', '... correct summary string');

SKIP: {
  skip 'fails with some event loops', 1
    unless ($AnyEvent::MODEL eq 'AnyEvent::Impl::Perl');
  $cv = AnyEvent->condvar;
  eval { $res = $cv->recv; };
  like($@, qr!^closed at \Q$0\E line \d+!, 'check close');
}

undef $rx;
undef $w;
undef $server;

eval { Device::RFXCOM::RX->new(device => $addr) };
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o, 'connection failed');

undef $rx;

eval { Device::RFXCOM::RX->new(device => $host, port => $port) };
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o,
     'connection failed (default port)');

undef $rx;
