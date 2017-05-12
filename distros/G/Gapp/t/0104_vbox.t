#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::VBox';

my $w = Gapp::VBox->new;
isa_ok $w, 'Gapp::VBox';
isa_ok $w->gobject, 'Gtk2::VBox';
