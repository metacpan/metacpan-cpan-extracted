#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::Entry';

my $w = Gapp::Entry->new;
isa_ok $w, 'Gapp::Entry';
isa_ok $w->gobject, 'Gtk2::Entry';
