#!/usr/bin/perl -w

=doc

Contrived example showing off the new ComboBox and Expander in gtk+-2.4.

=cut

use Gtk2 -init;

die "This example requires gtk+ 2.4.0, but Gtk2 has been compiled for "
  . join (".", Gtk2->GET_VERSION_INFO)."\n"
	unless Gtk2->CHECK_VERSION (2, 4, 0);

$window = Gtk2::Window->new;
$window->signal_connect (delete_event => sub { Gtk2->main_quit; 1 });

$expander = Gtk2::Expander->new ('There are Combo Boxes in here!');
$window->add ($expander);

$vbox = Gtk2::VBox->new;
$expander->add ($vbox);

$model = Gtk2::ListStore->new ('Glib::String');
foreach (qw/this is a test of the emergency broadcast system/) {
	$model->set ($model->append, 0, $_);
}

$combo = Gtk2::ComboBoxEntry->new ($model, 0);
$vbox->add ($combo);

$combo = Gtk2::ComboBox->new_text;
foreach (qw/this is a test of the emergency broadcast system/) {
	$combo->append_text ($_);
}
$vbox->add ($combo);

#
# now for something a little more sophisticated:  we'll have a combo that
# lists all the stock ids to do with go/goto, with their icons.
#
$model = Gtk2::ListStore->new ('Glib::String');
foreach (grep /gtk-go/, Gtk2::Stock->list_ids) {
	$model->set ($model->append, 0, $_);
}
$combo = Gtk2::ComboBox->new ($model);
# a ComboBox implements the CellLayout interface; that is, we can pack
# CellRenderers into the ComboBox to control how the items are displayed.
my $renderer = Gtk2::CellRendererPixbuf->new;
$combo->pack_start ($renderer, FALSE);
$combo->set_attributes ($renderer, 'stock-id' => 0);
$renderer = Gtk2::CellRendererText->new;
$combo->pack_start ($renderer, FALSE);
$combo->set_attributes ($renderer, text => 0);
$vbox->add ($combo);


$window->show_all;

Gtk2->main;

