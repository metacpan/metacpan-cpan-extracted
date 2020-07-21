#!/usr/bin/env perl
package
  MyApp2;
use strict;
use warnings;

use File::AddInc [libdir_var => qw($libdir)];
use lib "$libdir/etc", $libdir, "$libdir/perl5";

use my_config;
use my_lib;

unless (caller) {
  print $my_config::foo, my_lib::bar(), "\n";
}

1;
