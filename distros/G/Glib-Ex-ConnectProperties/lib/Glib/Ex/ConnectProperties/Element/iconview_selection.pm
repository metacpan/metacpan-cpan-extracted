# Copyright 2011, 2012 Kevin Ryde

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



package Glib::Ex::ConnectProperties::Element::iconview_selection;
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

use constant read_signal => 'selection-changed';

sub get_value {
  my ($self) = @_;
  ### iconview_selection get_value()

  my @paths = $self->{'object'}->get_selected_items;
  my $pname = $self->{'pname'};
  if ($pname eq 'empty') {
    return scalar(@paths) == 0;
  } elsif ($pname eq 'not-empty') {
    return scalar(@paths) != 0;
  } elsif ($pname eq 'count') {
    return scalar(@paths);
  } else {
    return $paths[0];
  }
}

sub set_value {
  my ($self, $value) = @_;
  ### iconview_selection set_value(): $value && "$value"

  # pname eq "selected-path"
  my $iconview = $self->{'object'};
  if (defined $value) {
    ### select_path: $value->to_string
    $iconview->select_path ($value);
  } else {
    ### unselect_all
    $iconview->unselect_all;
  }
}

#------------------------------------------------------------------------------
# unused

# sub _iconview_count_selected_items {
#   my ($iconview) = @_;
#   my @paths = $iconview->get_selected_items;
#   return scalar(@paths);
# }


1;
__END__

=for stopwords Glib-Ex-ConnectProperties ConnectProperties IconView IconViews synchronise TreeSelection Ryde

=head1 NAME

Glib::Ex::ConnectProperties::Element::iconview_selection -- IconView selected item

=for test_synopsis my ($iconview,$another);

=head1 SYNOPSIS

 Glib::Ex::ConnectProperties->new([$iconview, 'iconview-selection#empty'],
                                  [$another, 'something']);

=head1 DESCRIPTION

This element class implements ConnectProperties access to items "selected"
in a L<Gtk2::IconView>.

    iconview-selection#empty           boolean, read-only
    iconview-selection#not-empty       boolean, read-only
    iconview-selection#count           integer, read-only
    iconview-selection#selected-path   Gtk2::TreePath or undef

For example C<iconview-selection#not-empty> might be connected up to make a
delete button sensitive only when the user has selected a row,

C<iconview-selection#selected-path> is the first selected row.  It's
intended for use with C<selection-mode> set to "single" so there's at most
one item selected.  Storing to the property calls C<select_path()> and in
single mode will switch from any existing selected item to just a given new
one.  This could be used to synchronise the selected item in two IconViews.

Selected rows in a C<Gtk2::TreeSelection> and items in an C<Gtk2::IconView>
are similar but not quite the same and are therefore handled separately in
C<tree-selection#> and C<iconview-selection#>.

=head1 SEE ALSO

L<Glib::Ex::ConnectProperties>,
L<Glib::Ex::ConnectProperties::Element::tree_selection>,
L<Gtk2::IconView>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-connectproperties/index.html>

=head1 LICENSE

Copyright 2011, 2012 Kevin Ryde

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
