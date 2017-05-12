#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';

{
    use_ok 'Gapp::Toolbar';
    
    my $w = Gapp::Toolbar->new;
    isa_ok $w, 'Gapp::Toolbar';
    isa_ok $w->gobject, 'Gtk2::Toolbar';
}
