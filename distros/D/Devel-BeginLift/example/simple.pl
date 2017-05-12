#!/usr/bin/env perl

use strict;
use warnings;

use Devel::BeginLift qw(foo baz);

use vars qw($i);

BEGIN { $i = 0 }

sub foo { "foo: $_[0]\n"; }

sub bar { "bar: $_[0]\n"; }

for (1 .. 3) {
  print foo($i++);
  print bar($i++);
}

no Devel::BeginLift;

print foo($i++);
