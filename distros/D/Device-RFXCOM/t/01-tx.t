#!/usr/bin/perl
#
# Copyright (C) 2010 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_RFXCOM_TX_TEST_DEBUG}
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
  use t::Helpers qw/test_warn/;
}

my @connections =
  (
   [
    {
     transmit => undef,
     desc => 'version check',
     recv => 'F030F030',
     send => '10',
     init => 0,
    },
    {
     transmit => undef,
     desc => 'set mode',
     recv => 'F037F037',
     send => '37',
     init => 1,
    },
    {
     transmit => { type => 'x10', command => 'off', device => 'i10' },
     desc => 'x10/i10/off',
     recv => '20E41B30CF',
     send => '37',
     init => 1,
    },
    {
     transmit => { type => 'x10', command => 'on', device => 'i2,i3,q0' },
     desc => 'x10/i2,i3/on - i2',
     recv => '20E01F10EF', # i2/on
     send => '37',
     init => 1,
    },
    {
     transmit => undef,
     desc => 'x10/i2,i3/on - i3',
     recv => '20E01F08F7', # i3/on
     send => '37',
     init => 1,
    },
    # no q0 as that is invalid
    {
     transmit => { type => 'x10', command => 'bright', house => 'j' },
     desc => 'x10/j/bright',
     recv => '20F00F8877',
     send => '37',
     init => 1,
    },
    {
     transmit => { type => 'homeeasy', command => 'off',
                   address => 'xmas', unit => 10 },
     desc => 'homeeasy/xmas/10/off',
     recv => '2101D5EA0A00',
     send => '37',
     init => 1,
    },
    {
     transmit => { type => 'homeeasy', command => 'on',
                   address => '0x3333', unit => 1 },
     desc => 'homeeasy/0x3333/1/on',
     recv => '21000CCCD100',
     send => '37',
     init => 1,
    },
    {
     transmit => { type => 'homeeasy', command => 'preset',
                   address => 'test', unit => 9, level => 5 },
     desc => 'homeeasy/test/9/preset/5',
     recv => '2401CD490950',
     send => '37',
     init => 1,
    },
   ],

   [
    {
     transmit => { type => 'homeeasy', command => 'on',
                   address => 'console', unit => 'group' },
     desc => 'homeeasy/console/group/on',
     recv => 'F030F030',
     send => '10',
     init => 0,
    },
    {
     transmit => undef,
     desc => 'enable harrison',
     recv => 'F03CF03C',
     send => '33',
     init => 0,
    },
    {
     transmit => undef,
     desc => 'enable koko',
     recv => 'F03DF03D',
     send => '33',
     init => 0,
    },
    {
     transmit => undef,
     desc => 'enable flamingo',
     recv => 'F03EF03E',
     send => '33',
     init => 0,
    },
    {
     transmit => undef,
     desc => 'disabling x10',
     recv => 'F03FF03F',
     send => '37',
     init => 0,
    },
    {
     transmit => undef,
     desc => 'set mode',
     recv => 'F033F033',
     send => '33',
     init => 1,
    },
    {
     transmit => undef,
     desc => 'homeeasy/console/group/on',
     recv => '21AA163DB000',
     send => '33',
     init => 1,
    },
   ],

  );

my @sc = ();
foreach my $con (@connections) {
  my @a = ();
  foreach my $rec (@$con) {
    my ($recv, $send, $desc) = @{$rec}{qw/recv send desc/};
    push @a,
      [ packrecv => $recv, $desc ],
      [ packsend => $send, $desc ];
  }
  push @sc, \@a;
}

my $server;
eval { $server = AnyEvent::MockTCPServer->new(connections => \@sc); };
plan skip_all => "Failed to create dummy server: $@" if ($@);
my ($host, $port) = $server->connect_address;
my $addr = join ':', $host, $port;

import Test::More tests => 56;
use_ok('Device::RFXCOM::TX');

my $tx;
my $w;
my %args = ();

my $cv;
foreach my $con (@connections) {

  my $init = 0;
  $tx = Device::RFXCOM::TX->new(%args,
                                device => $addr,
                                init_callback => sub { $init++ });

  ok($tx, 'instantiate Device::RFXCOM::TX object');

  $w = AnyEvent->io(fh => $tx->filehandle, poll => 'r',
                    cb => sub { $cv->send($tx->wait_for_ack()) });

  $cv = AnyEvent->condvar;
  foreach my $rec (@$con) {
    my ($tran, $desc, $sent, $init_exp) = @{$rec}{qw/transmit desc send init/};
    if ($tran) {
      print STDERR "Transmitting: $desc\n" if DEBUG;
      $tx->transmit(%$tran) if ($tran);
    }
    my $res = $cv->recv;
    print STDERR "Received ack for $desc\n" if DEBUG;
    is((unpack 'H*', $res), $sent, 'response - '.$desc);
    is($init, $init_exp, 'init == '.$init_exp.' - '.$desc);
    $cv = AnyEvent->condvar;
  }

  # invert all the defaults
  %args =
    (
     receiver_connected => 1,
     harrison => 1,
     koko => 1,
     flamingo => 1,
     x10 => 0,
    );
}

undef $server;

eval { $tx->transmit(type => 'magic', command => 'fetch cake'); };
like($@, qr!^\Q$tx\E->transmit: magic encoding not supported at !,
     'invalid transmit type');

like(test_warn(sub { $tx->transmit(type => 'x10', command => 'on'); }),
     qr!->encode: Invalid x10 message!, 'invalid x10 message');

SKIP: {
  skip 'fails with some event loops', 1
    unless ($AnyEvent::MODEL eq 'AnyEvent::Impl::Perl');
  eval { my $res = $cv->recv; };
  like($@, qr!^closed at \Q$0\E line \d+!, 'check close');
}

undef $tx;
undef $w;

eval { Device::RFXCOM::TX->new(device => $addr) };
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o, 'connection failed');

undef $tx;

eval { Device::RFXCOM::TX->new(device => $host, port => $port) };
like($@, qr!^TCP connect to '\Q$addr\E' failed:!o,
     'connection failed (default port)');

undef $tx;
