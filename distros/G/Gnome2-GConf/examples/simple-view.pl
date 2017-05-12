#!/usr/bin/perl
# Copyright (C) 1999, 2000 Red Hat Inc.
# Copyright (C) 2003 Emmanuele Bassi <emmanuele.bassi@iol.it>

# A very simple program that monitors a single key for changes.

use strict;
use warnings;

use Gtk2;
use Gnome2::GConf;

Gtk2->init;

my $client = Gnome2::GConf::Client->get_default;
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect(delete_event => sub { $_[0]->destroy;  });
$window->signal_connect(destroy      => sub { Gtk2->main_quit; });

my $str = $client->get_string("/extra/test/directory/key");

my $label = Gtk2::Label->new($str ? $str : "<unset>");

$window->add($label);
	
$client->add_dir("/extra/test/directory", 'preload-none');
$client->notify_add("/extra/test/directory/key", sub {
		my ($client, $cnxn_id, $entry, $label) = @_;
		
		if    (not ($entry->{value}))
		{
			$label->set_text('<undef>');
		}
		elsif ($entry->{value}->{type} eq 'string')
		{
			$label->set_text($entry->{value}->{value});
		}
		else
		{
			$label->set_text('<wrong type>');
			}
	}, $label);

$window->show_all;

Gtk2->main;

0;
