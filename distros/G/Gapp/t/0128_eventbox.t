#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';


use_ok 'Gapp::EventBox';



{ # basic construction test
    my $w = Gapp::EventBox->new;
    isa_ok $w, 'Gapp::EventBox';
    isa_ok $w->gobject,  'Gtk2::EventBox';
}

