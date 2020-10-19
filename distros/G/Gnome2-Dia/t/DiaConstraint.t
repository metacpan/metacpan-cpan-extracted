#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 7;

# $Id$

###############################################################################

my $constraint = Gnome2::Dia::Constraint -> new();
isa_ok($constraint, "Gnome2::Dia::Constraint");

my $var = Gnome2::Dia::Variable -> new();

$constraint -> add($var, 23);
$constraint -> times(1);

ok($constraint -> has_variables());

$constraint -> optimize();

is($constraint -> solve($var), "-0");

$constraint -> foreach(sub {
  is($_[0], $constraint);
  is($_[1], $var);
  is($_[2], 23);
  is($_[3], "bla");
}, "bla");
