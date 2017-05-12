#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 15;

use Gtk2 '-init';

{
    use_ok 'Gapp::ToolButton';
    
    my $w = Gapp::ToolButton->new;
    isa_ok $w, 'Gapp::ToolButton';
    isa_ok $w->gobject, 'Gtk2::ToolButton';
}

{
    use_ok 'Gapp::MenuToolButton';
    
    my $w = Gapp::MenuToolButton->new;
    isa_ok $w, 'Gapp::MenuToolButton';
    isa_ok $w->gobject, 'Gtk2::MenuToolButton';
}


{
    use_ok 'Gapp::ToggleToolButton';
    
    my $w = Gapp::ToggleToolButton->new;
    isa_ok $w, 'Gapp::ToggleToolButton';
    isa_ok $w->gobject, 'Gtk2::ToggleToolButton';
}

{
    use_ok 'Gapp::RadioToolButton';

    my $w = Gapp::RadioToolButton->new;
    isa_ok $w, 'Gapp::RadioToolButton';
    isa_ok $w->gobject, 'Gtk2::RadioToolButton';
}


{
    use_ok 'Gapp::SeparatorToolItem';

    my $w = Gapp::SeparatorToolItem->new;
    isa_ok $w, 'Gapp::SeparatorToolItem';
    isa_ok $w->gobject, 'Gtk2::SeparatorToolItem';
}



