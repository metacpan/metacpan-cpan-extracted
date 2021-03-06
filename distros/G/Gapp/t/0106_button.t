#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::Button';

my $w = Gapp::Button->new;
isa_ok $w, 'Gapp::Button';
isa_ok $w->gobject, 'Gtk2::Button';
