#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  Digital
  Digital::Role
  Digital::Driver
)) {
  use_ok($_);
}

done_testing;

