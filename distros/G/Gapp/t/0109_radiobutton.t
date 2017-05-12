#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::RadioButton';

my $w = Gapp::RadioButton->new;
isa_ok $w, 'Gapp::RadioButton';
isa_ok $w->gobject, 'Gtk2::RadioButton';
