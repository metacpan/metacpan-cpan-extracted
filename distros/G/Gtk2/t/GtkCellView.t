#!/usr/bin/perl
#
# $Id$
#

#########################
# GtkCellView Tests
# 	- rm
#########################

#########################

use strict;
use warnings;

use Gtk2::TestHelper tests => 12,
    at_least_version => [2, 6, 0, "GtkCellView is new in 2.6"],
    ;

use constant PIXBUF => 0;
use constant STRING => 1;
use constant BOOLEAN => 2;

my $win = Gtk2::Window->new;

isa_ok (my $cview = Gtk2::CellView->new, 'Gtk2::CellView',
	'Gtk2::CellView->new');

ginterfaces_ok($cview);

isa_ok ($cview = Gtk2::CellView->new_with_text ('text'), 'Gtk2::CellView',
	'Gtk2::CellView->new_with_text');

isa_ok ($cview = Gtk2::CellView->new_with_markup ('markup'), 
	'Gtk2::CellView', 'Gtk2::CellView->new_with_markup');

isa_ok ($cview = Gtk2::CellView->new_with_pixbuf 
			($win->render_icon ('gtk-ok', 'dialog')),
	'Gtk2::CellView', 'Gtk2::CellView->new_with_pixbuf');

my $model = create_store ();
fill_store ($model, get_pixbufs ($win));

ok (eval { $cview->set_model (undef);
           $cview->set_model ($model);
           1; },
    '$cview->set_model');

SKIP: {
	skip 'new 2.16 stuff', 2
		unless Gtk2->CHECK_VERSION(2, 16, 0);

	$cview->set_model (undef);
	is($cview->get_model(), undef, '$cview->get_model with undef');

	$cview->set_model ($model);
	is($cview->get_model(), $model, '$cview->get_model');
}

my $treepath = Gtk2::TreePath->new_from_string ('0');
$cview->set_displayed_row ($treepath);
is ($cview->get_displayed_row->to_string, $treepath->to_string,
    '$cview->set|get_displaed_row');

isa_ok ($cview->get_size_of_row ($treepath), 'Gtk2::Requisition');

ok (eval { $cview->set_background_color (Gtk2::Gdk::Color->new (0, 0, 0)); 1; },
    '$cview->set_background_color');

isa_ok ($cview->get_cell_renderers, 'Gtk2::CellRendererPixbuf', 
	'$cview->get_cell_renderers');

my $renderer = ($cview->get_cell_renderers)[0];

sub create_store
{
	my $store = Gtk2::ListStore->new (qw/Gtk2::Gdk::Pixbuf Glib::String 
					     Glib::Boolean/);
	return $store;
}

sub get_pixbufs
{
	my $win = shift;

	my @pbs;

	foreach (qw/gtk-stock-dialog-warning gtk-stock-stop gtk-stock-new/)
	{
		push @pbs, $win->render_icon ($_, 'dialog');
	}

	return \@pbs;
}

sub fill_store
{
	my $store = shift;
	my $pbs = shift;

	foreach (qw/one two three four five six seven eight nine uno dos 
		    tres quatro cinco/)
	{
		my $iter = $store->append;
		$store->set ($iter, 
			     STRING, "$_",
			     PIXBUF, $pbs->[rand (@$pbs)],
			     BOOLEAN, rand (2),
		     );
	}
}
