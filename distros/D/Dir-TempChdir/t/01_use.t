#! /usr/bin/perl

use strict;
use warnings;

use Config;
use Test::More tests => 1;

BEGIN {
  use_ok(
    'Dir::TempChdir',
    $Config{d_fchdir} ? () : '-IGNORE_UNSAFE_CHDIR_SECURITY_RISK'
  )
};
