use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init/;
use Gtk2::Ex::ComboBox;
use Data::Dumper;

my $window = Gtk2::Window->new;
$window->signal_connect('destroy', sub {Gtk2->main_quit;});

my $label1 = Gtk2::Label->new('With-Buttons');
my $eventbox1 = add_arrow($label1);

my $label2 = Gtk2::Label->new('With-CheckBox');
my $eventbox2 = add_arrow($label2);

my $label3 = Gtk2::Label->new('No-CheckBox');
my $eventbox3 = add_arrow($label3);

my $hbox = Gtk2::HBox->new (FALSE, 10);
$hbox->pack_start (Gtk2::Label->new('One'), FALSE, TRUE, 0);    
$hbox->pack_start ($eventbox1, FALSE, TRUE, 0);    
$hbox->pack_start ($eventbox2, FALSE, TRUE, 0);    
$hbox->pack_start ($eventbox3, FALSE, TRUE, 0);    
$hbox->pack_start (Gtk2::Label->new('Three'), FALSE, TRUE, 0);    
$hbox->pack_start (Gtk2::Label->new('Four'), FALSE, TRUE, 0);    
$hbox->pack_start (Gtk2::Label->new('Five'), FALSE, TRUE, 0);    
$hbox->pack_start (Gtk2::Label->new('Six'), FALSE, TRUE, 0);    

my $combobox1 = Gtk2::Ex::ComboBox->new($label1, 'with-buttons');
$combobox1->set_list(['this', 'that', 'what']);
$combobox1->signal_connect('changed' => 
	sub {
		print "combobox1 selection changed\n";
	}
);
my $combobox2 = Gtk2::Ex::ComboBox->new($label2, 'with-checkbox');
$combobox2->set_list_preselected([[0,'how'], [1,'when'], [1,'where']]);
$combobox2->signal_connect('changed' => 
	sub {
		print "combobox2 selection changed\n";
	}
);

my $combobox3 = Gtk2::Ex::ComboBox->new($label3, 'no-checkbox');
$combobox3->set_list_preselected([[1,'how'], [0,'when'], [1,'where']]);
$combobox3->signal_connect('changed' => 
	sub {
		print "combobox3 selection changed\n";
	}
);

my $text = Gtk2::TextView->new;
my $dumpbutton = Gtk2::Button->new('Show Details');
my $vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->pack_start ($hbox, FALSE, TRUE, 0);
$vbox->pack_start ($text, TRUE, TRUE, 0);
$vbox->pack_start ($dumpbutton, FALSE, TRUE, 0);
$window->add ($vbox);

$eventbox1->signal_connect('button-release-event' => sub { $combobox1->show; } );
$eventbox2->signal_connect('button-release-event' => sub { $combobox2->show; } );
$eventbox3->signal_connect('button-release-event' => sub { $combobox3->show; } );
$dumpbutton->signal_connect('button-release-event' => 
	sub {
		print Dumper $combobox1->get_selected_values;
		print Dumper $combobox2->get_selected_values;
		print Dumper $combobox3->get_selected_values;
		print Dumper $combobox1->get_selected_indices;
		print Dumper $combobox2->get_selected_indices;
		print Dumper $combobox3->get_selected_indices;
	}
);

$window->set_default_size(500, 200);
$window->show_all;

Gtk2->main;

sub add_arrow {
	my ($label) = @_;
	my $arrow = Gtk2::Arrow -> new('down', 'none');
	my $labelbox = Gtk2::HBox->new (FALSE, 0);
	$labelbox->pack_start ($label, FALSE, FALSE, 0);    
	$labelbox->pack_start ($arrow, FALSE, FALSE, 0);    
	my $eventbox = Gtk2::EventBox->new;
	$eventbox->add ($labelbox);
	return $eventbox;
}