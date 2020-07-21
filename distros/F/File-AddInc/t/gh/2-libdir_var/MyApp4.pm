#!/usr/bin/env perl
package
  MyApp4;
use strict;
use warnings;

use MyExporter 'etc', q{}, 'perl5';

use my_config;
use my_lib;

unless (caller) {
  print $my_config::foo, my_lib::bar(), "\n";
}

1;
