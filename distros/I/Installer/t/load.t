#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

for (qw(
  App::Installer
  Installer
  Installer::Software
  Installer::Target
)) {
  use_ok($_);
}

done_testing;
