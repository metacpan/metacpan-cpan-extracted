#!/usr/bin/env perl
package
  MyApp;
use strict;
use warnings;

use File::AddInc qw($libdir);
use lib "$libdir/etc", $libdir, "$libdir/perl5";

use my_config;
use my_lib;

unless (caller) {
  print $my_config::foo, my_lib::bar(), "\n";
}

1;
