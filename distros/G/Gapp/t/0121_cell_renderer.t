#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';


{
    use_ok 'Gapp::CellRenderer';
    
    my $w = Gapp::CellRenderer->new(
        gclass => 'Gtk2::CellRendererText',
        property => 'text',
    );
    isa_ok $w, 'Gapp::CellRenderer';
    isa_ok $w->gobject, 'Gtk2::CellRendererText';
}
