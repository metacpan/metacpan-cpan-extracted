# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.


# set selected-path   select_path()
# model -- its treeview model or undef



package Glib::Ex::ConnectProperties::Element::tree_selection;
use 5.008;
use strict;
use warnings;
use Glib;
use Gtk2;
use base 'Glib::Ex::ConnectProperties::Element';

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


use constant pspec_hash =>
  do {
    my $bool = Glib::ParamSpec->boolean ('empty',  # name
                                         '',       # nick
                                         '',       # blurb
                                         1,        # default, unused
                                         'readable');
    ({
      'empty'      => $bool,
      'not-empty'  => $bool,

      'count'      => Glib::ParamSpec->int ('count', # name
                                            '',      # nick
                                            '',      # blurb
                                            0,       # min
                                            32767,   # max
                                            0,       # default, unused
                                            'readable'),

      'selected-path' => Glib::ParamSpec->boxed ('selected-path',  # name
                                                 '',               # nick
                                                 '',               # blurb
                                                 'Gtk2::TreePath',
                                                 Glib::G_PARAM_READWRITE),
     })
  };

use constant read_signal => 'changed';

sub get_value {
  my ($self) = @_;
  ### tree_selection get_value(): "$self->{'object'}"

  my $sel = $self->{'object'};
  my $pname = $self->{'pname'};
  if ($pname eq 'selected-path') {
    return ($sel->get_selected_rows)[0];
  } else {
    my $count = $sel->count_selected_rows;
    if ($pname eq 'empty') {
      return $count == 0;
    } elsif ($pname eq 'not-empty') {
      return $count != 0;
    } else {
      return $count;
    }
  }
}

sub set_value {
  my ($self, $value) = @_;
  ### tree_selection set_value(): "$self->{'object'}"
  ### value: $value && "$value"

  # pname eq "selected-path"
  my $sel = $self->{'object'};
  if (defined $value) {
    ### select_path: $value->to_string
    $sel->select_path ($value);
  } else {
    ### unselect_all
    $sel->unselect_all;
  }
}

1;
__END__


# No compare method for Gtk2::TreeIter.
# Might subclass Glib::Param::Boxed to add one.
# But even then the path is probably easier
#
# 'selected-iter' => Glib::ParamSpec->boxed ('selected-iter',  # name
#                                            '',               # nick
#                                            '',               # blurb
#                                            'Gtk2::TreeIter',
#                                            Glib::G_PARAM_READWRITE),
#                'selected-iter' => sub { scalar($_[0]->get_selected) },
#                'selected-iter' => 'select_iter',
#    tree-selection#selected-iter   Gtk2::TreeIter or undef

=for stopwords Glib-Ex-ConnectProperties ConnectProperties TreeSelection synchronise TreeViews IconView selected-iter Gtk Ryde Perl-Gtk2's

=head1 NAME

Glib::Ex::ConnectProperties::Element::tree_selection -- TreeSelection rows

=for test_synopsis my ($treesel,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$treesel, 'tree-selection#width'],
                                  [$another, 'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to rows selected in a
L<Gtk2::TreeSelection>.

    tree-selection#empty           boolean, read-only
    tree-selection#not-empty       boolean, read-only
    tree-selection#count           integer, read-only
    tree-selection#selected-path   Gtk2::TreePath or undef

A C<Gtk2::TreeSelection> is normally used by C<Gtk2::TreeView>.  The target
object for ConnectProperties should be the TreeSelection, as obtained from
the TreeView with

    $treeselection = $treeview->get_selection();

For example C<tree-selection#not-empty> might be connected up to make a
delete button sensitive only when the user has selected one or more rows,

    my $treeselection = $treeview->get_selection;
    Glib::Ex::ConnectProperties->new
      ([$treeselection, 'tree-selection#not-empty'],
       [$button,        'sensitive', write_only => 1]);

C<tree-selection#selected-path> is the first selected row.  It's intended
for use with "single" selection mode so there's at most one row selected.
Writing to the property does C<select_path()> and in single mode will switch
from any existing selected row to just the new one.  This could be used to
synchronise the selected item in two TreeViews.

Rows in a C<Gtk2::TreeSelection> and items in a C<Gtk2::IconView> are
similar but not quite the same and so are kept as separate
C<tree-selection#> and C<iconview-selection#>.

For reference a C<selected-iter> of type C<Gtk2::TreeIter> might mostly
work, but not sure about comparing on storing.  Would prefer an C<equal()>
or C<compare()> method on C<Gtk2::TreeIter> rather than going via the model.
(Perl-Gtk2's C<to_arrayref()> access only suits Perl code models.)

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::iconview_selection>,
L<Glib::Ex::ConnectProperties::Element::model_rows>,
L<Glib::Ex::ConnectProperties::Element::combobox_active>,
L<Gtk2::TreeSelection>,
L<Gtk2::TreeView>,
L<Gtk2::TreePath>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-connectproperties/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ConnectProperties.  If not, see L<http://www.gnu.org/licenses/>.

=cut
