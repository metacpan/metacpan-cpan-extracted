#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::Label';

my $w = Gapp::Label->new( text => 'Label' );
isa_ok $w, 'Gapp::Label';
isa_ok $w->gobject, 'Gtk2::Label';
