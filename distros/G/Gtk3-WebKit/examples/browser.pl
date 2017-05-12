#!/usr/bin/env perl

=head1 NAME

browser.pl - Embed a webkit widget in an application

=head1 SYNOPSIS

    browser.pl [URL]

Simple usage:

    browser.pl http://search.cpan.org/

=head1 DESCRIPTION

Display a web page.

=cut

use strict;
use warnings;

use Gtk3 -init;
use Gtk3::WebKit;


sub main {
    my ($url) = shift @ARGV || 'http://search.cpan.org/';

    my $window = Gtk3::Window->new('toplevel');
    $window->set_default_size(800, 600);
    $window->signal_connect(destroy => sub { Gtk3->main_quit() });

    # Create a WebKit widget
    my $view = Gtk3::WebKit::WebView->new();

    # Load a page
    $view->load_uri($url);

    # Pack the widgets together
    my $scrolls = Gtk3::ScrolledWindow->new();
    $scrolls->add($view);
    $window->add($scrolls);
    $window->show_all();

    Gtk3->main();
    return 0;
}


exit main() unless caller;
