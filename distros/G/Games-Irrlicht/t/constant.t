#!/usr/bin/perl -w

use Test::More tests => 2;
use strict;

BEGIN
  {
  $| = 1;
  use blib;
  use lib '../blib/lib';
  use lib '../blib/arch';
  chdir 't' if -d 't';
  use_ok ('Games::Irrlicht::Constants');
  }

can_ok ('Games::Irrlicht::Constants', qw/
  EDT_NULL
  EDT_OPENGL
  /);

# etc etc we really dont want to duplicate all constants here, right?

