#!/usr/bin/perl -w

=doc

Gtk2::Table's horizontal and vertical packing options can be a little confusing
at first.  This example gives you a way to get a feel for them interactively.

Hint: resize the window and stretch the hpaned's gutter.

This program also illustrates using container child properties, making a
hpaned's second child sticky, using named colors, vectorization of operations,
and using multiple columns in a combo box model but not in the view.

Originally from the thread "Alignment of labels in table",
http://mail.gnome.org/archives/gtk-perl-list/2005-November/msg00029.html

=cut

use strict;
use Glib qw(:constants);
use Gtk2 -init;

#
# Create a basic window, with a table on the left and some controls on the
# right, separated by a draggable gutter.
#
my $window = Gtk2::Window->new;
$window->signal_connect (destroy => sub {Gtk2->main_quit});
my $hpaned = Gtk2::HPaned->new;
$window->add ($hpaned);
my $table = Gtk2::Table->new (2, 2);
$hpaned->add1 ($table);

my $vbox = Gtk2::VBox->new;
$hpaned->add2 ($vbox);

# Now that we have children in the HPaned, tell it to keep child2 at its
# current size when resizing the window.
$hpaned->child1_resize (TRUE);
$hpaned->child2_resize (FALSE);

# Initialize the model we'll use for all of the combo boxes, below.
my $combo_model = Gtk2::ListStore->new ('Gtk2::AttachOptions', 'Glib::String');
foreach ({name => 'expand', value => ['expand'] },
	 {name => 'fill', value => ['fill'] },
	 {name => 'shrink', value => ['shrink'] },
	 {name => 'expand+fill', value => ['expand', 'fill']}) {
	$combo_model->set ($combo_model->append,
			   0, $_->{value},
			   1, $_->{name});
}

# Set up each cell of the table and its corresponding row of controls.
foreach ([0, 1, 0, 1, "red"],
	 [0, 1, 1, 2, "green"],
	 [1, 2, 0, 1, "blue"],
	 [1, 2, 1, 2, "orange"]) {
	my ($left, $right, $top, $bottom, $color_name) = @$_;
	my $color = Gtk2::Gdk::Color->parse ($color_name);

	my $event_box = Gtk2::EventBox->new;
	my $label = Gtk2::Label->new ("$left $right $top $bottom");
	$event_box->modify_bg (normal => $color);
	$event_box->add ($label);
	$label->show;

	$table->attach_defaults ($event_box, $left, $right, $top, $bottom);

	my $hbox = Gtk2::HBox->new;
	$vbox->pack_start ($hbox, FALSE, FALSE, 0);

	$label = Gtk2::Label->new ("$left $right $top $bottom");
	$label->modify_fg (normal => $color);
	$hbox->pack_start ($label, FALSE, FALSE, 0);

	my $combo_box = Gtk2::ComboBox->new ($combo_model);
	my $cell = Gtk2::CellRendererText->new;
	$combo_box->pack_start ($cell, TRUE);
	$combo_box->add_attribute ($cell, text => 1);
	$combo_box->signal_connect (changed => sub {
		my ($combo_box, $child) = @_;
		my $new_x_options =
			$combo_box->get_model->get
				($combo_box->get_active_iter, 0);
		$table->child_set ($child, x_options => $new_x_options);
	}, $event_box);
	$combo_box->set_active (0);
	$hbox->pack_start ($combo_box, FALSE, FALSE, 0);

	$combo_box = Gtk2::ComboBox->new ($combo_model);
	$cell = Gtk2::CellRendererText->new;
	$combo_box->pack_start ($cell, TRUE);
	$combo_box->add_attribute ($cell, text => 1);
	$combo_box->signal_connect (changed => sub {
		my ($combo_box, $child) = @_;
		my $new_y_options =
			$combo_box->get_model->get
				($combo_box->get_active_iter, 0);
		$table->child_set ($child, y_options => $new_y_options);
	}, $event_box);
	$combo_box->set_active (0);
	$hbox->pack_start ($combo_box, FALSE, FALSE, 0);
}


$window->show_all;
Gtk2->main;

