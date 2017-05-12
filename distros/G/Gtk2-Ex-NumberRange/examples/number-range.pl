use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Data::Dumper;
use Gtk2::Ex::NumberRange;

my $numberrange = Gtk2::Ex::NumberRange->new;
$numberrange->set_model(['>', 10, 'and', '<=', 20]);

$numberrange->signal_connect('changed' =>
	sub {
		my $model = $numberrange->get_model;
		print Dumper $model;
		my $sql_condition = $numberrange->to_sql_condition('mynumber', $model);
		print "$sql_condition\n" if $sql_condition;
	}
);
my $clear = Gtk2::Button->new_from_stock('gtk-clear');
my $i = 0;
$clear->signal_connect ('button-release-event' => 
	sub {
		$numberrange->set_model(undef);
	}
);
my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });

my $vbox = Gtk2::VBox->new (FALSE);
$vbox->pack_start ($numberrange->{widget}, FALSE, FALSE, 0); 	
$vbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0); 
$vbox->pack_start ($clear, FALSE, FALSE, 0); 

$window->add($vbox);
$window->set_default_size(300, 400);
$window->show_all;
Gtk2->main;

