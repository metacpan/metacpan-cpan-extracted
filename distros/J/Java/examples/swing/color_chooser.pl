#!/home/markt/usr/local/Linux/bin/perl -w

use strict;
no strict 'subs';
use lib '../..';
use Java;

my $awt = "java.awt";
my $swing = "javax.swing";

my $java = new Java();

my $win = $java->create_object("$swing.JFrame","Color Chooser, Comma Test!");

my $content_pane = $win->getContentPane;

my $color = $java->javax_swing_JColorChooser("showDialog",$content_pane,"Pick a color",$java->get_field("java.awt.Color","white"));

my $blue = $color->getBlue->get_value;
my $green = $color->getGreen->get_value;
my $red = $color->getRed->get_value;

print "You picked: R: $red G: $green B: $blue\n";
