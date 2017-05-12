#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 5;

use Gtk2 '-init';
use_ok 'Gapp::Window';

{ # basic test
    my $w = Gapp::Window->new;
    isa_ok $w, 'Gapp::Window';
    isa_ok $w->gobject, 'Gtk2::Window';
}

{ # transient for
    my $t = Gapp::Window->new;
    my $w = Gapp::Window->new( transient_for => $t, position => 'center' );
    ok $w->gobject->get_transient_for, 'set window transient for';
    ok $w->gobject->get_position, 'set window position';
}


