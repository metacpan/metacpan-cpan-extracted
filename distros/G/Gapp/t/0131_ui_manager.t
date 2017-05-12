#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::UIManager';

my $w = Gapp::UIManager->new;
isa_ok $w, 'Gapp::UIManager';
isa_ok $w->gobject, 'Gtk2::UIManager';
