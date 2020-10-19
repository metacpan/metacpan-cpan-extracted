#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $solver = Gnome2::Dia::Solver -> new();
isa_ok($solver, "Gnome2::Dia::Solver");

my $constraint = Gnome2::Dia::Constraint -> new();
my $var = Gnome2::Dia::Variable -> new();

$constraint -> add($var, 23);

$solver -> add_constraint($constraint);
$solver -> resolve();
$solver -> remove_constraint($constraint);
