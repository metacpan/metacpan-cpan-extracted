#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';





{
    use_ok 'Gapp::ScrolledWindow';
    my $w = Gapp::ScrolledWindow->new;
    isa_ok $w, q[Gapp::ScrolledWindow];
    isa_ok $w->gobject, q[Gtk2::ScrolledWindow];
}





