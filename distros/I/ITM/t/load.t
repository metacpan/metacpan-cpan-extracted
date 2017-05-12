#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  ITM
  ITM::HardwareSource
  ITM::Role
  ITM::Overflow
  ITM::Instrumentation
  ITM::Sync
)) {
  use_ok($_);
}

done_testing;

