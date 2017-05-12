#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 3;

use Gtk2 '-init';
use_ok 'Gapp::ActionGroup';

my $w = Gapp::ActionGroup->new(
    actions => [
        Gapp::Action->new(
            name => 'new',
            label => 'New',
            icon => 'gtk-new'
        )
    ]
);


isa_ok $w, 'Gapp::ActionGroup';
ok $w->gobject, 'Gtk2::ActionGroup';
