#!/usr/bin/env perl
package
  Foo;
use strict;

use File::AddInc -local_lib;

use Bar;

unless (caller) {
  print "OK\n";
}

1;
