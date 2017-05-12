#!perl

use strict;
use warnings;
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::Phat;

my $window = Gtk2::Window->new;
$window->set_title('Fanslider Demo');
$window->set_border_width(5);
$window->set_position('center');
$window->signal_connect('delete-event' => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new(FALSE, 5);
$window->add($vbox);
$vbox->show;

my $adj = Gtk2::Adjustment->new(0, -1, 1, 0.01, 0.1, 0);
my $slider = Gtk2::Phat::HFanSlider->new($adj);
$vbox->pack_start($slider, TRUE, TRUE, 0);
$slider->show;

my $hbox = Gtk2::HBox->new(FALSE, 5);
$vbox->pack_start($hbox, TRUE, TRUE, 0);
$hbox->show;

my $label = Gtk2::Label->new('Value:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

my $spin = Gtk2::SpinButton->new($adj, 0, 2);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

$label = Gtk2::Label->new('Lower:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

my $spin_adj = Gtk2::Adjustment->new(-1, -5, 0, 0.01, 0, 0);
$spin_adj->signal_connect('value-changed' => \&cb_lower, $adj);
$spin = Gtk2::SpinButton->new($spin_adj, 0, 2);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

$label = Gtk2::Label->new('Upper:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

$spin_adj = Gtk2::Adjustment->new(1, 0, 5, 0.01, 0, 0);
$spin_adj->signal_connect('value-changed' => \&cb_upper, $adj);
$spin = Gtk2::SpinButton->new($spin_adj, 0, 2);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

my $check = Gtk2::CheckButton->new_with_label('Inverted');
$check->signal_connect('toggled' => \&cb_inverted, $slider);
$hbox->pack_start($check, TRUE, TRUE, 0);
$check->show;

$check = Gtk2::CheckButton->new_with_label('Sensitive');
$check->set_active(TRUE);
$check->signal_connect('toggled' => \&cb_sensitive, $slider);
$hbox->pack_start($check, TRUE, TRUE, 0);
$check->show;

$adj = Gtk2::Adjustment->new(0, -1, 1, 0.01, 0.1, 0);
$slider = Gtk2::Phat::VFanSlider->new($adj);
$vbox->pack_start($slider, TRUE, TRUE, 0);
$slider->show;

$hbox = Gtk2::HBox->new(FALSE, 5);
$vbox->pack_start($hbox, TRUE, TRUE, 0);
$hbox->show;

$label = Gtk2::Label->new('Value:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

$spin = Gtk2::SpinButton->new($adj, 0, 2);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

$label = Gtk2::Label->new('Lower:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

$spin_adj = Gtk2::Adjustment->new(-1, -5, 0, 0.01, 0, 0);
$spin_adj->signal_connect('value-changed' => \&cb_lower, $adj);
$spin = Gtk2::SpinButton->new($spin_adj, 0, 2);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

$label = Gtk2::Label->new('Upper:');
$hbox->pack_start($label, TRUE, TRUE, 0);
$label->show;

$spin_adj = Gtk2::Adjustment->new(1, 0, 5, 0.01, 0, 0);
$spin_adj->signal_connect('value-changed' => \&cb_upper, $adj);
$spin = Gtk2::SpinButton->new($spin_adj, 0, 2);
$hbox->pack_start($spin, TRUE, TRUE, 0);
$spin->show;

$check = Gtk2::CheckButton->new_with_label('Inverted');
$check->signal_connect('toggled' => \&cb_inverted, $slider);
$hbox->pack_start($check, TRUE, TRUE, 0);
$check->show;

$check = Gtk2::CheckButton->new_with_label('Sensitive');
$check->set_active(TRUE);
$check->signal_connect('toggled' => \&cb_sensitive, $slider);
$hbox->pack_start($check, TRUE, TRUE, 0);
$check->show;

$window->show;

Gtk2->main;

sub cb_inverted {
    my ($check, $slider) = @_;

    $slider->set_inverted($check->get_active);
}

sub cb_sensitive {
    my ($check, $slider) = @_;

    $slider->set_sensitive($check->get_active);
}

sub cb_lower {
    my ($lower, $slider) = @_;

    if ($lower->value >= $slider->upper) {
        $lower->set_value($slider->upper - 0.01);
        return;
    }

    if ($lower->value > $slider->value) {
        $lower->set_value($slider->value);
        return;
    }

    $slider->lower($lower->value);
    $slider->changed;
}

sub cb_upper {
    my ($upper, $slider) = @_;

    if ($upper->value <= $slider->lower) {
        $upper->set_value($slider->lower - 0.01);
        return;
    }

    if ($upper->value < $slider->value) {
        $upper->set_value($slider->value);
        return;
    }

    $slider->upper($upper->value);
    $slider->changed;
}
