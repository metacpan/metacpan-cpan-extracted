#!/usr/bin/env perl

use Test::Most tests => 1;

use Renard::Incunabula::Common::Setup;
use Gtk3 -init;
use Intertangle::API::Gtk3::WindowID;

subtest "Get window ID" => fun() {
	my $w = Gtk3::Window->new;
	$w->show;
	my $id = Intertangle::API::Gtk3::WindowID->get_widget_id( $w );
	ok $id, "Got window ID: $id";

	my $a_w = Gtk3::Window->new;
	$a_w->show;
	my $a_id = Intertangle::API::Gtk3::WindowID->get_widget_id( $a_w );
	ok $a_id, "Second window ID: $a_id";
};

done_testing;
