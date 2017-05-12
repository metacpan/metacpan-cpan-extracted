#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';


{
    use_ok 'Gapp::ListStore';
    my $w = Gapp::ListStore->new( columns => [ 'Glib::String' ]);
    isa_ok $w, 'Gapp::ListStore';
    isa_ok $w->gobject, 'Gtk2::ListStore';
}

{
    use_ok 'Gapp::TreeStore';
    my $w = Gapp::TreeStore->new( columns => [ 'Glib::String' ]);
    isa_ok $w, 'Gapp::TreeStore';
    isa_ok $w->gobject, 'Gtk2::TreeStore';
}