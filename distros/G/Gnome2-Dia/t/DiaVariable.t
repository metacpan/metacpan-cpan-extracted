#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 3;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaVariable.t,v 1.1 2004/09/14 17:54:17 kaffeetisch Exp $

###############################################################################

my $variable = Gnome2::Dia::Variable -> new();
isa_ok($variable, "Gnome2::Dia::Variable");

$variable -> set_value(23);
is($variable -> get_value(), 23);

$variable -> set_strength(qw(very-weak));
is($variable -> get_strength(), qw(very-weak));
