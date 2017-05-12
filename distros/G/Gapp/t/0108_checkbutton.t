#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::CheckButton';

my $w = Gapp::CheckButton->new;
isa_ok $w, 'Gapp::CheckButton';
isa_ok $w->gobject, 'Gtk2::CheckButton';
