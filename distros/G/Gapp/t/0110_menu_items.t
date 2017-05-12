#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 21;

use Gtk2 '-init';

{
    use_ok 'Gapp::MenuItem';
    
    my $w = Gapp::MenuItem->new;
    isa_ok $w, 'Gapp::MenuItem';
    isa_ok $w->gobject, 'Gtk2::MenuItem';
}

{
    use_ok 'Gapp::ImageMenuItem';
    
    my $w = Gapp::ImageMenuItem->new;
    isa_ok $w, 'Gapp::ImageMenuItem';
    isa_ok $w->gobject, 'Gtk2::ImageMenuItem';
}

{
    use_ok 'Gapp::SeparatorMenuItem';

    my $w = Gapp::SeparatorMenuItem->new;
    isa_ok $w, 'Gapp::SeparatorMenuItem';
    isa_ok $w->gobject, 'Gtk2::SeparatorMenuItem';
}

{
    use_ok 'Gapp::CheckMenuItem';

    my $w = Gapp::CheckMenuItem->new;
    isa_ok $w, 'Gapp::CheckMenuItem';
    isa_ok $w->gobject, 'Gtk2::CheckMenuItem';
}


{
    use_ok 'Gapp::RadioMenuItem';

    my $w = Gapp::RadioMenuItem->new;
    isa_ok $w, 'Gapp::RadioMenuItem';
    isa_ok $w->gobject, 'Gtk2::RadioMenuItem';
}

{
    use_ok 'Gapp::SeparatorMenuItem';

    my $w = Gapp::SeparatorMenuItem->new;
    isa_ok $w, 'Gapp::SeparatorMenuItem';
    isa_ok $w->gobject, 'Gtk2::SeparatorMenuItem';
}


{
    use_ok 'Gapp::TearoffMenuItem';

    my $w = Gapp::TearoffMenuItem->new;
    isa_ok $w, 'Gapp::TearoffMenuItem';
    isa_ok $w->gobject, 'Gtk2::TearoffMenuItem';
}

