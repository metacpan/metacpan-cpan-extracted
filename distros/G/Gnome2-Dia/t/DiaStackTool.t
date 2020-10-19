#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 1;

# $Id$

###############################################################################

my $stack = Gnome2::Dia::StackTool -> new();
isa_ok($stack, "Gnome2::Dia::StackTool");

$stack -> push($stack);
$stack -> pop();
