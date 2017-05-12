#!/usr/bin/perl -w
# vim: ts=2 sw=2 filetype=perl expandtab

use warnings;
use strict;

use Test::More tests => 4;

BEGIN { use_ok 'IO::Pipely', 'pipely' };

### Test one-way pipe() pipe.

SKIP: {
  my ($uni_read, $uni_write) = pipely(type => 'pipe');
  skip "$^O does not support one-way pipe()", 1
    unless defined $uni_read and defined $uni_write;

  print $uni_write "whee pipe\n";
  my $uni_input = <$uni_read>; chomp $uni_input;
  ok($uni_input eq "whee pipe", "one-way pipe passed data unscathed");
}

### Test one-way socketpair() pipe.
SKIP: {
  my ($uni_read, $uni_write) = pipely(type => 'socketpair');

  skip "$^O does not support one-way socketpair()", 1
    unless defined $uni_read and defined $uni_write;

  print $uni_write "whee socketpair\n";
  my $uni_input = <$uni_read>; chomp $uni_input;
  ok(
    $uni_input eq 'whee socketpair',
    "one-way socketpair passed data unscathed"
  );
}

### Test one-way pair of inet sockets.
SKIP: {

  unless ($ENV{RUN_NETWORK_TESTS}) {
    skip 'RUN_NETWORK_TESTS environment variable is not true.', 1;
  }

  my ($uni_read, $uni_write) = pipely(type => 'inet');
  skip "$^O does not support one-way inet sockets.", 1
    unless defined $uni_read and defined $uni_write;

  print $uni_write "whee inet\n";
  my $uni_input = <$uni_read>; chomp $uni_input;
  ok(
    $uni_input eq 'whee inet',
    "one-way inet pipe passed data unscathed"
  );
}

exit 0;
