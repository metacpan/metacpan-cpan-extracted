#!perl

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::Phat;

my $window = Gtk2::Window->new;
$window->set_title('Keyboard Demo');
$window->set_border_width(12);
$window->set_position('center');
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });

my $main_hbox = Gtk2::HBox->new(FALSE, 12);
$window->add($main_hbox);
$main_hbox->show;

my $hbox = Gtk2::HBox->new(FALSE, 3);
$main_hbox->pack_start($hbox, FALSE, FALSE, 0);
$hbox->show;

my $mega_label = Gtk2::Label->new('Press a Key');

my $adj = Gtk2::Adjustment->new(0, 0, 0, 0, 0, 0);
my $keyboard = Gtk2::Phat::VKeyboard->new($adj, 128, TRUE);
$hbox->pack_start($keyboard, FALSE, FALSE, 0);
$keyboard->show;

$keyboard->signal_connect('key-pressed'  => \&pressed, $mega_label);
$keyboard->signal_connect('key-released' => \&released, $mega_label);

my $scroll = Gtk2::VScrollbar->new($adj);
$hbox->pack_start($scroll, FALSE, FALSE, 0);
$scroll->show;

my $vbox = Gtk2::VBox->new(FALSE, 3);
$main_hbox->pack_start($vbox, TRUE, TRUE, 0);
$vbox->show;

$adj = Gtk2::Adjustment->new(0, 0, 0, 0, 0, 0);
$keyboard = Gtk2::Phat::HKeyboard->new($adj, 128, TRUE);
$vbox->pack_start($keyboard, FALSE, FALSE, 0);
$keyboard->show;

$keyboard->signal_connect('key-pressed'  => \&pressed, $mega_label);
$keyboard->signal_connect('key-released' => \&released, $mega_label);

$scroll = Gtk2::HScrollbar->new($adj);
$vbox->pack_start($scroll, FALSE, FALSE, 0);
$scroll->show;

$vbox->pack_start($mega_label, TRUE, TRUE, 18);
$mega_label->show;

$window->show;

Gtk2->main;

sub pressed {
    my ($widget, $key, $label) = @_;

    $label->set_text("Key Pressed: $key");
}

sub released {
    my ($widget, $key, $label) = @_;

    $label->set_text("Key Released: $key");
}
