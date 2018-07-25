#!/usr/bin/env perl
package
  MyApp2::Foo::Bar;

use File::AddInc;
use MyApp2::Baz::Qux;

unless (caller) {
  print File::AddInc->libdir, "\n";
  print "OK", "\n";
  print MyApp2::Baz::Qux->RESULT, "\n";
}

1;
