#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';

{
    use_ok 'Gapp::ToolItemGroup';
    
    my $w = Gapp::ToolItemGroup->new;
    isa_ok $w, 'Gapp::ToolItemGroup';
    isa_ok $w->gobject, 'Gtk2::ToolItemGroup';
}


{
    use_ok 'Gapp::ToolPalette';
    
    my $w = Gapp::ToolPalette->new;
    isa_ok $w, 'Gapp::ToolPalette';
    isa_ok $w->gobject, 'Gtk2::ToolPalette';
}
