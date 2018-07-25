#!/usr/bin/env perl
package
  MyApp::Deep::Runnable::Module;
use strict;

use File::AddInc;
use MyApp::Util;

unless (caller) {
  print File::AddInc->libdir, "\n";
  print "OK", "\n";
  print MyApp::Util->FOO, "\n";
}

1;
