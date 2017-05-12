#!/usr/bin/perl

=head1 NAME

validation.pl - Accepts only ASCII letters.

=head1 DESCRIPTION

This sample program shows how to make a simple text validation widget. This
particular example considers ASCII letters as being the only valid characters,
any other character will be underlined in red but still accepted by the widget.

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
	
	my $vbox = new Gtk2::VBox(FALSE, 0);
	$vbox->pack_start($entry, FALSE, FALSE, FALSE);
	$vbox->set_focus_child($entry);
	$window->add($vbox);
	
	$entry->signal_connect(changed => \&on_change);
	
	$window->signal_connect(delete_event => sub { Gtk2->main_quit(); });
	
	$window->show_all();
	Gtk2->main();

	return 0;
}


#
# Each time that the text is changed we validate it. If there's an error within
# the text we use Pango markup to highlight it.
#
sub on_change {
	my ($widget) = @_;

	my $string = $widget->get_text;

	# Validate the entry's text (accepting only letters)
	$string =~ s/([^a-z]+)/apply_pango_makup($1)/egi;

	$widget->set_markup($string);
	$widget->signal_stop_emission_by_name('changed');
}


#
# Applies Pango markup to the given text. The text has the conflicting XML
# characters encoded with entities first.
#
sub apply_pango_makup {
	my ($text) = @_;

	# Escape the XML entities - MUST be done before applying the Pango markup
	$text = Glib::Markup::escape_text($text);

	# Apply the Pango markup to the escaped text
	return qq(<span underline="error" underline_color="red">$text</span>);
}
