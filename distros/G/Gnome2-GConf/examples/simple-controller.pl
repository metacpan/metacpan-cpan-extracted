#!/usr/bin/perl
# Copyright (C) 1999, 2000 Red Hat Inc.
# Copyright (C) 2003 Emmanuele Bassi <emmanuele.bassi@iol.it>

# A very simple program that sets a single key value when you type
# it in an entry and press return

use strict;
use warnings;

use Gtk2;
use Gnome2::GConf;

Gtk2->init;

my $window = Gtk2::Window->new('toplevel');
$window->signal_connect(delete_event => sub { $_[0]->destroy;  });
$window->signal_connect(destroy      => sub { Gtk2->main_quit; });

my $entry = Gtk2::Entry->new;

$window->add($entry);

my $client = Gnome2::GConf::Client->get_default;
$client->add_dir("/extra/test/directory", 'preload-none');

$entry->signal_connect(activate => sub {
		my ($entry, $client) = @_;
		my $str = $entry->get_chars(0, -1);

		$client->set_string("/extra/test/directory/key", $str);
	}, $client);

$entry->set_sensitive($client->key_is_writable("/extra/test/directory/key"));

$window->show_all;

Gtk2->main;

0;
