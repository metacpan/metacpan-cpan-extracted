# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-MenuView.
#
# Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-MenuView.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::MenuView::Menu;
use 5.008;
use strict;
use warnings;
use Gtk2;

# 1.240 for some non-copying in the GValue boxed handling needed so
# signal_chain_from_overridden in _do_size_request writes its result to the
# right place.  (Or 1.230 pre-release.)
#
# use Glib 1.240;


# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 4;

use Glib::Object::Subclass
  'Gtk2::Menu',
  signals => { map => \&_do_map,
               # size_request => \&_do_size_request,
             };

use constant { _DIRTY_ITEM => 1,
               _DIRTY_SEPARATOR => 2 };

sub INIT_INSTANCE {
  my ($menu) = @_;
  $menu->{'size_request_ids'} = Glib::Ex::SignalIds->new
    ($menu, $menu->signal_connect (size_request => \&_do_size_request));
}

# sub SET_PROPERTY {
#   my ($menu, $pspec, $newval) = @_;
#   my $pname = $pspec->get_name;
#   $menu->{$pname} = $newval;  # per default GET_PROPERTY
# }

# 'show' signal class closure
sub _do_map {
  my ($menu) = @_;
  ### MenuView Menu map: "$menu"
  $menu->_freshen;
  return shift->signal_chain_from_overridden(@_);
}

# 'show' signal class closure
sub _do_size_request {
  my ($menu, $req) = @_;
  ### MenuView Menu size-request: "$menu"

  $menu->_freshen;
  #   return shift->signal_chain_from_overridden(@_);

  undef $menu->{'size_request_ids'};
  my $sreq = $menu->size_request;
  $menu->{'size_request_ids'} = Glib::Ex::SignalIds->new
    ($menu, $menu->signal_connect (size_request => \&_do_size_request));
  $req->width ($sreq->width);
  $req->height ($sreq->height);
}

sub _freshen {
  my ($menu) = @_;
  ### MenuView _freshen(): "$menu"

  $menu->{'all_dirty'} || $menu->{'dirty'} || return;

  my $menuview = $menu->_get_menuview;
  ###   menuview: "$menuview"
  my $model = $menuview && $menuview->{'model'};
  ###   model: "$model"
  my $path = $model && $menu->_get_path;
  ###   path: ($path && $path->to_string)

  # $len can be fetched once from the model as item updates are not allowed
  # to change the rows
  my $len = 0;
  if ($path) {
    # iter undef for depth==0 empty path, otherwise get_iter() of path
    my $iter;
    if ($path->get_depth == 0 || ($iter = $model->get_iter ($path))) {
      #   length from iter: $iter
      $len = $model->iter_n_children ($iter);
    }
  }
  ### $len

  # This loop allows for new dirtiness caused by a model set_value() in an
  # item update.  Looking at all_dirty each time is probably unnecessary,
  # only if maybe _do_row_changed() decided to collapse to all_dirty when
  # all rows are indeed dirty.
  for (;;) {
    my $saw_dirty = 0;
    foreach my $i (0 .. $len-1) {
      $saw_dirty |= ($menuview->_freshen_item ($menu, $path, $i) || 0);
    }
    if (! $saw_dirty) { last; }
  }
  delete $menu->{'dirty'};

  if (my $children = $menu->{'children'}) {
    # use a pop() loop instead of a single splice() out so as not to lose
    # track of items if one of the _remove_item()s errors-out
    while (@$children > $len) {
      if (my $item = pop @$children) {
        $menu->_remove_item ($item);
      }
    }
  }
}

sub _remove_item {
  my ($class_or_menu, $item) = @_;
  ### _remove_item "$item"

  my $menu = $item->get_parent || return;
  if (my $separator = delete $item->{'Gtk2::Ex::MenuView.separator'}) {
    $menu->remove ($separator);
    $separator->destroy;
  }
  $menu->remove ($item);
  $item->set_submenu (undef);
  $item->destroy; # in case circular ref from child AccelLabel
}

#------------------------------------------------------------------------------

# $menu is either $self or a sub-menu, return the $self MenuView
sub _get_menuview {
  my ($menu) = @_;
  for (;;) {
    if ($menu->isa('Gtk2::Ex::MenuView')) { return $menu; }
    my $item = $menu->get_attach_widget || last;
    $menu = $item->get_parent || last;
  }
  return undef;
}

sub _get_path {
  my ($menu) = @_;
  ### MenuView Menu _get_path(): $menu
  if ($menu->isa('Gtk2::Ex::MenuView')) {
    ###   self
    return Gtk2::TreePath->new;  # empty path
  }
  my $item = $menu->get_attach_widget || do {
    ###   oops, unattached menu
    return undef;
  };
  return ($menu->item_get_mmpi($item))[2];
}

# mmpi from the menu or submenu
# sub get_mmpi {
#   my ($menu) = @_;
#   ### MenuView Menu get_mmpi: $menu
#   if ($menu->isa('Gtk2::Ex::MenuView')) {
#     ###   self
#     return ($menu,
#             $menu->{'model'},
#             Gtk2::TreePath->new,
#             undef);
#   }
#   my $item = $menu->get_attach_widget || do {
#     ###   oops, unattached menu
#     return undef;
#   };
#   return $menu->item_get_mmpi ($item);
# }

#------------------------------------------------------------------------------

sub _item_get_index {
  my ($menu, $item) = @_;
  my $children = $menu->{'children'};
  foreach my $i (0 .. $#$children) {
    if (my $child = $children->[$i]) {
      if ($item == $child
          || ($item == ($child->{'Gtk2::Ex::MenuView.separator'}||0))) {
        return $i;
      }
    }
  }
  return undef;
}

sub item_get_path {
  my ($class, $item) = @_;
  return ($class->item_get_mmpi($item))[2];
}
sub item_get_mmpi {
  my ($class, $item) = @_;
  ### Menu item_get_mmpi(): "$item"

  # unless (ref $class_or_menu) {
  #   my $menu = $item->get_parent || return;
  #   ###   class method, recurse to menu: "$menu"
  #   return $menu->item_get_mmpi ($item);
  # }

  my $path = Gtk2::TreePath->new;
  for (;;) {
    my $menu = $item->get_parent || do {
      ###   oops, unattached item
      return;
    };
    my $i = _item_get_index ($menu, $item);
    if (! defined $i) {
      ###   oops, item not a child
      return;
    }
    $path->prepend_index ($i);

    if ($menu->isa('Gtk2::Ex::MenuView')) {
      ###   path: $path->to_string
      my $model = $menu->{'model'} || do {
        ###   oops, no model in menuview
        return;
      };
      my $iter = $model->get_iter($path) || do {
        ###   oops, no iter for path
        return;
      };
      return ($menu, $model, $path, $iter);
    }

    $item = $menu->get_attach_widget || do {
      ###   oops, unattached menu
      return;
    };
  }
}

# sub insert {
#   my ($self, $child, $pos) = @_;
#   if ($pos >= 0 && $pos < $self->{'model_pos'}) {
#     $self->{'model_pos'}--;
#   }
#   $self->SUPER::insert ($child, $pos);
# }
# sub prepend {
#   my ($self, $child) = @_;
#   $self->{'model_pos'}--;
#   $self->SUPER::prepend ($child);
# }

1;
__END__
