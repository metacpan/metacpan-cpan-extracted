#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use Gtk2::Notify -init, 'Images';

my $n = Gtk2::Notify->new('Icon Test', 'Testing stock icon', 'stock_samples');
$n->show;

my $uri = 'file://'. $Bin .'/applet-critical.png';
print "Sending $uri\n";

$n = Gtk2::Notify->new('Alert!', 'Testing URI icons', $uri);
$n->show;

$n = Gtk2::Notify->new('Raw image test', 'Testing sending raw pixbufs');

my $button = Gtk2::Button->new;
my $icon = $button->render_icon('gtk-ok', 'dialog');
$n->set_icon_from_pixbuf($icon);

$n->show;

