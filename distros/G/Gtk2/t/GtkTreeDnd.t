#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper
  tests => 7,
  noinit => 1;

# GtkTreeDragSource drag_data_get()
#
{ my $list = Gtk2::ListStore->new('Glib::String');
  $list->insert_with_values (0, 0=>'foo');
  $list->insert_with_values (1, 0=>'bar');

  # one arg returning new GtkSelectionData
  my $seldata = $list->drag_data_get (Gtk2::TreePath->new_from_indices(0));
  isa_ok($seldata, 'Gtk2::SelectionData');
  my ($model, $path) = $seldata->get_row_drag_data;
  is ($model, $list);
  is_deeply ([ 0 ], [ $path->get_indices ]);

  # storing to existing GtkSelectionData
  $list->drag_data_get (Gtk2::TreePath->new_from_indices(1), $seldata);
  ($model, $path) = $seldata->get_row_drag_data;
  is ($model, $list);
  is_deeply ([ 1 ], [ $path->get_indices ]);

  # check mortalizing
  require Scalar::Util;
  Scalar::Util::weaken ($seldata); is ($seldata, undef);
  $model = undef;
  Scalar::Util::weaken ($list);    is ($list, undef);
}

exit 0;
__END__
