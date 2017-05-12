#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
  use_ok 'Hoobot';
  use_ok 'Hoobot::Page';
  use_ok 'Hoobot::Login';
}

cmp_ok(Hoobot->VERSION, '>', 0, "Has a version");
