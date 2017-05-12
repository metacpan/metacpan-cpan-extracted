#!/usr/bin/perl -w

# A simple, contrived example of dealing with a TreeView/ListStore in
# multiple selection mode.

use Glib qw(TRUE);
use Gtk2 -init;

use constant STRING_COLUMN => 0;

sub fill_store {
	my $store = Gtk2::ListStore->new ('Glib::String');

	for ($i = 0 ; $i < 50 ; $i+=5) {
		my $iter = $store->append;
		$store->set ($iter, 0 => "$i");
	}

	return $store;
}


my $window = Gtk2::Window->new;
$window->set_size_request (150, 300);
$window->set_border_width (6);
$window->signal_connect (delete_event => sub { Gtk2->main_quit; TRUE });
my $vbox = Gtk2::VBox->new;
$window->add ($vbox);
my $sw = Gtk2::ScrolledWindow->new;
$sw->set_shadow_type ('etched-in');
$sw->set_policy ('automatic', 'automatic');
$vbox->pack_start ($sw, TRUE, TRUE, 0);


my $model = fill_store ();
my $tree_view = Gtk2::TreeView->new_with_model ($model);

$tree_view->set_reorderable (TRUE);
$model->signal_connect (rows_reordered => sub {print "rows reordered\n"});
$tree_view->get_selection->set_mode ('multiple');
$tree_view->get_selection->signal_connect (changed => sub {
	my @sel = $_[0]->get_selected_rows;
	print "changed "
	    . "[".$_[0]->count_selected_rows."] "
	    . "[".scalar(@sel)."] "
	    . join(",", map { $_->to_string } @sel)
	    . "\n"
});

$sw->add ($tree_view);

my $renderer = Gtk2::CellRendererText->new;
my $column = Gtk2::TreeViewColumn->new_with_attributes ("Some numbers", 
							$renderer, 
							text => 0);
$tree_view->append_column ($column);

$window->show_all;

Gtk2->main;


