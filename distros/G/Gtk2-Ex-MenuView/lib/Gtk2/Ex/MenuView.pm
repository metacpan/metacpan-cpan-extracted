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

package Gtk2::Ex::MenuView;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2 1.200; # for GDK_PRIORITY_REDRAW, and bug fixes probably

use Glib::Ex::SignalIds;
use Glib::Ex::SourceIds;
use Glib::Ex::SignalBits;
use Gtk2::Ex::MenuView::Menu;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 4;

use constant _submenu_class => 'Gtk2::Ex::MenuView::Menu';

BEGIN {
  Glib::Type->register_enum ('Gtk2::Ex::MenuView::WantActivate',
                             no   => 0,
                             leaf => 1,
                             all  => 2);
  Glib::Type->register_enum ('Gtk2::Ex::MenuView::WantVisible',
                             no       => 0,
                             show     => 1,
                             show_all => 2);
}

use Glib::Object::Subclass
  _submenu_class(),
  signals => { 'item-create-or-update'
               => { param_types   => ['Gtk2::MenuItem',
                                      'Gtk2::TreeModel',
                                      'Gtk2::TreePath',
                                      'Gtk2::TreeIter'],
                    return_type   => 'Gtk2::MenuItem',
                    flags         => ['action','run-last'],
                    accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
                  },
               'separator-create-or-update'
               => { param_types   => ['Gtk2::MenuItem',
                                      'Gtk2::TreeModel',
                                      'Gtk2::TreePath',
                                      'Gtk2::TreeIter'],
                    return_type   => 'Gtk2::MenuItem',
                    flags         => ['action'],
                    accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
                  },
               activate
               => { param_types => ['Gtk2::MenuItem',
                                    'Gtk2::TreeModel',
                                    'Gtk2::TreePath',
                                    'Gtk2::TreeIter'],
                    return_type => undef },
             },
  properties => [ Glib::ParamSpec->object
                  ('model',
                   'Model',
                   'TreeModel to display.',
                   'Gtk2::TreeModel',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('want-activate',
                   'Want activate',
                   'Whether to connect and generate a unified activate signal.',
                   'Gtk2::Ex::MenuView::WantActivate',
                   'leaf',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->enum
                  ('want-visible',
                   'Want visible',
                   'Whether to automatically make items visible.',
                   'Gtk2::Ex::MenuView::WantVisible',
                   'show_all',
                   Glib::G_PARAM_READWRITE),

                ];


# TODO:
#
# dirty 0, 1=item, 2=separator
#
# current_item_at_indices ...
# $menu->get_model_items
# $menu->model_items_array

# $menuview->menu_at_path
# $menuview->model_items
# $menuview->foreach_model_item
# item_get_indices

# mnemonics
# accel key from model example
# circular protection pay attention to model changes ?

#------------------------------------------------------------------------------

# sub INIT_INSTANCE {
#    my ($self) = @_;
# }

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  $self->{$pname} = $newval;  # per default GET_PROPERTY

  if ($pname eq 'model') {
    my $model = $newval;
    Scalar::Util::weaken (my $weak_self = $self);
    my $ref_weak_self = \$weak_self;
    $self->{'model_ids'} = $model && Glib::Ex::SignalIds->new
      ($model,
       $model->signal_connect (row_changed => \&_do_row_changed,
                               $ref_weak_self),
       $model->signal_connect (row_deleted => \&_do_row_deleted,
                               $ref_weak_self),
       $model->signal_connect (row_inserted => \&_do_row_inserted,
                               $ref_weak_self),
       $model->signal_connect (rows_reordered => \&_do_rows_reordered,
                               $ref_weak_self),
       $model->signal_connect
       (row_has_child_toggled => \&_do_row_has_child_toggled, $ref_weak_self));
    _dirty_all_menus ($self);
  }
}

sub _freshen_item {
  my ($self, $menu, $menu_path, $i) = @_;
  ### _freshen_item() number: $i
  my $model = $self->{'model'} || return;

  if (delete $menu->{'all_dirty'}) {
    ### all_dirty, make dirty array
    my $menu_iter = ($menu_path->get_depth
                     ? $model->get_iter($menu_path) || do {
                       ###   no iter for menu_path
                       return;
                     }
                     : undef);
    my $len = $model->iter_n_children ($menu_iter);
    $menu->{'dirty'} ||= [];
    @{$menu->{'dirty'}} = ((Gtk2::Ex::MenuView::Menu::_DIRTY_ITEM()
                            | Gtk2::Ex::MenuView::Menu::_DIRTY_SEPARATOR())
                           x $len);
  }

  ### dirty_bits: $menu->{'dirty'}->[$i]
  my $dirty_bits = delete $menu->{'dirty'}->[$i] || do {
    ### not dirty, no freshen needed
    return;
  };
  # still dirty if recursive freshens such as item_at_indices() look, but
  # cleared when this _freshen_item() returns
  local $menu->{'dirty'}->[$i] = $dirty_bits;

  my $item_path = $menu_path->copy;
  $item_path->append_index ($i);

  my $item_iter = $model->get_iter($item_path) || do {
    ###   no iter for item_path
    return;
  };

  my $key = $item_path->to_string;
  ### in progress: $self->{'item_update_in_progress'}
  my $in_progress = $self->{'item_update_in_progress'} || {};
  if ($in_progress->{$key}) {
    ### croak for recursion
    croak "Recursive item create or update for path=$key";
  }
  local $self->{'item_update_in_progress'} = { %$in_progress, $key => 1 };
  ### flag in_progress to: $self->{'item_update_in_progress'}

  my $children = ($menu->{'children'} ||= []);
  my $item = $children->[$i];
  my $leaf = ! $model->iter_has_child ($item_iter);

  my ($old_separator, $submenu);
  if ($item) {
    $old_separator = $item->{'Gtk2::Ex::MenuView.separator'};
    $submenu = $item->get_submenu;
  }

  if ($dirty_bits & Gtk2::Ex::MenuView::Menu::_DIRTY_ITEM()) {
    my $old_item = $item;
    $item = $self->signal_emit ('item-create-or-update',
                                $old_item,
                                $model,
                                $item_path,
                                $item_iter);
    ### _item_create: $item

    unless ($item && $old_item && $item == $old_item) {
      if ($old_item) {
        $menu->_remove_item ($old_item);
        delete $children->[$i]; # so _item_index_to_menu_pos() doesn't see it
        undef $old_separator;   # destroyed by _remove_item()
      }
      if ($item) {
        if ((my $want_activate = $self->get('want-activate')) ne 'no') {
          # Connect to both leaf and non-leaf rows and filter in the handler,
          # since a row might gain or lose a submenu at any time.  There won't
          # be many non-leafs so not much is wasted by this.
          $item->signal_connect (activate => \&_do_item_activate);
        }
        if ((my $want_visible = $self->get('want-visible')) ne 'no') {
          $item->$want_visible; # 'show' or 'show_all'
        }
        $menu->insert ($item, _item_index_to_menu_pos($menu,$i));
        $children->[$i] = $item;
      }
    }
  }

  if ($item) {
    if ($leaf) {
      undef $submenu;
    } else {
      if (! $submenu) {
        ### create submenu
        $submenu = $self->_submenu_class->new;
        $submenu->{'all_dirty'} = 1;
      }
    }
    $item->set_submenu ($submenu);
  }

  if ($item
      && ($dirty_bits & Gtk2::Ex::MenuView::Menu::_DIRTY_SEPARATOR())) {
    my $item_iter = $model->get_iter($item_path) || return;
    my $separator = $self->signal_emit ('separator-create-or-update',
                                        $old_separator,
                                        $model,
                                        $item_path,
                                        $item_iter);
    unless ($old_separator && $separator && $old_separator == $separator) {
      if ($old_separator) {
        $menu->remove ($old_separator);
        $old_separator->destroy;
      }
      if ($separator) {
        my $pos = _item_index_to_menu_pos ($menu, $i);
        $item->{'Gtk2::Ex::MenuView.separator'} = $separator;
        $menu->insert ($separator, $pos);
      } else {
        delete $item->{'Gtk2::Ex::MenuView.separator'};
      }
    }
  }

  ### freshen return 1
  return 1;
}

# 'activate' signal handler on each item child
sub _do_item_activate {
  my ($item) = @_;
  ### MenuView activate: $item

  # shouldn't normally get a signal when not within a menu, but allow for
  # perhaps the model changing without signals yet processed
  my ($menuview,$model,$path,$iter) = Gtk2::Ex::MenuView->item_get_mmpi($item)
    or do {
      ###   no model row for activated item
      return;
    };
  if ($menuview->get('want-activate') eq 'leaf'
      && $model->iter_has_child ($iter)) {
    ###   no activate on leaf
    return;
  }
  $menuview->signal_emit ('activate', $item, $model, $path, $iter);
}

sub _item_index_to_menu_pos {
  my ($menu, $i) = @_;
  ### _item_index_to_menu_pos(): $i
  ###   menu: "@{[$menu->get_children]}"
  my $children = $menu->{'children'} || return -1;
  ###   children: "@{[grep {defined} @$children]}"
  my $pos = -1;
  OUTER: for ( ; $i < @$children; $i++) {
    if (my $after = $children->[$i]) {
      $after = $after->{'Gtk2::Ex::MenuView.separator'} || $after;

      foreach my $child ($menu->get_children) {
        $pos++;
        if ($child == $after) { last OUTER; }
      }
      ### oops, not found in menu: "$after"
      ### assert: 0
      return -1;
    }
  }
  ### _item_index_to_menu_pos(): "$i -> $pos"
  return $pos;
}

sub _dirty_all_menus {
  my ($self) = @_;
  ### _dirty_all_menus

  my $menu = $self;
  my @pending;
  do {
    _dirty_menu($menu);
    push @pending, map { my $submenu = $_->get_submenu;
                         ($submenu ? ($submenu) : ()) }
      @{$menu->{'children'}};
  } while ($menu = pop @pending);
}
# sub _menushellbits_menu_and_submenus {
#   my ($menu) = @_;
#   my @pending;
#   my @ret;
#   do {
#     push @ret, $menu;
#     push @pending, grep {defined} map {$_->get_submenu} $menu->get_children;
#   } while ($menu = pop @pending);
#   return @ret;
# }


#------------------------------------------------------------------------------
# dirtiness etc

sub _idle_freshen {
  my ($menu) = @_;
  if ($menu->mapped) {
    my $self = $menu->_get_menuview;
    Scalar::Util::weaken (my $weak_self = $self);
    $self->{'idle'} ||= Glib::Ex::SourceIds->new
      (Glib::Idle->add (\&_do_idle, \$weak_self,
                        Gtk2::GTK_PRIORITY_RESIZE - 1)); # just before resize
  }
}
sub _do_idle {
  my ($ref_weak_self) = @_;
  ### _do_idle
  my $self = $$ref_weak_self || return;
  delete $self->{'idle'};

  my $menu = $self;
  my @pending;
  do {
    if ($menu->mapped) {
      $menu->_freshen;
    }
    push @pending, map {$_->get_submenu || ()} @{$menu->{'children'}};
  } while ($menu = pop @pending);

  return 0; # Glib::SOURCE_REMOVE
}

# mark $menu as all dirty
sub _dirty_menu {
  my ($menu) = @_;
  delete $menu->{'dirty'};
  $menu->{'all_dirty'} ||= do {
    _idle_freshen ($menu);
    1;
  }
}

# mark $menu item number $i as dirty
sub _dirty_add {
  my ($self, $menu, $i, $dirty_bits) = @_;
  ### _dirty_add(): $i, "$menu", $dirty_bits

  if (! $menu->{'all_dirty'}) {
    my $dirty = ($menu->{'dirty'} ||= []);
    $dirty->[$i] |= do {
      _idle_freshen ($self);
      $dirty_bits;  # item
    };
  }
}

sub _dirty_item_and_following_separator {
  my ($self, $menu, $path) = @_;

  my $i = ($path->get_indices)[-1];
  _dirty_add ($self, $menu, $i,
              Gtk2::Ex::MenuView::Menu::_DIRTY_ITEM());

  if (my $model = $self->{'model'}) {
    $path = $path->copy;
    $path->next;
    if ($model->get_iter($path)) {
      _dirty_add ($self, $menu, $i+1,
                  Gtk2::Ex::MenuView::Menu::_DIRTY_SEPARATOR());
    }
  }
}

# return item at $path if it currently exists, or undef if not
sub _current_item_at_path  {
  my ($self, $path) = @_;
  my @indices = $path->get_indices
    or return undef;  # empty path
  my $item;
  my $menu = $self;
  for (;;) {
    $item = $menu->{'children'}->[shift @indices] || return undef;
    @indices || last;
    $menu = $item->get_submenu || return undef;
  }
  return $item;
}

# return menu containing the item at $path, if that menu currently exists
# (the item itself doesn't have to), or undef if no such menu
sub _current_menu_at_path {
  my ($self, $path) = @_;
  if ($path->get_depth == 0) { return $self; }
  my $item = $self->_current_item_at_path($path) || return undef;
  return $item->get_submenu;
}

# return menu containing the item at $path, if that menu currently exists
# (the item itself doesn't have to), or undef if no such menu
sub _current_menu_containing_path {
  my ($self, $path) = @_;
  if ($path->get_depth == 1) { return $self; }
  $path = $path->copy;
  $path->up;
  return $self->_current_menu_at_path($path);
}

#------------------------------------------------------------------------------
# model changes

# 'row-has-child-toggled' callback from model
#
# Called only for rows, not when the toplevel goes between empty and
# non-empty.  FIXME: Not yet documented that an item updates with subrow
# emptiness like this.
#
sub _do_row_has_child_toggled {
  my ($model, $path, $iter, $ref_weak_self) = @_;
  ### MenuView row-has-child-toggled: $path->to_string
  my $self = $$ref_weak_self || return;

  my $item = $self->_current_item_at_path($path) || return;
  if ($model->iter_has_child($iter)) {
    $item->set_submenu (undef);
  }
  # update display for rows or no-rows and create submenu if became
  # non-empty
  _dirty_add ($self, $item->get_parent, ($path->get_indices)[-1],
              Gtk2::Ex::MenuView::Menu::_DIRTY_ITEM());
}

# 'row-changed' callback from model
sub _do_row_changed {
  my ($model, $path, $iter, $ref_weak_self) = @_;
  ### MenuView row changed: $path->to_string
  my $self = $$ref_weak_self || return;

  my $menu = $self->_current_menu_containing_path($path) || do {
    ###   no menu for it currently
    return;
  };
  _dirty_item_and_following_separator ($self, $menu, $path);
}

# 'row-deleted' callback from model
sub _do_row_deleted {
  my ($model, $path, $ref_weak_self) = @_;
  ### MenuView row deleted: $path->to_string
  my $self = $$ref_weak_self || return;

  my $menu = $self->_current_menu_containing_path($path) || do {
    ###   no menu for this yet
    return;
  };

  my $i = ($path->get_indices)[-1];
  _splice_maybe ($menu->{'dirty'}, $i,1);  # delete
  if (my $item = _splice_maybe ($menu->{'children'}, $i,1)) {
    $menu->_remove_item ($item);
  }

  # update following row for its separator, if there's a following row
  if ($model->get_iter($path)) {
    _dirty_add ($self, $menu, $i,
                Gtk2::Ex::MenuView::Menu::_DIRTY_SEPARATOR());
  }
}

# 'row-inserted' callback from model
sub _do_row_inserted {
  my ($model, $path, $iter, $ref_weak_self) = @_;
  ### MenuView row inserted: $path->to_string
  my $self = $$ref_weak_self || return;

  my $menu = $self->_current_menu_containing_path($path) || do {
    ###   no menu for this yet
    return;
  };
  my $i = ($path->get_indices)[-1];

  # shift up arrays if necessary
  _splice_maybe ($menu->{'children'}, $i,0, undef);  # insert
  _splice_maybe ($menu->{'dirty'},    $i,0, 1);      # insert

  _dirty_item_and_following_separator ($self, $menu, $path);
}

# 'rows-reordered' callback from model
sub _do_rows_reordered {
  my ($model, $path, $iter, $aref, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### MenuView rows reordered

  my $menu = $self->_current_menu_at_path($path) || do {
    ###   no menu for this yet
    return;
  };
  my $children = $menu->{'children'} || return;
  my @new_children;
  my $pos = _item_index_to_menu_pos ($menu, 0);
  foreach my $newpos (0 .. $#$aref) {
    my $oldpos = $aref->[$newpos];
    if (my $item = $children->[$oldpos]) {
      $new_children[$newpos] = $item;

      # ENHANCE-ME: defer this to _freshen(), with a 'dirty_reorder' or
      # if 'all_dirty' reinserting coped with reorder
      if (my $separator = $item->{'Gtk2::Ex::MenuView.separator'}) {
        $menu->reorder_child ($separator, $pos++);
      }
      ### reorder_child item to: $pos
      $menu->reorder_child ($item, $pos++);
    }
  }
  @$children = @new_children;

  # ENHANCE-ME: could reorder the dirty flags and just update separators
  # with different preceding
  _dirty_menu ($menu);
}

#------------------------------------------------------------------------------

sub item_at_path {
  my ($self, $path) = @_;
  return $self->item_at_indices ($path->get_indices);
}

sub item_at_indices {
  my $self = shift;
  ### item_at_indices(): @_
  $self->{'model'} || return undef;

  my $menu = $self;
  my $menu_path = Gtk2::TreePath->new;  # of $menu
  my $item;
  while (@_) {
    my $i = shift;
    $self->_freshen_item ($menu, $menu_path, $i);
    (($item = $menu->{'children'}->[$i])
     && ($menu = $item->get_submenu))
      or last;
    $menu_path->append_index($i);
  }
  return $item;
}

#------------------------------------------------------------------------------

# _splice_maybe($aref,$offset,$len, $repl...)
# A splice() of @$aref, but only if $aref is not undef and $offset is not
# past its end.
sub _splice_maybe {
  if (my $aref = shift) {
    if ((my $pos = shift) <= $#$aref) {
      splice @$aref, $pos, @_;   # $len and values
    }
  }
}

#------------------------------------------------------------------------------

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

=for stopwords TreeModel MenuView Gtk undef menuview iter BUILDABLE menubar popup ComboBox renderer CellView renderers submenu MenuItem CellRenderer Subclassing RadioMenuItems toplevel submenus enum lookups CheckMenuItems CheckMenuItem iters recursing tradeoff there'll Buildable menuitem prepends prepend Ryde Gtk2-Ex-MenuView

=head1 NAME

Gtk2::Ex::MenuView -- menu of items from a TreeModel

=for test_synopsis my ($my_model)

=head1 SYNOPSIS

 use Gtk2::Ex::MenuView;
 my $menuview = Gtk2::Ex::MenuView->new (model => $my_model);
 $menuview->signal_connect (item_create_or_update => \&my_item_create);
 $menuview->signal_connect (activate => \&my_item_activate);

 sub my_item_create {
   my ($menuview, $item, $model, $path, $iter) = @_;
   # make item if not already done
   if (! $item) {
     $item = Gtk2::MenuItem->new_with_label ('');
   }
   # update its settings to display model data
   my $label = $item->get_child;
   my $str = $model->get ($iter, 0);  # column 0
   $label->set_text ($str);
   return $item;   # created or updated item
 }

 sub my_item_activate {
   my ($menuview, $item, $model, $path, $iter) = @_;
   print "an item was activated ...\n";
 }

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::MenuView> is a subclass of C<Gtk2::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            Gtk2::Ex::MenuView::Menu
              Gtk2::Ex::MenuView

The C<MenuView::Menu> subclass is an implementation detail (things common to
the toplevel menu and submenus), so don't rely on that.

=head1 DESCRIPTION

C<Gtk2::Ex::MenuView> presents rows and sub-rows of a C<Gtk2::TreeModel> as
a menu and sub-menus.  The items update with changes in the model.

    +--------------+
    | Item One     |
    | Item Two  => | +------------+
    | Item Three   | | Sub-item A |
    +--------------+ | Sub-item B |
                     +------------+

The menu items are created by an C<item-create-or-update> callback signal
described below.  It offers flexibility for item class and settings, but
there's no default, so you must connect a handler or nothing is displayed.
The code shown in the SYNOPSIS above is typical, creating an item if not
already created, then updating the item display settings to show the row
contents.

=head1 FUNCTIONS

=over 4

=item C<< $menuview = Gtk2::Ex::MenuView->new (key=>value,...) >>

Create and return a new C<Gtk2::Ex::MenuView> object.  Optional key/value
pairs set initial properties as per C<< Glib::Object->new >>.

=back

=head2 Item Access

=over 4

=item C<< $item = $menuview->item_at_path ($path) >>

=item C<< $item = $menuview->item_at_indices ($i, $j, ...) >>

Return the C<Gtk2::MenuItem> child at the given path or coordinates.  If it
doesn't exist yet then C<item-create-or-update> is called to create it.

The return is C<undef> if the requested path doesn't exist in the model, or
path is empty, or if C<item-create-or-update> returns C<undef> for no item
for that row.

C<item_at_indices> is handy on a C<list-only> model to get an item just by
number (0 for the first row), without going through a C<Gtk2::TreePath>
object.  For example,

    $item = $menuview->item_at_indices (0);  # first menu item

=back

=head2 Item Location

The following can methods are good in an item signal handler for locating
an item within its MenuView.

=over

=item C<< $path = Gtk2::Ex::MenuView->item_get_path ($item) >>

Return a C<Gtk2::TreePath> which is the location of C<$item> in its
MenuView.  Return C<undef> if C<$item> has been removed from the menuview
(eg. if its row was deleted).

The C<$path> object is newly created and can be modified or kept by the
caller.

=item C<< ($menuview, $model, $path, $iter) = Gtk2::Ex::MenuView->item_get_mmpi ($item) >>

Return a combination menuview, model, path and iter which is the item's
MenuView and location.  Return no values if C<$item> has been removed from
the menuview.

C<$path> and C<$iter> are both newly created and can be modified or kept by
the caller.  C<$model> is the same as C<< $menuview->get('model') >>, but
returned since it's often wanted for fetching data (using C<$iter>).

=back

=head1 PROPERTIES

=over 4

=item C<model> (object implementing C<Gtk2::TreeModel>, default undef)

The TreeModel to display.  Until this is set the menu is empty.

The menu is updated to the new model data by C<item-create-or-update> calls
as necessary.  Any popped-up submenus which don't exist in the new model are
popped-down, but those existing in both the old and new model remain up.

=item C<want-visible> (C<Gtk2::Ex::MenuView::WantVisible> enum, default 'show_all')

Whether to automatically make items visible.  The possible values are

    no         don't touch items' visible property
    show       use $item->show when first created
    show_all   use $item->show_all when first created

The default C<show_all> makes each item and all its child widgets visible.
This is usually what you want to see it on the screen.  C<show> or C<no>
allow items or some of their child parts to be invisible at times.  See
L</Item Visibility> below for further notes.

(The enum value is C<show_all> with an underscore.  It corresponds to the
method name and C function name, though it's unlike other enum nicks which
use hyphens.)

=item C<want-activate> (C<Gtk2::Ex::MenuView::WantActivate> enum, default 'leaf')

Whether to emit the MenuView C<activate> signal (described below) for item
activation.  The possible values are

    no      don't emit
    leaf    emit for leaf items
    all     emit for all items

The default C<leaf> will suit most applications.  C<all> emits on non-leaf
nodes too, such as when clicking to pop up a submenu, which isn't really an
item selection and not usually of interest.

Setting C<no> doesn't emit the C<activate> signal.  This saves some signal
connections and lookups and can be used if you want different connections on
different items, or perhaps only care about a few item activations, or have
a MenuItem subclass with its own activate handler in the class.

Currently this setting only affects newly created items, not existing ones.

=back

=head1 SIGNALS

=over 4

=item C<item-create-or-update> (parameters: menuview, item, model, path, iter)

Emitted as a callback to the application asking it for a menu item for the
given model row.

C<$item> is the previously returned item for this row, or C<undef> if none
yet.  The return should be a C<Gtk2::MenuItem> or subclass.  It can be
either newly created or simply the existing C<$item> with updated settings.
If no item is wanted at all for the row then return C<undef>.

    $menuview->signal_connect
        (item_create_or_update => \&my_item_handler);

    sub my_item_handler {
      my ($menuview, $item, $model, $path, $iter, $userdata) = @_;
      if (! $item) {
        $item = ...;   # create something
      }
      # ... apply item settings to display row data
      return $item;
    }

MenuView owns any item returned to it by C<item-create-or-update> and will
C<< $item->destroy >> when no longer wanted.  (C<destroy> lets items break
any circular references and in particular is necessary for an item with a
C<Gtk2::AccelLabel> child, per notes in L<Gtk2::MenuItem>.)

The order C<item-create-or-update> calls are made for rows is unspecified.
They're also done on a "lazy" basis, so items are only created or updated
when the menu is visible, or its size is requested, etc.

An C<item-create-or-update> handler can call C<< $menuview->item_at_path >>
etc to get another row item.  This will do a recursive
C<item-create-or-update> if the item isn't already up-to-date.  Of course
the item currently updating or any higher one in progress cannot be
obtained.

An C<item-create-or-update> must not insert, delete or reorder the model
rows.

=cut

# Not true since spun through idle ... are there other reasons to leave the
# rows unmolested.
#
# because it may be called from a model C<row-inserted> or C<row-changed>
# signal handler and row changes may invalidate the path and iter reaching
# other connected handlers.

=item C<activate> (parameters: menuview, item, model, path, iter)

Emitted when a menu item is activated, either by the user clicking it, or a
programmatic C<< $item->activate >> (including an C<< $item->set_active >>
on CheckMenuItems).

    sub my_activate {
      my ($menuview, $item, $model, $path, $iter, $userdata) = @_;
      print "Item activated ", $path->to_string, "\n";
    }

The parameters happen to be the same as C<item-create-or-update> above,
except of course C<$item> is not C<undef>.

If you change row contents then bear in mind it might cause an
C<item-create-or-update> call updating C<$item>.  If that callback decides
to return a brand new item then you'll be left with only the old one (now
destroyed).

You can connect directly to the individual item C<activate> signals (with a
C<signal_connect> in C<item-create-or-update>).  The unified MenuView
C<activate> is designed for the common case where most items do something
similar based on the model data.

An C<activate> handler must not insert, delete or reorder rows in the model,
since doing so may invalidate the C<$path> and C<$iter>.  Those objects are
passed to each connected handler without tracking row changes by the
handlers.  This restriction doesn't apply to an C<activate> handler on an
individual item, as it doesn't have path/iter parameters, and as long as the
item C<activate> won't be emitted by code within an C<item-create-or-update>
(like C<set_active> on a CheckMenuItem does) and which thus has path and
iters in use.

=back

=head1 DETAILS

=head2 Item Create and Update

The way C<item-create-or-update> combines the create and update operations
makes it easy to sometimes update an existing item or sometimes create a new
one, probably sharing the code that applies display settings.

An update can return a new item if a different class is wanted for different
row data, or if some settings on an item can be made only when constructing
it, not updated later.  Otherwise an update is usually just a matter of
fetching row data and putting it in properties in the item or child.

A slack C<item-create-or-update> can create a new item every time.  If model
rows don't change often then this is perfectly respectable and may save a
line or two of code.  For example,

    sub my_item_create_or_update_handler {
      my ($menuview, $item, $model, $path, $iter, $userdata) = @_;
      return Gtk2::MenuItem->new_with_label ($model->get($iter,0));
    }

=head2 Item Visibility

Usually all items should be made visible and MenuView does that
automatically by default.  If you want to manage visibility yourself then
set C<want-visiblity> to C<no> to make MenuView leave it alone completely,
or C<show> to have MenuView just C<< $item->show >> the item itself, not
recursing into its children.

An invisible item or a return of C<undef> from C<item-create-or-update> both
result in nothing displayed.  If items are slow to create you might keep
them in the menu but invisible when unwanted (trading memory against
slowness of creation).  Visibility could be controlled from something
external too.

From a user interface point of view it's often better to make items
insensitive (greyed out) when not applicable etc.  You can set the item
C<sensitive> property (see L<Gtk2::Widget>) from C<item-create-or-update>
according to row data, or link it up to something external, etc.

=head2 Check Items

One use for a C<Gtk2::CheckMenuItem> is to have the C<active> property
display and control a column in the model.  In C<item-create-or-update> do
C<< $item->set_active >> to make the item show the model data, then in the
C<activate> signal handler do C<< $model->set >> to put the item's new
C<active> state into the model.  See F<examples/checkitem.pl> in the sources
for a complete sample program.

C<< $model->set >> under C<activate> will cause MenuView to call
C<item-create-or-update> again because the model row has changed, and
C<< $item->set_active >> there may emit the C<activate> signal again.  This
would be an endless recursion except that C<set_activate> notices when the
item is already in the state requested and does nothing.  Be sure to have a
cutoff like that.

Another possibility is to tie the check item C<active> property to something
external using signal handlers to keep them in sync.
L<Glib::Ex::ConnectProperties> is a handy way to link properties between
widgets or objects.

It's usually not a good idea to treat a check item's C<active> property as
the "master" storage for a flag, because the row drag-and-drop in
C<Gtk2::TreeView> and similar doesn't work by reordering rows but instead by
inserting a copy then deleting the old.  MenuView can't tell when that's
happening and creates a new item shortly followed by deleting the old, which
loses the flag value in the old item.

=head2 Radio Button Items

C<Gtk2::RadioMenuItem> is a subclass of C<Gtk2::CheckMenuItem> so the above
L</Check Items> notes apply to it too.

When creating or updating a C<Gtk2::RadioMenuItem> the "group" is set by
passing another radio item widget to group with.  Currently there's not much
in MenuView to help you find a widget to group with.

Keeping group members in a weakened bucket is one possibility.  For
top-level rows another is C<< $menuview->get_children >> (the
C<Gtk2::Container> method) to find a suitable existing group item.  If radio
items are all you ever have in the menu then just the first (if any) will be
enough.

Calling C<< $menuview->item_at_path >> to get another row is no use because
you don't want to create new items, only find an existing one.  In the
future there'll probably be some sort of get current item at path if exists,
or get existing items and paths, or get current items in submenu, or get
submenu widget, etc.

=head2 CellView Items

C<Gtk2::ComboBox> displays its model-based menus using a C<Gtk2::CellView>
child in each item with C<Gtk2::CellRenderer> objects for the drawing.  Alas
it doesn't make this available for general use (only with the selector box,
launching from there).  You can make a similar thing with MenuView by
creating items with a CellView child each.

The only thing to note is that as of Gtk 2.20 a CellView doesn't
automatically redraw if the model row changes.  C<item-create-or-update> is
called for a row change and from there you can force a redraw with
C<< $cellview->set_displayed_row >> with the same path already set in it.
See F<examples/cellview.pl> in the sources for a complete program.

Often a single CellRenderer can be shared among all the items created.
Drawing is done one cell at a time so different attribute values applied for
different rows don't clash, as long as every CellView sets all attributes
which matter.  (Is that a documented CellView feature though?)

=head2 Buildable

C<Gtk2::Ex::MenuView> inherits the C<Gtk2::Buildable> interface like any
widget subclass and C<Gtk2::Builder> can be used to construct a MenuView
similar to a plain C<Gtk2::Menu>.  The class name is C<Gtk2__Ex__MenuView>,
so for example

    <object class="Gtk2__Ex__MenuView" id="my-menu">
      <property name="model">my-model</property>
      <signal name="item-create-or-update" handler="my_create"/>
      <signal name="activate" handler="my_activate"/>
    </object>

Like a plain C<Gtk2::Menu>, a MenuView will be a top-level object in the
builder and then either connected up as the submenu of a menuitem somewhere
(in another menu or menubar), or just created ready to be popped up
explicitly by event handler code.  See F<examples/builder.pl> in the sources
for a complete program.

=head2 Subclassing

If you make a sub-class of MenuView you can have a "class closure" handler
for C<item-create-or-update> and C<activate>.  This is a good way to hide
item creation and setups.  There's no base class handlers for those signals,
so no need to C<signal_chain_from_overridden>.  A subclass might expect
certain model columns to contain certain data, like text to display etc.

You can also make a subclass of C<Gtk2::MenuItem> for the items in a
MenuView.  This can be a good place to hide code that might otherwise be a
blob within C<item-create-or-update>, perhaps doing things like creating or
updating child widgets, etc.  MenuView doesn't care what class the items
are, as long as they're C<Gtk2::MenuItem> or some subclass of
C<Gtk2::MenuItem>.

=head2 Menu Size

MenuView is intended for up to perhaps a few hundred items.  Each item is a
separate C<Gtk2::MenuItem>, usually with a child widget to draw, so it's not
particularly memory-efficient.  You probably won't want to create huge menus
anyway since as of Gtk 2.12 the user scrolling in a menu bigger than the
screen is poor.  (You have to wait while it scrolls, and if you've got a
slow X server it gets badly bogged down by its own drawing.)

=head1 FUTURE

It mostly works to C<< $menu->prepend >> extra fixed items for the menu (see
L<Gtk2::Menu>), not controlled from model rows.  For example a
C<Gtk2::TearoffMenuItem> or equivalent of some other class.  There's nothing
yet to do that in sub-menus though.

It may be possible to append fixed items too.  An C<append> could mean an
item after the model ones, and C<prepend> or an C<insert> near the start
could mean before the model ones.  The only tricky bit is when there's no
model items yet an C<insert> right between the prepends and appends would be
ambiguous.  Perhaps prepend there would be most likely, or have
C<pack_start> and C<pack_end> style methods.

There's some secret work-in-progress in the code for an optional separator
item above each row.  The idea is to have visible separators, usually like
C<Gtk2::SeparatorMenuItem> or similar, between sets of related items,
perhaps at places where a particular model column value changes.

=head1 SEE ALSO

L<Gtk2::Menu>, L<Gtk2::MenuItem>, L<Gtk2::Label>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-menuview/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011 Kevin Ryde

Gtk2-Ex-MenuView is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-MenuView is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-MenuView.  If not, see L<http://www.gnu.org/licenses/>.

=cut

