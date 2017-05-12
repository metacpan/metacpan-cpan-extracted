#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';






{ # basic construction test
    use_ok 'Gapp::Expander';
    my $w = Gapp::Expander->new;
    isa_ok $w, 'Gapp::Expander';
    isa_ok $w->gobject,  'Gtk2::Expander';
}
