#!/usr/bin/perl

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Sexy;

my $window = Gtk2::Window->new();
$window->show();
$window->set_title('Sexy Spell Entry Test');
$window->set_border_width(12);

$window->signal_connect('destroy' => sub { Gtk2->main_quit });

my $hbox = Gtk2::HBox->new(FALSE, 6);
$hbox->show();
$window->add($hbox);

my $label = Gtk2::Label->new('Text:');
$label->show();
$hbox->pack_start($label, FALSE, FALSE, 0);

my $entry = Gtk2::Sexy::SpellEntry->new();
$entry->show();
$hbox->pack_start($entry, TRUE, TRUE, 0);

$entry->set_text('Hello World');

Gtk2->main;
