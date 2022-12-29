#!/usr/bin/env perl

use Test::Most;

use Renard::Incunabula::Common::Setup;
use Intertangle::API::Gtk3;
use Gtk3;

plan Gtk3::init_check
	? ( tests    => 1 )
	: ( skip_all => 'Could not init GTK' );

subtest "Get visual IDs" => fun() {
	my $w = Gtk3::Window->new;
	$w->show_all;
	plan skip_all => "Not on X11" unless $w->get_window =~ /X11Window/;
	require Intertangle::API::Gtk3::GdkX11;
	Intertangle::API::Gtk3::GdkX11->import;

	my $gdk_screen = $w->get_screen;
	my $gdk_visuals = $gdk_screen->list_visuals;
	my $default_xvisual = $gdk_screen->get_xscreen->DefaultVisual;
	my ($default_gdkvisual) = grep { $_->get_xvisual->xvisualid == $default_xvisual->xvisualid } @$gdk_visuals;

	my $visual_id = $default_xvisual->xvisualid;
	is $default_gdkvisual->get_xvisual->xvisualid,
		$visual_id, sprintf("found GdkVisual for the default X11 visual ID: 0x%x", $visual_id);
};

done_testing;
