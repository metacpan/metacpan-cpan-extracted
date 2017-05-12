#!/usr/bin/perl

=head1 NAME

simple.pl - Type in Pango markup and apply it on the fly.

=head1 DESCRIPTION

This sample program allows the user to type in Pango markup and to see the
results live.

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::Ex::Entry::Pango;


exit main();


sub main {

	my $window = Gtk2::Window->new();

	my $markup = Gtk2::Entry->new();
	my $entry = Gtk2::Ex::Entry::Pango->new();
	
	my $button_apply = Gtk2::Button->new('Apply');
	
	my $hbox_bottom = new Gtk2::HBox(FALSE, 0);
	$hbox_bottom->pack_start($markup, TRUE, TRUE, 0);
	$hbox_bottom->pack_start($button_apply, FALSE, FALSE, 0);

	my $vbox = new Gtk2::VBox(FALSE, 0);
	$vbox->pack_start($entry,       TRUE, TRUE, 0);
	$vbox->pack_start($hbox_bottom, TRUE, TRUE, 0);

	$window->set_focus_child($markup);
	$window->add($vbox);
	
	# Use Pango markup
	$entry->set_markup(
		'<i>Pan</i><b>go</b> is <span underline="error" underline_color="red">fun</span>'
	);
	

	# Connect the signals
	$window->signal_connect(delete_event => sub { Gtk2->main_quit(); });


	# Apply the user's Pango text
	$button_apply->signal_connect(clicked => sub {
		$markup->signal_emit('activate');
	});
	$markup->signal_connect(activate => sub {
		$entry->set_markup($markup->get_text);
	});

	
	$window->set_default_size(450, -1);
	$window->show_all();
	Gtk2->main();

	return 0;
}
