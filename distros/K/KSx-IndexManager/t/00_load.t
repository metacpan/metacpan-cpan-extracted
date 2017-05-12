#!perl

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
  use_ok("KSx::IndexManager");
  use_ok("KSx::IndexManager::Plugin");
  use_ok("KSx::IndexManager::Plugin::Partition");
}
