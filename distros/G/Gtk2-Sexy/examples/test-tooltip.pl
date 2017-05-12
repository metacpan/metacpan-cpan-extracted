#!/usr/bin/perl

use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Sexy;

my $tooltip = Gtk2::Sexy::Tooltip->new;

my $hbox = Gtk2::HBox->new(6, TRUE);
$hbox->show;
$tooltip->add($hbox);

my $image = Gtk2::Image->new_from_stock('gtk-dialog-authentication', 'dialog');
$image->show;
$hbox->pack_start($image, FALSE, TRUE, 0);

my $label = Gtk2::Label->new;
$label->set_markup( "<span size=\"large\" weight=\"bold\">Text</span>" );
$label->show;
$hbox->pack_start($label, TRUE, TRUE, 0);

$tooltip->show;

Gtk2->main;
