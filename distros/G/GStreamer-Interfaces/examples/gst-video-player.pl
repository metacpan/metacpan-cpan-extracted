#!/usr/bin/perl

=head1 NAME

gst-video-player.pl - Video player made in Perl

=head1 SYNOPSIS

gst-video-player.pl video

Where I<video> is the path to a video file or an URI to a video.

Play a video that's available locally:

	perl gst-video-player.pl film.ogv

Stream a video from a website:

	perl gst-video-player.pl http://anon.nasa-global.edgesuite.net/qt.nasa-global/ksc/ksc_071509_sts127_launch_480i.mov

=head1 DESCRIPTION

This program shows how to create a video player using Gtk2 and GStreamer. This
player can handle all video formats supported by GStreamer.

The original Vala code from http://live.gnome.org/Vala/GStreamerSample was ported to Perl and adjusted to play arbitrary video files.

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE filename_to_uri);
use GStreamer '-init';
use GStreamer::Interfaces;
use Gtk2 '-init';
use File::Spec;
use Cwd;

exit main();


sub main {
	die "Usage: file\n" unless @ARGV;
	my ($uri) = @ARGV;
	
	if ($uri =~ m,^[^:]+://,) {
		# Nothing to do as the input is already an URI
	}
	elsif (! File::Spec->file_name_is_absolute($uri)) {
		my $file = File::Spec->catfile(getcwd(), $uri);
		$uri = filename_to_uri($file, undef);
	}
	else {
		$uri = filename_to_uri($uri, undef);
	}
	
	# Create the main pipeline and GUI elements
	my ($pipeline, $player, $sink) = create_pipeline();
	my ($window, $canvas, $buttons) = create_widgets();

	$player->set(uri => $uri);

	# Buttons used to control the playback
	add_button($buttons, 'gtk-media-play', sub {
		$sink->set_xwindow_id($canvas->window->get_xid);
		$pipeline->set_state('playing');
	});

	add_button($buttons, 'gtk-media-stop', sub {
		$pipeline->set_state('ready');
	});


	# Run the program
	Gtk2->main();

	# Cleanup
	$pipeline->set_state('null');
	return 0;
}


sub create_pipeline {
	my $pipeline = GStreamer::Pipeline->new('pipeline');

	# The pipeline elements
	my ($player, $sink) = GStreamer::ElementFactory->make(
		playbin     => 'player',
		xvimagesink => 'sink',
	);

	$pipeline->add($player);
	$player->link($sink);

	$player->set('video-sink', $sink);
	$sink->set('force-aspect-ratio', TRUE);

	return ($pipeline, $player, $sink);
}


sub create_widgets {
	# Create the widgets
	my $window = Gtk2::Window->new();
	$window->set_title("Gst video test");

	# This is where the video will be displayed
	my $canvas = Gtk2::DrawingArea->new();
	$canvas->set_size_request(300, 150);

	my $vbox = Gtk2::VBox->new(FALSE, 0);
	$vbox->pack_start($canvas, TRUE, TRUE, 0);

	# Prepare a box that will hold the playback controls
	my $buttons = Gtk2::HButtonBox->new();
	$vbox->pack_start($buttons, FALSE, TRUE, 0);

	$window->add($vbox);

	$window->signal_connect(delete_event => sub {
		Gtk2->main_quit();
		return Glib::SOURCE_CONTINUE;
	});

	$window->show_all();

	return ($window, $canvas, $buttons);
}


sub add_button {
	my ($box, $stock, $callback) = @_;
	my $button = Gtk2::Button->new_from_stock($stock);
	$button->signal_connect(clicked => $callback);
	$box->add($button);
	$button->show_all();
}
