#!/usr/bin/perl

use strict;
use warnings;

use Test::NeedsDisplay;
use Test::More 'no_plan';
use Data::Dumper;


use Gtk3 -init;


BEGIN {
    use_ok('Gtk3::WebKit2');
}


sub main {
    # Grab the session so that headless unit test don't crash, see RT 93421
    # my $session = Gtk3::WebKit2::get_default_session();

    my $view = Gtk3::WebKit2::WebView->new();
    isa_ok($view, 'Gtk3::WebKit2::WebView');
    return 0;
}


exit main() unless caller;
