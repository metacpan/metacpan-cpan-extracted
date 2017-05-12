#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG};
use Test::More;
use Test::Requires qw/Test::SharedFork Test::Warn/;
use Test::SharedFork;
use Test::Warn;
use IO::Pipe;

plan tests => 7;

$|=1;
use_ok('Device::CurrentCost');

my $pipe = IO::Pipe->new;
my $pid = fork();
if ($pid == 0) {
  # child
  $pipe->writer;
  $pipe->autoflush;

  print $pipe q{<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>17:02:42</time><tmpr>27.2</tmpr><sensor>0</sensor><id>00077</id><type>1</type><ch1><watts>01380</watts></ch1></msg><msg><src>truncated};

  select undef, undef, undef, 1;

  print $pipe q{<msg><src>CC128-v0.11</src><dsb>00596</dsb><time>17:02:42</time><tmpr>27.2</tmpr><sensor>0</sensor><id>00077</id><type>1</type><ch1><watts>01999</watts></ch1></msg>};

  close $pipe;

} elsif ($pid) {
  # parent
  $pipe->reader;
  my $dev = Device::CurrentCost->new(filehandle => $pipe,
                                     discard_timeout => 0.5);

  my $msg = $dev->read(1);
  is($msg->value, 1380, 'first value');

  warning_is { $msg = $dev->read(0.05) } '', 'no discard timeout yet';
  is($msg, undef, 'read timeout');
  select undef, undef, undef, 0.8;

  warning_like { $msg = $dev->read(1) }
    {carped => qr/Discarding '<msg><src>truncated'/}, 'discard timeout';
  is($msg->value, 1999, 'second value');

  is(test_error(sub { $dev->read(0.5) }), 'Device::CurrentCost->read: closed',
     'closed');

  waitpid $pid, 0;
} else {
  die $!;
}

sub test_error {
  eval { shift->() };
  local $_ = $@;
  s/\s+at\s.*$//s;
  $_;
}
