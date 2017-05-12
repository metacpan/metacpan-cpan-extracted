#!/usr/bin/perl

=head1 NAME

podview.pl - Simple POD viewer.

=head1 SYNOPSIS

podview.pl [page]

=head1 DESCRIPTION

This sample program shows how to use Gtk2::Ex::Entry::Pango in order to make a
search box entry. This consists of a field that displays a default text (POD
name...). In this particular case the POD file names entered are validated on
the fly, if a page doesn't exist it is marked as being wrong with a red
underlining stroke.

This is a very basic POD viewer provided as a lame example. For a more complete
program performing the same task take a look at L<Gtk2::Ex::PodViewer>.

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::Ex::Entry::Pango;

use Pod::Simple::Search;
use Pod::Simple;
use Pod::Text;
use IO::String;


exit main();


sub main {

	my ($page) = @ARGV;
	
	# POD stuff
	my $pod_search = Pod::Simple::Search->new();
	my $pod_parser = Pod::Text->new(sentence => 0, width => 80);
	
	
	my ($entry, $textview) = create_widgets();
	$entry->set_empty_markup("<span color='grey' size='smaller'>POD name...</span>");
	
	
	# Check if there page entered exists (realtime validation)
	$entry->signal_connect('changed' => sub {
		
		my $page = $entry->get_text;
		if ($page eq "") {
			return;
		}
		
		# Check if the page exists
		my $file = $pod_search->find($page);
		if ($file) {
			return;
		}
		
		# The page doesn't exist, mark it as being wrong
		my $markup = Glib::Markup::escape_text($page);
		$markup = qq(<span underline="error" underline_color="red">$markup</span>);
		$entry->set_markup($markup);
		$entry->signal_stop_emission_by_name('changed');
	});
	
	
	# Load a POD page when enter is pressed
	$entry->signal_connect('activate' => sub {
		
		# The POD page to load
		my $page = $entry->get_text;
		if ($page eq "") {
			return;
		}
		
		
		# Find the POD file
		my $content;
		if (my $file = $pod_search->find($page)) {
			
			# Parse the POD file
			my $handle = IO::String->new();
			$pod_parser->parse_from_file($file, $handle);
			$content = ${ $handle->string_ref };
		}
		else {
			$content = "No such POD page: '$page'";
		}
		
		
		# Update the POD text
		my $buffer = $textview->get_buffer;
		$buffer->set_text($content);
		
		
		# Set the text and scroll to the beginning
		$textview->scroll_to_iter($buffer->get_start_iter, 0.0, TRUE, 0.0, 0.0);
	});
	

	# Load a default page
	if (@ARGV) {
		my ($page) = @ARGV;
		$entry->set_text($page);
	}

	
	Gtk2->main();
	
	return 0;
}


# Creates the widgets and returns the main widgets to be used by the
# application.
sub create_widgets {
	my $window = Gtk2::Window->new();
	
	# Search entry field
	my $entry = Gtk2::Ex::Entry::Pango->new();
	
	# Textview where the POD document will be displayed
	my $textview = Gtk2::TextView->new();
	$textview->set_size_request(600, 400);
	$textview->set_editable(FALSE);
	$textview->set_cursor_visible(FALSE);
	
	my $scrolls = Gtk2::ScrolledWindow->new(undef, undef);
	$scrolls->set_policy('automatic', 'always');
	$scrolls->set_shadow_type('out');
	$scrolls->add($textview);
	
	my $label = Gtk2::Label->new("POD Page: ");
	my $button = Gtk2::Button->new("Search");
	
	# Packaging
	my $top_box = Gtk2::HBox->new();
	$top_box->pack_start($label, FALSE, FALSE, 0);
	$top_box->pack_start($entry, TRUE, TRUE, 0);
	$top_box->pack_start($button, FALSE, FALSE, 0);
	
	my $vbox = Gtk2::VBox->new();
	$vbox->pack_start($top_box, FALSE, FALSE, 0);
	$vbox->pack_start($scrolls, TRUE, TRUE, 0);
	
	$window->add($vbox);
	
	$window->signal_connect(delete_event => sub {
		Gtk2->main_quit();
	});
	$button->signal_connect(clicked => sub {
		$entry->signal_emit('activate');
	});
	$button->grab_focus();
	
	$window->show_all();
	
	return ($entry, $textview);
}

