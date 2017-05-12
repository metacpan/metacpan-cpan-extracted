#!/usr/bin/perl

#
# Test some aspects of the lazy loader
#

use strict;
use warnings;
use Glib;
use Test::More tests => 1;

SKIP: {
  skip 'need Glib::InitiallyUnowned', 1
    unless Glib->CHECK_VERSION(2, 10, 0);

  # Setup a strange hierarchy that tests whether the lazy loader can deal with
  # being invoked on a package that only indirectly inherits from a registered
  # package.
  @NotThere::ISA = ();
  @NotHere::ISA = ();
  @Foo::ISA = qw/NotThere Glib::InitiallyUnowned/;
  @Bar::ISA = qw/NotHere Foo/;
  ok (Bar->isa (qw/Glib::Object/),
      'the lazy loader correctly set up the hierarchy');
}


