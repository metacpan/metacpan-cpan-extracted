#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::Dialog';

my $w = Gapp::Dialog->new(
    title => 'Gapp',
    buttons => [ qw(gtk-yes yes gtk-no no) ],

);

isa_ok $w, 'Gapp::Dialog';
isa_ok $w->gobject, 'Gtk2::Dialog';
