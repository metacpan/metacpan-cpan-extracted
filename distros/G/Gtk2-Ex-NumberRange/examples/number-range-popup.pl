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
		print Dumper my $model = $numberrange->get_model;
		my $sql_condition = $numberrange->to_sql_condition('mynumber', $model);
		print "$sql_condition\n" if $sql_condition;
	}
);

my $label = Gtk2::Label->new('Click-Here');
my $labelbox = _add_button_press($label);
my $popup = $numberrange->attach_popup_to($label);
$labelbox->signal_connect('button-press-event' => 
	sub {
		$popup->show;
		return TRUE; # Very Important...
		             # If you don't return true, then the popup will get closed
	}
);
my $window = Gtk2::Window->new;
$window->signal_connect('destroy' => sub { Gtk2->main_quit });
my $hbox = Gtk2::HBox->new (FALSE);
$hbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0); 
$hbox->pack_start ($labelbox, TRUE, TRUE, 0); 
$hbox->pack_start (Gtk2::Label->new('Outside Label'), TRUE, TRUE, 0); 

my $vbox = Gtk2::VBox->new (FALSE);
$vbox->pack_start ($hbox, FALSE, FALSE, 0); 	
$vbox->pack_start (Gtk2::Label->new, TRUE, TRUE, 0); 

$window->add($vbox);
$window->show_all;
Gtk2->main;

sub _add_button_press {
	my ($widget) = @_;
	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add ($widget);
	$eventbox->add_events (['button-press-mask']);
	return $eventbox;
}
