#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

for (qw(
  INI_File
)) {
  use_ok($_);
}

done_testing;

