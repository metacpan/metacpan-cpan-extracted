#!/usr/bin/perl

#
# $Id$
#

#########################
# GtkIconView Tests
# 	- rm
#########################

#########################

use strict;
use warnings;

use Gtk2::TestHelper tests => 60,
    at_least_version => [2, 6, 0, "GtkIconView is new in 2.6"],
    ;

use constant TEXT => 0;
use constant PIXBUF => 1;
use constant BOOLEAN => 2;

use constant ICON_COORD => 30;

my $win = Gtk2::Window->new;
#my $swin = Gtk2::ScrolledWindow->new;
#$win->add ($swin);

my $model = create_store ();

isa_ok (my $iview = Gtk2::IconView->new, 'Gtk2::IconView',
	'Gtk2::IconView->new');
ginterfaces_ok($iview);

is ($iview->get_model, undef, '$iview->get_model, undef');
$iview->set_model ($model);
is ($iview->get_model, $model, '$iview->set|get_model');

isa_ok ($iview = Gtk2::IconView->new_with_model ($model), 'Gtk2::IconView',
	'Gtk2::IconView->new');
#$swin->add ($iview);
is ($iview->get_model, $model, '$iview->get_model, new_with_model');

fill_store ($model, get_pixbufs ($win));

is ($iview->get_text_column, -1, '$iview->get_text_column, undef');
$iview->set_text_column (TEXT);
is ($iview->get_text_column, TEXT, '$iview->set|get_text_column');

is ($iview->get_pixbuf_column, -1, '$iview->get_pixbuf_column, undef');
$iview->set_pixbuf_column (PIXBUF);
is ($iview->get_pixbuf_column, PIXBUF, '$iview->set|get_pixbuf_column');

is ($iview->get_markup_column, -1, '$iview->get_markup_column, undef');
$iview->set_markup_column (TEXT);
is ($iview->get_markup_column, TEXT, '$iview->set|get_markup_column');

foreach (qw/horizontal vertical/)
{
	$iview->set_orientation ($_);
	is ($iview->get_orientation, $_, '$iview->set|get_orienation, '.$_);
}

# extended should be in this list, but it seems to fail
foreach (qw/none single browse multiple/)
{
	$iview->set_selection_mode ($_);
	is ($iview->get_selection_mode, $_,
	    '$iview->set|get_selection_mode '.$_);
}

$iview->set_columns (23);
is ($iview->get_columns, 23);

$iview->set_item_width (23);
is ($iview->get_item_width, 23);

$iview->set_spacing (23),
is ($iview->get_spacing, 23);

$iview->set_row_spacing (23);
is ($iview->get_row_spacing, 23);

$iview->set_column_spacing (23);
is ($iview->get_column_spacing, 23);

$iview->set_margin (23);
is ($iview->get_margin, 23);

my $path = $iview->get_path_at_pos (ICON_COORD, ICON_COORD);
$path = Gtk2::TreePath->new_first unless defined $path;
isa_ok ($path, 'Gtk2::TreePath');

is ($iview->path_is_selected ($path), '',
    '$iview->path_is_selected, no');
$iview->select_path ($path);
is ($iview->path_is_selected ($path), 1,
    '$iview->path_is_selected, yes');
$iview->unselect_path ($path);
is ($iview->path_is_selected ($path), '',
    '$iview->path_is_selected, no');

$iview->item_activated ($path);

my @sels = $iview->get_selected_items;
is (scalar (@sels), 0, '$iview->get_selected_items, count 0');

$iview->select_all;
@sels = $iview->get_selected_items;
is (scalar (@sels), 14, '$iview->get_selected_items, count 14');
isa_ok ($sels[0], 'Gtk2::TreePath', '$iview->get_selected_items, type');
# make sure it's actually a valid path
ok (defined $sels[0]->to_string);

$iview->unselect_all;
@sels = $iview->get_selected_items;
is (scalar (@sels), 0, '$iview->get_selected_items, count 0');

$iview->select_path ($path);
$iview->selected_foreach (sub {
    my ($view, $path, $data) = @_;
    isa_ok ($view, 'Gtk2::IconView');
    isa_ok ($path, 'Gtk2::TreePath');
    isa_ok ($data, 'HASH');
    is ($data->{foo}, 'bar', 'callback data intact');
}, { foo => 'bar' });
$iview->select_all;
my $ncalls = 0;
$iview->selected_foreach (sub { $ncalls++ });
my @selected_items = $iview->get_selected_items;
is ($ncalls, scalar(@selected_items),
    'called once for each selected child');

SKIP: {
	skip 'new 2.8 stuff', 11
		unless Gtk2->CHECK_VERSION (2, 8, 0);

	# For some reason, get_item_at_pos seems to occasionally run into
	# uninitialized memory when used non-interactively.  So it's not tested
	# here.
	# run_main sub { warn $iview->get_item_at_pos (ICON_COORD, ICON_COORD); };

	my $win = Gtk2::Window->new;
	my $model = create_store ();
	fill_store ($model, get_pixbufs ($win));

	my $iview = Gtk2::IconView->new_with_model ($model);
	$iview->set_text_column (TEXT);
	$iview->set_pixbuf_column (PIXBUF);

	$win->add ($iview);
	$win->show_all;

	my $path = Gtk2::TreePath->new_first;

	# We have no cell renderer to test with, since get_cells() is not
	# available.
	$iview->set_cursor ($path, undef, FALSE);
	my @tmp = $iview->get_cursor;
	is (@tmp, 2);
	isa_ok ($tmp[0], "Gtk2::TreePath");
	is ($tmp[1], undef);

	@tmp = $iview->get_visible_range;
	isa_ok ($tmp[0], "Gtk2::TreePath");
	isa_ok ($tmp[1], "Gtk2::TreePath");

	$iview->scroll_to_path ($path, TRUE, 0.5, 0.5);
	$iview->scroll_to_path ($path);

	$iview->enable_model_drag_source ([qw/shift-mask/], "copy",
	  { target => "STRING", flags => ["same-app", "same-widget"], info => 42 });
	$iview->enable_model_drag_dest ("copy",
	  { target => "STRING", flags => ["same-app", "same-widget"], info => 42 });

	$iview->unset_model_drag_source;
	$iview->unset_model_drag_dest;

	$iview->set_reorderable (TRUE);
	ok ($iview->get_reorderable);

	$iview->set_drag_dest_item ($path, "drop-into");
	@tmp = $iview->get_drag_dest_item;
	isa_ok ($tmp[0], "Gtk2::TreePath");
	is ($tmp[1], "drop-into");

	my ($tmp_path, $pos) = $iview->get_dest_item_at_pos (ICON_COORD, ICON_COORD);
	isa_ok ($tmp_path, "Gtk2::TreePath");
	like ($pos, qr/drop/);

	isa_ok ($iview->create_drag_icon ($path), "Gtk2::Gdk::Pixmap");

	$win->destroy;
}

SKIP: {
	skip 'new 2.12 stuff', 2
		unless Gtk2->CHECK_VERSION (2, 12, 0);

        my $win = Gtk2::Window->new;
	my $model = create_store ();
	fill_store ($model, get_pixbufs ($win));

	my $iview = Gtk2::IconView->new_with_model ($model);

	$iview->set_tooltip_column (TEXT);
	is ($iview->get_tooltip_column, TEXT);

	my ($bx, $by) = $iview->convert_widget_to_bin_window_coords (0, 0);
	is_deeply ([$bx, $by], [0, 0]);
}

SKIP: {
	skip 'new 2.18 stuff', 1
		unless Gtk2->CHECK_VERSION (2, 18, 0);

	my $win = Gtk2::Window->new;
	my $model = create_store ();
	fill_store ($model, get_pixbufs ($win));
	my $iview = Gtk2::IconView->new_with_model ($model);

	$iview->set_item_padding(2);
	is ($iview->get_item_padding, 2, '[gs]et_icon_padding');
}

SKIP: {
	skip 'query-tooltip is hard to test automatically', 5;

        my $win = Gtk2::Window->new;
	$win->set (tooltip_markup => "<b>Bla!</b>");

	my $model = create_store ();
	fill_store ($model, get_pixbufs ($win));

	my $iview = Gtk2::IconView->new_with_model ($model);

	my $path = Gtk2::TreePath->new_first;
	my $cell = ($iview->get_cells)[PIXBUF];

	my $handler_called = 0;
	$win->signal_connect (query_tooltip => sub {
		my ($window, $x, $y, $keyboard_mode, $tip) = @_;

		return TRUE if $handler_called++;

		$iview->set_tooltip_item ($tip, $path);
		$iview->set_tooltip_cell ($tip, $path, $cell);

		my ($bx, $by, $model, $tpath, $iter) =
			$iview->get_tooltip_context ($x, $y, $keyboard_mode);
		is ($bx, 0);
		is ($by, 0);
		isa_ok ($model, 'Gtk2::TreeModel');
		isa_ok ($tpath, 'Gtk2::TreePath');
		isa_ok ($iter, 'Gtk2::TreeIter');

		Glib::Idle->add (sub { Gtk2->main_quit; });

		return TRUE;
	});

	$win->add ($iview);
	$win->show_all;

	my $event = Gtk2::Gdk::Event->new ('motion-notify');
	$event->window ($win->window);
	Gtk2->main_do_event ($event);

	Gtk2->main;

	$win->destroy;
}

SKIP: {
	skip 'new 2.22 stuff', 3
		unless Gtk2->CHECK_VERSION (2, 22, 0);

	my $win = Gtk2::Window->new;
	my $model = create_store ();
	fill_store ($model, get_pixbufs ($win));
	my $iview = Gtk2::IconView->new_with_model ($model);
	my $path = Gtk2::TreePath->new_first;

	ok (defined $iview->get_item_column ($path));
	ok (defined $iview->get_item_row ($path));

	$iview->set_item_orientation ('vertical');
	is ($iview->get_item_orientation, 'vertical');
}

sub create_store
{
	my $store = Gtk2::ListStore->new (qw/Glib::String Gtk2::Gdk::Pixbuf
					     Glib::Boolean/);
	return $store;
}

sub get_pixbufs
{
	my $win = shift;

	my @pbs;

	foreach (qw/gtk-ok gtk-cancel gtk-about gtk-quit/)
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
			     TEXT, "$_",
			     PIXBUF, $pbs->[rand (@$pbs)],
			     BOOLEAN, rand (2),
		     );
	}
}
