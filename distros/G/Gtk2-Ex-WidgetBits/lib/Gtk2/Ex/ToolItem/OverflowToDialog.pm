# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ToolItem::OverflowToDialog;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scalar::Util;
use Gtk2::Ex::ContainerBits;
use Gtk2::Ex::MenuBits 35;  # v.35 for mnemonic_escape, mnemonic_undo

# uncomment this to run the ### lines
#use Smart::Comments;


our $VERSION = 48;

use Glib::Object::Subclass
  'Gtk2::ToolItem',
  interfaces => [
                 # Gtk2::Buildable new in Gtk 2.12, omit if not available
                 Gtk2::Widget->isa('Gtk2::Buildable') ? 'Gtk2::Buildable' : (),
                ],
  signals => { add => \&_do_add,
               destroy => \&_do_destroy,
               create_menu_proxy => \&_do_create_menu_proxy,
               notify => \&_do_notify,
               hierarchy_changed => \&_do_hierarchy_changed,
             },
  properties => [ Glib::ParamSpec->string
                  ('overflow-mnemonic',
                   'Overflow Mnemonic',
                   'Blurb.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->object
                  ('child-widget',
                   'Child Widget',
                   'Blurb.',
                   'Gtk2::Widget',
                   Glib::G_PARAM_READWRITE),
                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### OverflowToDialog FINALIZE_INSTANCE()

  # don't let _update_child_position() store it back again
  delete $self->{'child_widget'};

  if (my $menuitem = delete $self->{'menuitem'}) {
    $menuitem->destroy;  # circular MenuItem<->AccelLabel, must destroy
  }
  if (my $dialog = delete $self->{'dialog'}) {
    $dialog->destroy;  # usual explicit Gtk2::Window destroy
  }
}
sub _do_destroy {
  my ($self) = @_;
  ### OverflowToDialog _do_destroy()
  FINALIZE_INSTANCE($self);
  $self->signal_chain_from_overridden;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### ToolItem-OverflowToDialog SET_PROPERTY: $pspec->get_name
  my $pname = $pspec->get_name;

  if ($pname eq 'child_widget') {
    $self->set_child_widget ($newval);

  } else {
    $self->{$pname} = $newval;

    if ($pname eq 'overflow_mnemonic') {
      # propagate
      if (my $menuitem = $self->{'menuitem'}) {
        if (my $label = $menuitem->get_child) { # perhaps gone in destruction
          $label->set_text_with_mnemonic (_mnemonic_text ($self));
        }
      }
      if (my $dialog = $self->{'dialog'}) {
        $dialog->update_text;
      }
    }
  }
}
sub _do_notify {
  my ($self, $pspec) = @_;
  ### ToolItem-OverflowToDialog _do_notify(): $pspec->get_name
  ### invocation hint: $self->signal_get_invocation_hint

  # my $n;
  #   if ($n++ > 10) {
  #   exit 1;
  # }
  # if (my $child = $self->get('child-widget')) {
  #   if ($child->isa('Gtk2::Container')) {
  #     ### child-widget: join(',', $child->get_children)
  #   }
  # }

  $self->signal_chain_from_overridden ($pspec);
  ### chain returned ...

  # The GtkToolItem gtk_tool_item_property_notify() propagates 'sensitive'
  # to the menuitem already, whatever is currently set_proxy_menu_item().
  # Send it to the dialog too.
  my $pname = $pspec->get_name;
  if ($pname eq 'sensitive' || $pname eq 'tooltip_text') {
    my $newval = $self->get($pname);
    foreach my $target ($self->{'menuitem'},
                        $self->{'dialog'} && $self->{'dialog'}->{'child_vbox'}) {
      if ($target) {
        ### propagate: "$pname to $target"
        $target->set ($pname => $newval);
      }
    }
  }
}

# 'add' class closure, per $container->add()
sub _do_add {
  my ($self, $child) = @_;
  ### ToolItem-OverflowToDialog _do_add(): "$child"

  $self->signal_chain_from_overridden ($child);
  $self->set_child_widget ($child);
}

# not documented yet
sub set_child_widget {
  my ($self, $child_widget) = @_;

  # watch out for recursion from _do_add()
  if ((Scalar::Util::refaddr($self->{'child_widget'})||0)
      == (Scalar::Util::refaddr($child_widget)||0)) {
    ### unchanged
    return;
  }

  $self->{'child_widget'} = $child_widget;
  _update_child_position ($self);

  # go through an idle handler as a workaround for some dodginess in glib
  # circa 2.30 running a notify closure from within an add closure ...
  Glib::Idle->add (sub {
                     $self->notify('child_widget');
                     return 0; # Glib::SOURCE_REMOVE;
                   });
}

sub _update_child_position {
  my ($self) = @_;
  my $child_widget = $self->{'child_widget'};
  if (my $dialog = $self->{'dialog'}) {
    my $child_vbox = $dialog->{'child_vbox'};
    if ($dialog->mapped) {
      # want $child_widget in the dialog
      Gtk2::Ex::ContainerBits::remove_all ($self);
      foreach my $old ($child_vbox->get_children) {
        if ((Scalar::Util::refaddr($old)||0)
            == (Scalar::Util::refaddr($child_widget)||0)) {
          # already in the dialog, don't pack
          undef $child_widget;
        } else {
          $child_vbox->remove ($old);
        }
      }
      if ($child_widget) {
        # expand/fill with dialog
        $child_vbox->pack_start ($child_widget, 1,1,0);
      }
      return;
    }

    # want $child_widget in the toolitem
    Gtk2::Ex::ContainerBits::remove_all ($child_vbox);
  }
  _bin_set_child ($self, $child_widget);
}

# Gtk2::Ex::BinBits::set_child ($bin, $child)
#
# Set the child widget in C<$bin> to C<$child>.  This is done by a C<remove>
# of any existing child and an C<add> of C<$child>.  C<$child> can be undef
# to set no child.
#
# When making a subclass of C<Gtk2::Bin> this function can be imported to
# have it available as a method on the new class, if desired.
#
sub _bin_set_child {
  my ($bin, $child) = @_;
  if (my $old_child = $bin->get_child) {
    if ((Scalar::Util::refaddr($child)||0) == (Scalar::Util::refaddr($old_child)||0)) {
      return;
    }
    $bin->remove ($old_child);
  }
  if (defined $child) {
    if (my $old_parent = $child->get_parent) {
      $old_parent->remove ($child);
    }
    $bin->add ($child);
  }
}

# # Gtk2::Ex::ContainerBits::set_children ($container, $child, ...)
# #
# # Set the children of C<$container> to the given C<$child...> arguments.
# # For convenience any C<undef>s in the arguments are ignored.
# #
# # This is done by a C<remove> of any existing children which are not listed,
# # and an add C<add> of any new additional children given.  If a C<$child> if
# # in C<$container> but not in the position given by the arguments then it's
# # removed and re-added.
# #
# # when making a subclass of C<Gtk2::Container> this function can be imported
# # to have it available as a method on the new class, if desired.
# #
# sub _container_set_children {
#   my $container = shift;
#   @_ = grep {defined} @_;
#   my @remove;
#   my @children = $container->get_children;
#   while (@children) {
#     my $old_child = shift @children;
#     if ((Scalar::Util::refaddr($_[0])||0)
#         == (Scalar::Util::refaddr($children[0])||0)) {
#       shift @_;
#     } else {
#       push @remove, $old_child;
#     }
#   }
#   Gtk2::Ex::ContainerBits::remove_widgets ($container, @remove);
#   foreach my $add (@_) {
#     $container->add ($add);
#   }
# }

# 'hierarchy-changed' class closure handler
sub _do_hierarchy_changed {
  my ($self, $pspec) = @_;
  ### ToolItem-OverflowToDialog _do_hierarchy_changed()

  # cf ConnectProperties self#toplevel -> dialog#transient-for
  # except transient-for prop new in 2.10
  if (my $dialog = $self->{'dialog'}) {
    $dialog->update_transient_for;
  }
}

sub _do_create_menu_proxy {
  my ($self) = @_;
  ### ToolItem-OverflowToDialog _do_create_menu_proxy()
  ### visible: $self->get('visible')

  $self->{'menuitem'} ||= do {
    # initial and subsequent sensitivity propagated by GtkToolItem
    my $menuitem = Gtk2::MenuItem->new_with_mnemonic (_mnemonic_text($self));
    if ($self->find_property('tooltip-text')) { # new in Gtk 2.12
      $menuitem->set_property (tooltip_text => $self->get('tooltip-text'));
    }
    # or ConnectProperties ...
    Scalar::Util::weaken (my $weak_self = $self);
    $menuitem->signal_connect (activate => \&_do_menu_activate, \$weak_self);
    $menuitem
  };

  $self->set_proxy_menu_item (__PACKAGE__, $self->{'menuitem'});
  return 1;
}

sub _do_menu_activate {
  my ($menuitem, $ref_weak_self) = @_;
  my $self = $$ref_weak_self || return;
  ### ToolItem-OverflowToDialog _do_menu_activate()
  _dialog($self)->present_for_menuitem ($menuitem);
}
sub _dialog {
  my ($self) = @_;
  return ($self->{'dialog'} || do {
    ### create new dialog
    require Gtk2::Ex::ToolItem::OverflowToDialog::Dialog;
    my $d = $self->{'dialog'}
      = Gtk2::Ex::ToolItem::OverflowToDialog::Dialog->new (toolitem => $self);
    _do_hierarchy_changed ($self); # initial transient_for
    $d
  });
}

sub _mnemonic_text {
  my ($self) = @_;
  my $str = $self->{'overflow_mnemonic'};
  if (defined $str) {
    return $str;
  } elsif (my $child_widget = $self->{'child_widget'}) {
    return Gtk2::Ex::MenuBits::mnemonic_escape ($child_widget->get_name);
  } else {
    return '';
  }
}

#------------------------------------------------------------------------------
# Gtk2::Buildable interface

sub GET_INTERNAL_CHILD {
  my ($self, $builder, $name) = @_;
  if ($name eq 'overflow_menuitem') {
    $self->signal_emit ('create-menu-proxy');
    return $self->retrieve_proxy_menu_item;
  }
  if ($name eq 'dialog') {
    return _dialog($self);
  }
  # ENHANCE-ME: Will Gtk2::Buildable wrapping expect anything to chain up?
  return undef;
}

1;
__END__

=for stopwords Gtk Gtk2 Perl-Gtk ToolItem Gtk toolitem boolean reparenting reparented tooltip

=head1 NAME

Gtk2::Ex::ToolItem::OverflowToDialog -- toolitem overflowing to a dialog

=for test_synopsis my ($widget)

=head1 SYNOPSIS

 use Gtk2::Ex::ToolItem::OverflowToDialog;
 my $toolitem = Gtk2::Ex::ToolItem::OverflowToDialog->new
                  (child_widget => $widget);

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ToolItem::OverflowToDialog> is a subclass of
C<Gtk2::ToolItem>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ToolItem
            Gtk2::Ex::ToolItem::OverflowToDialog

=head1 DESCRIPTION

This ToolItem displays a given child widget in the usual way, and makes an
overflow menu item to display it in a dialog if the toolbar is full.

       toolbar overflow  
       +---+             
       | V |                   dialog                  
       +-----------+           +----------------------+
       | Other     |           |        My Item       |
       | My Item   |  -->      | +------------------+ |
       | Other     |           | |   child-widget   | |
       +-----------+           | +------------------+ |
                               +----------------------+
                               | Close                |
                               +----------------------+

This ensures a toolitem is always available to the user, if you don't have a
better idea for an overflow.  It's quite well suited to widgets with a lot
of state, such as C<Gtk2::Entry>, as it's the one child widget presented in
two places.

For buttons or check box type children usually it's better to have the
overflow menu item just act directly on the child, like the usual
L<Gtk2::ToolButton>, L<Gtk2::ToggleToolButton> and L<Gtk2::RadioToolButton>.
Or for instance L<Gtk2::Ex::ToolItem::ComboEnum> does a menu item with
sub-menu.

=head2 Implementation

The dialog works by reparenting the child widget to the dialog then putting
it back to the toolitem when closed, unmapped, or destroyed.

If the dialog is open and the toolbar becomes big enough to show the
toolitem, then the dialog is not immediately popped down.  This seems most
sensible for the user, in particular as it's not easy to be sure the child
would be visible if put back, and if the toolbar size is jumping about then
the user won't be pleased to have the dialog taken away but the item not
visible.

Due to the reparenting, the child widget isn't in the usual container
C<< $toolitem->get_child >> (or C<get_children>, C<foreach>, etc).  The
C<child-widget> property is always the child, wherever it's been reparented.

Care should be taken in any signal handlers in the child not to assume that
C<get_parent> or C<get_ancestor> will give the toolbar or main window etc.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::ToolItem::OverflowToDialog->new (key=>value,...) >>

Create and return a new toolitem widget.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.

=back

=head1 PROPERTIES

=over 4

=item C<child-widget> (C<Gtk2::Widget>, default C<undef>)

The child widget to show in the toolitem or dialog.

This is set by the usual C<Gtk2::Container> C<child> property too, but
C<child> is write-only and can only store to an empty ToolItem, whereas
C<child-widget> is read/write and setting it replaces any existing child
widget.

The usual container method C<< $toolitem->add($widget) >> sets this child
widget too, but again only into an empty ToolItem.

=item C<overflow-mnemonic> (string, default C<undef>)

A mnemonic string to show in the overflow menu item.  It should have "_"
underscores like "_Foo" with the "_F" meaning the "F" can be pressed to
select the item.  (Double underscore "__" is a literal underscore.)

=back

The ToolItem C<sensitive> property is propagated to the overflow menu item
and to the dialog's child area.  (But the dialog close button is always
sensitive.)  Setting insensitive just on the child widget works too, but
will leave the menu item sensitive.  It's probably better to make the whole
toolitem insensitive so the menu item is disabled too.

The ToolItem C<tooltip-text> property (new in Gtk 2.12) is copied to the
dialog's child area.  A tooltip can also be put just on the child widget
too.

=head1 BUILDABLE

C<Gtk2::Ex::ToolItem::OverflowToDialog> can be constructed with
C<Gtk2::Builder> (new in Gtk 2.12).  The class name is
C<Gtk2__Ex__ToolItem__OverflowToDialog> and properties and signal handlers
can be set in the usual way.

    <object class="Gtk2__Ex__ToolItem__OverflowToDialog" id="toolitem">
      <property name="overflow-mnemonic">_Foo</property>
    </object>

There's two "internal child" widgets available,

    overflow_menuitem    GtkMenuItem for toolbar overflow
    dialog               GtkDialog opened from there

They can be used to set desired properties on those widgets (things not
otherwise offered from the ToolItem itself).  Here's a sample fragment,

    <object class="Gtk2__Ex__ToolItem__OverflowToDialog" id="toolitem">
      <child internal-child="dialog">
        <object class="GtkDialog" id="ddd">
          <property name="icon-name">something</property>
        </object>
      </child>
    </object>

C<internal-child> means C<< <child> >> doesn't create a new child object,
but accesses one already in the parent.  C<< id="ddd" >> is the name to
refer to it elsewhere in the Builder specification and possible later
C<< $builder->get_object() >>.  An C<id> must be present even if not used.

Both C<overflow_menuitem> and C<dialog> have the effect of creating those
sub-parts immediately, where normally they wait until actually needed for a
toolbar overflow and then when the user clicks on the menu item, both of
which might never happen of course.

=head1 BUGS

As of Perl-Gtk 1.223 the C<Gtk2::Buildable> interface from Perl code doesn't
chain up to the parent buildable methods, so some of GtkWidget specifics may
be lost, such as the C<< <accessibility> >> tags.

=head1 SEE ALSO

L<Gtk2::ToolItem>,
L<Gtk2::ToolButton>,
L<Gtk2::ToggleToolButton>,
L<Gtk2::RadioToolButton>,
L<Gtk2::Ex::ToolItem::ComboEnum>,
L<Gtk2::Ex::ToolItem::CheckButton>,
L<Gtk2::Ex::MenuBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012 Kevin Ryde

Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-WidgetBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
