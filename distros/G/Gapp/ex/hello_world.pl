#!/usr/bin/perl -w
use strict;
use warnings;

use Gtk2 '-init';


use Gapp;
use Gapp::Actions::Basic qw( Quit );

my $window = Gapp::Window->new(
    title => 'Gapp Application',
    signal_connect => [
        ['delete-event', Quit ]
    ],
    content => [
        Gapp::Label->new( text => 'Hello world!' ),
    ]
);

$window->show_all;

Gtk2->main;