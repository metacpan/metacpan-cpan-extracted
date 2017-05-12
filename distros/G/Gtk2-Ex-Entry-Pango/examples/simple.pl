#!/usr/bin/perl

=head1 NAME

simple.pl - Apply Pango markup through buttons.

=head1 DESCRIPTION

This sample program provides some buttons that apply Pango markup.

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::Ex::Entry::Pango;


exit main();


sub main {

	my $window = Gtk2::Window->new();

	my $entry = Gtk2::Ex::Entry::Pango->new();
	
	my $button_markup1 = Gtk2::Button->new('Markup 1');
	my $button_markup2 = Gtk2::Button->new('Markup 2');
	my $button_text = Gtk2::Button->new('Text');
	
	my $hbox_bottom = new Gtk2::HBox(FALSE, 0);
	$hbox_bottom->pack_start($button_markup1, FALSE, FALSE, 0);
	$hbox_bottom->pack_start($button_markup2, FALSE, FALSE, 0);
	$hbox_bottom->pack_start($button_text, FALSE, FALSE, 0);

	my $vbox = new Gtk2::VBox(FALSE, 0);
	$vbox->pack_start($entry,       TRUE, TRUE, 0);
	$vbox->pack_start($hbox_bottom, TRUE, TRUE, 0);

	$window->set_focus_child($button_markup1);
	$window->add($vbox);
	
	# Use Pango markup
	$entry->set_markup(
		'<i>Pan</i><b>go</b> is <span underline="error" underline_color="red">fun</span>'
	);
	

	# Connect the signals
	$window->signal_connect(delete_event => sub { Gtk2->main_quit(); });


	$button_markup1->signal_connect(clicked => sub {
		$entry->set_markup('sm<b>aller</b> text');
	});

	$button_markup2->signal_connect(clicked => sub {
		$entry->set_markup('s<b>maller</b> text');
	});

	$button_text->signal_connect(clicked => sub {
		$entry->set_text('smaOOOOller text');
	});

	
	$window->show_all();
	Gtk2->main();

	return 0;
}
