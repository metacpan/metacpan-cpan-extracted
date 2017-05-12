use strict;
use warnings;
use Glib qw(TRUE FALSE);
use Gtk2 qw/-init/;
use Gtk2::Ex::ComboBox;
use Gtk2::Ex::Simple::List;
use Data::Dumper;

use Gtk2::TestHelper tests => 7;

my $window = Gtk2::Window->new;
$window->signal_connect('destroy', sub {Gtk2->main_quit;});

my $label = Gtk2::Label->new('With-Buttons');
my $hbox = Gtk2::HBox->new (FALSE, 10);
$hbox->pack_start ($label, FALSE, TRUE, 0);    

my $combobox = Gtk2::Ex::ComboBox->new($label, 'with-checkbox');
isa_ok($combobox, "Gtk2::Ex::ComboBox");
ok(!$combobox->set_list_preselected([[0,'this'], [1,'that'], [1,'what']]));

my $slist = $combobox->get_treeview;
isa_ok($slist, "Gtk2::Ex::Simple::List");

my $selected_indices = $combobox->get_selected_indices;
is(Dumper($selected_indices->{'selected-indices'}), Dumper([1,2]));
is(Dumper($selected_indices->{'unselected-indices'}), Dumper([0]));

my $selected_values = $combobox->get_selected_values;
is(Dumper($selected_values->{'selected-values'}), Dumper(['that', 'what']));
is(Dumper($selected_values->{'unselected-values'}), Dumper(['this']));

my $text = Gtk2::TextView->new;

my $vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->pack_start ($hbox, FALSE, TRUE, 0);
$vbox->pack_start ($text, TRUE, TRUE, 0);
$window->add ($vbox);
$window->set_default_size(500, 200);
$window->show_all;

$combobox->show;