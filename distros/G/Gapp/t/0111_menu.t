#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 7;

use Gtk2 '-init';
use_ok 'Gapp::Menu';

{
    my $w = Gapp::Menu->new;
    isa_ok $w, 'Gapp::Menu';
    isa_ok $w->gobject, 'Gtk2::Menu';
}

use_ok 'Gapp::MenuItem';
{
    my $w = Gapp::MenuItem->new;
    isa_ok $w, 'Gapp::MenuItem';
    isa_ok $w->gobject, 'Gtk2::MenuItem';
    
    $w->set_visible_func( sub { 1 } );
    is ref $w->visible_func, 'CODE', 'got visble func';
}
