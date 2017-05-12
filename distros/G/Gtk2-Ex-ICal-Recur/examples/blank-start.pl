use strict;
use warnings;
use Gtk2 '-init';
use Gtk2::Ex::ICal::Recur;
use Gtk2::Ex::Simple::Menu;
use Gtk2::Ex::Simple::List;
use Glib qw /TRUE FALSE/;
use Data::Dumper;

my $recur = Gtk2::Ex::ICal::Recur->new;

my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

my $vbox = Gtk2::VBox->new(FALSE);
my $hbox = Gtk2::HBox->new(FALSE);
my $preview = Gtk2::Button->new_from_stock('gtk-preview');
$preview->signal_connect('clicked' => 
	sub {
		$recur->update_preview;		
	}
);

my $done = Gtk2::Button->new_from_stock('gtk-done');
$done->signal_connect('clicked' => 
	sub {
		print Dumper $recur->get_model;
	}
);

$hbox->pack_start(Gtk2::Label->new, TRUE, TRUE, 0);
$hbox->pack_start($preview, TRUE, TRUE, 0);
$hbox->pack_start($done, TRUE, TRUE, 0);
$hbox->pack_start(Gtk2::Label->new, TRUE, TRUE, 0);
$vbox->pack_start($recur->{widget}, TRUE, TRUE, 0);
$vbox->pack_start($hbox, FALSE, FALSE, 5);

$window->add($vbox);
$window->set_default_size(700,350);
$window->show_all;

Gtk2->main;
