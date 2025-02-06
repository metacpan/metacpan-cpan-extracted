#!/usr/bin/env perl
package
  Foo;
use strict;

use File::AddInc -local_lib;

use Bar; # From local/lib

use Baz; # From lib/

unless (caller) {
  print "OK\n";
}

1;
