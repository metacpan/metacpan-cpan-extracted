#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 5,
	skip_all => 'this test is interactive';
use Data::Dumper;

my $win = Gtk2::Window->new;

my $model = Gtk2::TreeStore->new (qw/Glib::String/);

my $iter;
foreach (qw/one two three four five/)
{
	$iter = $model->append (undef);
	$model->set ($iter, 0 => $_);
}

my $view = Gtk2::TreeView->new ($model);

$view->append_column (Gtk2::TreeViewColumn->new_with_attributes (
	'title', Gtk2::CellRendererText->new, text => 0,
));

#my $pixmap = $view->create_row_drag_icon (Gtk2::TreePath->new ("0:0"));
#isa_ok ($pixmap, '', 'create_row_drag_icon');

$view->enable_model_drag_source (['button1-mask'], ['copy'], ['example', ['same-app'], 0]);
$view->enable_model_drag_dest (['copy'], ['example', ['same-app'], 0]);

$view->signal_connect (drag_data_received => sub {
		print Dumper (@_);
		my ($self, $context, $x, $y, 
		    $selection, $info, $time) = @_;

		my ($path, $pos) = $view->get_dest_row_at_pos ($x, $y);
		my $target = $model->get_iter ($path);

		my ($dpath, $dpos) = $view->get_drag_dest_row;
		is ($dpath, undef, 'get_drag_dest_row, path, empty');
		ok (($dpos =~ /after|before/), 'get_drag_dest_row, pos');

		$view->set_drag_dest_row ($path, $pos);
		($dpath, $dpos) = $view->get_drag_dest_row;
		isa_ok ($dpath, 'Gtk2::TreePath', 
			'set_drag_dest_row, path, filled');
		ok (($dpos =~ /after|before/), 'set_drag_dest_row, pos');

		$view->unset_rows_drag_dest;
		$view->unset_rows_drag_source;
		ok (1, 'unset drag dest/source');

		$context->finish (0, 0, $time);
	});

# TODO/FIXME: synthesize the drag

$win->add ($view);
$win->show_all;
Gtk2->main;

__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
