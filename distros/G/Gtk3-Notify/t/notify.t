#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;


use Gtk3 -init;


BEGIN {
    use_ok('Gtk3::Notify', -init, "test_app");
}


sub main {
    my $view = Gtk3::Notify::Notification->new("Title", "test", undef);
    isa_ok($view, 'Gtk3::Notify::Notification');
    return 0;
}


exit main() unless caller;
