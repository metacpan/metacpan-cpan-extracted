use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Ex::DateRange;

my $daterange = Gtk2::Ex::DateRange->new;
$daterange->set_model([ 'after', '1965-03-12', 'and', 'before', '1989-02-14' ]);
$daterange->signal_connect('changed' =>
	sub {
		print Dumper $daterange->get_model;
	}
);
my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });


my $vbox = Gtk2::VBox->new (FALSE);
$vbox->pack_start ($daterange->{widget}, FALSE, FALSE, 0); 	
$vbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0); 

my $hbox = Gtk2::HBox->new (FALSE);
$hbox->pack_start ($vbox, FALSE, FALSE, 0); 	
$hbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0); 

$window->add($hbox);

$window->set_default_size(300, 400);
$window->show_all;
Gtk2->main;

