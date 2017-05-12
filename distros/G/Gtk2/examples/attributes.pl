#!/usr/bin/perl
use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;

my $window = Gtk2::Window->new;
my $box = Gtk2::VBox->new;

my @labels = (
  ["Light, Oblique" => ['light',  'oblique']],
  ["Normal, Normal" => ['normal', 'normal']],
  ["Bold, Italic"   => ['bold',   'italic']],
);

foreach (@labels) {
  my ($string, $attrs) = @{$_};
  my ($weight, $style) = @{$attrs};

  my $list = Gtk2::Pango::AttrList->new;

  $list->insert (
    Gtk2::Pango::AttrWeight->new ($weight, 0, length $string));
  $list->insert (
    Gtk2::Pango::AttrStyle->new ($style, 0, length $string));

  my $label = Gtk2::Label->new ($string);
  $label->set_attributes ($list);

  $box->add ($label);
}

$window->add ($box);
$window->show_all;
$window->signal_connect(delete_event => sub { Gtk2->main_quit; });

Gtk2->main;
