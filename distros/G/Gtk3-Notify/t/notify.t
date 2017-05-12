#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
use Data::Dumper;


use Gtk3 -init;


BEGIN {
    use_ok('Gtk3::Notify');
}


sub main {
    my $view = Gtk3::Notify::Notification->new();
    isa_ok($view, 'Gtk3::Notify::Notification');
    return 0;
}


exit main() unless caller;
