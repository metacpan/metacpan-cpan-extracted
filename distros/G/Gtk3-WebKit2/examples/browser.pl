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

use common::sense;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use Gtk3 -init;
use Gtk3::WebKit2;
use Gtk3::JavaScriptCore;
use JSON qw(encode_json);

sub main {
    my ($self) = @_;

    my ($url) = shift @ARGV || 'http://localhost:3000/reachable';

    my $window = Gtk3::Window->new('toplevel');
    $window->set_default_size(800, 600);
    $window->signal_connect(destroy => sub { Gtk3->main_quit() });

    my $ctx = Gtk3::WebKit2::WebContext::get_default();

    # Create a WebKit widget
    my $view = Gtk3::WebKit2::WebView->new_with_context($ctx);

    $view->signal_connect('load-changed', sub {
        my ($view, $load_event) = @_;

        if ($load_event eq 'finished') {
            run_javascript($view, 'document.title;');
        }
    });

    # Load a page
    $view->load_uri($url);

    # Pack the widgets together
    my $scrolls = Gtk3::ScrolledWindow->new();
    $scrolls->add($view);
    $window->add($scrolls);
    $window->show_all();

    Gtk3::main_iteration while Gtk3::events_pending;

    # step 1: find a way to execute javascript and get json back
    # step 2: create WWW::Webkit2 module that uses Gtk3::WebKit2, ie get_title
    # step 3: find any memory issues?
    Gtk3->main;

    # github repository

    # installation:
    # sudo zypper in typelib-1_0-WebKit2-4_0
    # sudo zypper in typelib-1_0-JavaScriptCore-4_0

    return 0;
}

sub run_javascript {
    my ($view, $javascript_string) = @_;

    my $done = 0;

    $view->run_javascript($javascript_string, undef, sub {
        my ($object, $result, $user_data) = @_;
        $done = 1;
        return get_json_from_javascript_result($view, $result);
    }, undef);

    Gtk3::main_iteration while Gtk3::events_pending and not $done;
}

sub get_json_from_javascript_result {
    my ($view, $result) = @_;

    my $value = $view->run_javascript_finish($result);
    my $js_value = $value->get_js_value;
    say $js_value->is_string;

    my $json = encode_json $js_value->to_string;

    return $json;
}

exit main() unless caller;
