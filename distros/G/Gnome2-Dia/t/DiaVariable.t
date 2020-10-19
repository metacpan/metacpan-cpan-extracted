#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 3;

# $Id$

###############################################################################

my $variable = Gnome2::Dia::Variable -> new();
isa_ok($variable, "Gnome2::Dia::Variable");

$variable -> set_value(23);
is($variable -> get_value(), 23);

$variable -> set_strength(qw(very-weak));
is($variable -> get_strength(), qw(very-weak));
