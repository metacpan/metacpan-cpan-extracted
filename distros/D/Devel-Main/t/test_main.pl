#!/usr/bin/env perl

use strict;
use warnings;

use lib "./lib";

use Devel::Main 'main';

main {
  my ($name) = @ARGV;
  $name //= 'World';
  
  print "Hello $name!\n";  
};