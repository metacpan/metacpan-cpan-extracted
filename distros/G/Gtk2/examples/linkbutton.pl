#!/usr/bin/perl -w

use strict;
use Gtk2 -init;

# you set one of these per app.
Gtk2::LinkButton->set_uri_hook (sub {
	my ($button, $url) = @_;
	my $message = Gtk2::MessageDialog->new
			($button->get_toplevel, [], 'info', 'ok',
			 "In a real app, you'd figure out how to handle "
			 ."opening urls, and do that here.  This is just "
			 ."an example of using the widget, so we don't "
			 ."mess around with all of that.\n\nUrl: $url");
	$message->run;
	$message->destroy;
});

my $window = Gtk2::Window->new;

my $button = Gtk2::LinkButton->new ("http://gtk2-perl.sf.net",
				    "Gtk2-Perl Homepage");

$window->add ($button);
$window->show_all;
$window->signal_connect (destroy => sub { Gtk2->main_quit });
Gtk2->main;
