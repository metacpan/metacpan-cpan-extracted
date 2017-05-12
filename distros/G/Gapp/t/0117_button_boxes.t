#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 6;

use Gtk2 '-init';





{
    use_ok 'Gapp::HButtonBox';
    my $w = Gapp::HButtonBox->new;
    isa_ok $w, q[Gapp::HButtonBox];
    isa_ok $w->gobject, q[Gtk2::HButtonBox];
}


{
    use_ok 'Gapp::VButtonBox';
    my $w = Gapp::VButtonBox->new;
    isa_ok $w, q[Gapp::VButtonBox];
    isa_ok $w->gobject, q[Gtk2::VButtonBox];
}




