#!perl

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::Phat;

my $window = Gtk2::Window->new;
$window->set_title('SliderButton Demo');
$window->set_border_width(5);
$window->set_position('center');
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new(FALSE, 5);
$window->add($vbox);
$vbox->show;

my $button = Gtk2::Phat::SliderButton->new_with_range(0, -50, 50, 0.25, 2);
$button->set_format(-1, 'Value: ', ' frobs');
$button->set_threshold(10);
$vbox->pack_start($button, TRUE, FALSE, 0);
$button->show;

my $hbox = Gtk2::HBox->new(FALSE, 5);
$vbox->pack_start($hbox, TRUE, TRUE, 0);
$hbox->show;

my $label = Gtk2::Label->new('Threshold:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

my $spin = Gtk2::SpinButton->new_with_range(1, 100, 1);
$spin->set_value(10);
$spin->signal_connect('value-changed' => \&cb_threshold, $button);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

my $check = Gtk2::CheckButton->new_with_label('Sensitive');
$check->set_active(TRUE);
$check->signal_connect('toggled' => \&cb_sensitive, $button);
$hbox->pack_start($check, TRUE, FALSE, 0);
$check->show;

$window->show;

Gtk2->main;

sub cb_threshold {
    my ($spin, $button) = @_;

    $button->set_threshold($spin->get_value_as_int);
}

sub cb_sensitive {
    my ($check, $button) = @_;

    $button->set_sensitive($check->get_active);
}
