#!/usr/bin/env perl
package
  MyApp3;
use strict;
use warnings;

use File::AddInc [these_libdirs => 'etc', q{}, 'perl5'];

use my_config;
use my_lib;

unless (caller) {
  print $my_config::foo, my_lib::bar(), "\n";
}

1;
