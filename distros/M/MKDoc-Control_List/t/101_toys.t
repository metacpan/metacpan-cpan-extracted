#!/usr/bin/perl

package GDGDGD;

use strict;
use warnings;
use Test::More qw /no_plan/;

use lib 'lib';
use MKDoc::Control_List;

use vars qw /$Current_Child/;

sub default {return "Gizmo"};

my $control_list = new MKDoc::Control_List (file => 't/data/toy_config.txt');
my $toy;

$Current_Child = "Davey";
($toy)      = $control_list->process();
is ($toy, "Galaxy Warrior");

$GDGDGD::Current_Child = "Deanna";
($toy)      = $control_list->process();
is ($toy, "Doll");

local $Current_Child = "Deacus";
($toy)      = $control_list->process();
is ($toy, "Gizmo");

