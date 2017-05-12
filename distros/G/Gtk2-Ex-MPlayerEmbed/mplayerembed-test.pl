#!/usr/bin/perl
use lib 'lib/';
use Gtk2 -init;
use Gtk2::Ex::MPlayerEmbed;
use strict;

my $embed = Gtk2::Ex::MPlayerEmbed->new;
$embed->set('args', $embed->get('args').' -ao null');

my $window = Gtk2::Window->new;
$window->set_default_size(640, 480);
$window->set_position('center');
$window->set_title('Movie Player');
$window->set_icon_name('gnome-multimedia');
$window->signal_connect('delete_event', sub { Gtk2->main_quit });
$window->add($embed);
$window->show_all;

$embed->play($ARGV[0]);

Gtk2->main;
