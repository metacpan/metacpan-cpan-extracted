#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  MCP::Picnic
)) {
  use_ok($_);
}

done_testing;
