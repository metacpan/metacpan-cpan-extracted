#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';





{
    use_ok 'Gapp::HPaned';
    my $w = Gapp::HPaned->new;
    isa_ok $w, q[Gapp::HPaned];
    isa_ok $w->gobject, q[Gtk2::HPaned];
}


{
    use_ok 'Gapp::VPaned';
    my $w = Gapp::VPaned->new;
    isa_ok $w, q[Gapp::VPaned];
    isa_ok $w->gobject, q[Gtk2::VPaned];
}




