#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';

use_ok 'Gapp::HBox';

my $w = Gapp::HBox->new;
isa_ok $w, 'Gapp::HBox';
isa_ok $w->gobject, 'Gtk2::HBox';
