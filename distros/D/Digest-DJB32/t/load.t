#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Digest::DJB32
)) {
  use_ok($_);
}

done_testing;

