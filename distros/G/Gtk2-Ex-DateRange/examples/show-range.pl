use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Ex::DateRange;

my $daterange = Gtk2::Ex::DateRange->new;
$daterange->signal_connect('changed' =>
	sub {
		my $model = $daterange->get_model;
		print Dumper $model;
		my $sql_condition = $daterange->to_sql_condition('mydate', $model);
		print "$sql_condition\n" if $sql_condition;
	}
);
my $clear = Gtk2::Button->new_from_stock('gtk-clear');
$clear->signal_connect ('button-release-event' => 
	sub {
		$daterange->set_model(undef);
	}
);
my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (FALSE);
$vbox->pack_start ($daterange->{widget}, FALSE, FALSE, 0); 	
$vbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0); 
$vbox->pack_start ($clear, FALSE, FALSE, 0); 

$window->add($vbox);
$window->set_default_size(300, 400);
$window->show_all;
Gtk2->main;

