#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::MenuBar';

my $w = Gapp::MenuBar->new;
isa_ok $w, 'Gapp::MenuBar';
isa_ok $w->gobject, 'Gtk2::MenuBar';
