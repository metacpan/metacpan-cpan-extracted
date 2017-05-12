# Copyright 2011, 2012 Kevin Ryde

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

package Gtk2::Ex::ToolItem::CheckButton;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scalar::Util;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 48;

use Glib::Object::Subclass
  'Gtk2::ToolItem',
  interfaces => [
                 # Gtk2::Buildable new in Gtk 2.12, omit if not available
                 Gtk2::Widget->isa('Gtk2::Buildable') ? 'Gtk2::Buildable' : (),
                ],
  signals => { destroy => \&_do_destroy,
               notify  => \&_do_notify,
               create_menu_proxy => \&_do_create_menu_proxy,
             },
  properties => [ Glib::ParamSpec->string
                  ('active',
                   'Active',
                   'Blurb.',
                   '',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('label',
                   'Label',
                   'Blurb.',
                   '',
                   Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  my $checkbutton = Gtk2::CheckButton->new;
  $checkbutton->show;
  $checkbutton->signal_connect ('notify::active',
                                \&_do_checkbutton_notify_active);
  $self->add ($checkbutton);
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### CheckButton FINALIZE_INSTANCE() ...

  # must explicitly destroy MenuItem since it normally has a circular
  # reference between the MenuItem and its AccelLabel child
  if (my $menuitem = delete $self->{'menuitem'}) {
    $menuitem->destroy;
  }
}
sub _do_destroy {
  my ($self) = @_;
  ### CheckButton _do_destroy()...
  FINALIZE_INSTANCE($self); # must explicitly destroy the menuitem
  $self->signal_chain_from_overridden;
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  ### ToolItem-CheckButton GET_PROPERTY: $pspec->get_name
  my $checkitem;
  return (($checkitem = $self->get_child)
          && $checkitem->get($pspec->get_name));
}
sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### ToolItem-CheckButton SET_PROPERTY: $pspec->get_name
  my $pname = $pspec->get_name;

  if ($pname eq 'active' || $pname eq 'label') {
    foreach my $target ($self->get_child, $self->{'menuitem'}) {
      if ($target) {
        $target->set_property ($pname => $newval);
      }
    }

  } else {
    $self->{$pname} = $newval;

    # Not implemented yet, just using the toolitem label ...
    # if ($pname eq 'overflow_mnemonic') {
    #   # propagate
    #   if (my $menuitem = $self->{'menuitem'}) {
    #     $menuitem->set_label (_mnemonic_text ($self));
    #   }
    # }
  }
}

# 'notify' on self
sub _do_notify {
  my ($self, $pspec) = @_;
  ### CheckButton _do_notify() ...
  $self->signal_chain_from_overridden ($pspec);

  my $pname = $pspec->get_name;
  if ($pname eq 'tooltip_text') {
    if (my $menuitem = $self->{'menuitem'}) {
      # if tooltip-text available on $self then is available on $menuitem
      $menuitem->set_property (tooltip_text => $self->get('tooltip-text'));
    }
  }
}

sub _do_checkbutton_notify_active {
  my ($checkbutton, $pspec, $ref_weak_self) = @_;
  my $self = $checkbutton->get_parent || return;
  ### ToolItem-CheckButton _do_checkbutton_notify_active() ...
  if (my $menuitem = $self->{'menuitem'}) {
    $menuitem->set_active ($checkbutton->get_active);
  }
  $self->notify('active');
}

sub _do_create_menu_proxy {
  my ($self) = @_;
  ### ToolItem-CheckButton _do_create_menu_proxy() ...

  my $menuitem;
  if (! ($menuitem = $self->{'menuitem'})) {
    my $label = $self->get_child->get('label');
    $menuitem = $self->{'menuitem'}
      # CheckMenuItem->new() doesn't like undef, pass no args for that
      = Gtk2::CheckMenuItem->new (defined $label ? $label : ());

    # initial and subsequent sensitivity propagated by GtkToolItem
    if ($self->find_property('tooltip-text')) { # new in Gtk 2.12
      $menuitem->set_property (tooltip_text => $self->get('tooltip-text'));
    }
    # or ConnectProperties ...
    Scalar::Util::weaken (my $weak_self = $self);
    $menuitem->signal_connect ('notify::active' => \&_do_menu_notify_active,
                               \$weak_self);
  }
  $self->set_proxy_menu_item (__PACKAGE__, $menuitem);
  return 1;
}


sub _do_menu_notify_active {
  my ($menuitem, $pspec, $ref_weak_self) = @_;
  ### ToolItem-CheckButton _do_menu_notify_active()...
  my $self = $$ref_weak_self || return;
  my $checkitem = $self->get_child || return;
  $checkitem->set_active ($menuitem->get_active);
}

sub get_active {
  my ($self) = @_;
  my $checkitem;
  return (($checkitem = $self->get_child)
          && $checkitem->get_active);
}
sub set_active {
  my ($self, $active) = @_;
  if (my $checkitem = $self->get_child) {
    $checkitem->set_active ($active);
  }
}

#------------------------------------------------------------------------------
# Gtk2::Buildable interface

sub GET_INTERNAL_CHILD {
  my ($self, $builder, $name) = @_;
  if ($name eq 'checkbutton') {
    return $self->get_child;
  }
  if ($name eq 'overflow_menuitem') {
    $self->signal_emit ('create-menu-proxy');
    return $self->retrieve_proxy_menu_item;
  }
  # ENHANCE-ME: Will Gtk2::Buildable expect anything for chaining up?
  return undef;
}

1;
__END__

=for stopwords Gtk2-Ex-WidgetBits Gtk2 Perl-Gtk ToolItem Gtk toolitem boolean reparenting reparented tooltip CheckButton ToggleButton BUILDABLE buildable GtkWidget Ryde

=head1 NAME

Gtk2::Ex::ToolItem::CheckButton -- toolitem with CheckButton

=for test_synopsis my ($widget)

=head1 SYNOPSIS

 use Gtk2::Ex::ToolItem::CheckButton;
 my $toolitem = Gtk2::Ex::ToolItem::CheckButton->new
                  (label => 'Foo',
                   active => 1);  # initial state

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ToolItem::CheckButton> is a subclass of C<Gtk2::ToolItem>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ToolItem
            Gtk2::Ex::ToolItem::CheckButton

and implements interfaces

    Gtk2::Buildable  (in Gtk 2.12 up)

=head1 DESCRIPTION

This is a ToolItem holding a C<Gtk2::CheckButton> widget, and overflowing to
a C<Gtk2::CheckMenuItem> in the toolbar overflow menu when necessary.

    +-------------+             
    | +-+         |
    | |X|  Label  |
    | +-+         |
    +-------------+             

This is similar to C<Gtk2::ToggleToolButton>, but the display is a
CheckButton with a tick check box instead of a ToggleButton in/out shadow.
A shadow is good for a small icon, but for a text word or two the check box
makes it clearer there's something to click.

The CheckButton child can be accessed with C<< $toolitem->get_child >> in
the usual way if desired, for instance to set specific properties.

=head1 FUNCTIONS

=over 4

=item C<< Gtk2::Ex::ToolItem::CheckButton->new (key=>value,...) >>

Create and return a new toolitem widget.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.

    $toolitem = Gtk2::Ex::ToolItem::CheckButton->new
                  (label => 'Foo');

=item C<< $toolitem->set_active ($bool) >>

=item C<< $bool = $toolitem->get_active ($bool) >>

Get or set the C<active> property (see L</PROPERTIES> below).

=back

=head1 PROPERTIES

=over 4

=item C<active> (boolean, default false)

Whether the button is checked or not.

=item C<label> (string, default empty "")

The label text to show in the item and in the overflow menu.

=back

The usual widget C<sensitive> property automatically propagates to the
overflow menu item.

The C<tooltip-text> property (new in Gtk 2.12) is propagated to the overflow
menu item.  It also works to put a tooltip on just the CheckButton child
(which is not propagated).

=head1 BUILDABLE

C<Gtk2::Ex::ToolItem::CheckButton> can be constructed with C<Gtk2::Builder>
(new in Gtk 2.12).  The class name is C<Gtk2__Ex__ToolItem__CheckButton> and
properties and signal handlers can be set in the usual way.

    <object class="Gtk2__Ex__ToolItem__CheckButton" id="toolitem">
      <property name="label">Foo</property>
    </object>

There's two "internal child" widgets available,

    checkbutton          the Gtk2::CheckButton child
    overflow_menuitem    for the toolbar overflow

These can be used to set desired properties (things not otherwise offered
from the ToolItem itself).  Here's a sample fragment,

    <object class="Gtk2__Ex__ToolItem__CheckButton" id="toolitem">
      <child internal-child="checkbutton">
        <object class="GtkCheckButton" id="my_checkbutton">
          <property name="yalign">0</property>
        </object>
      </child>
    </object>

C<internal-child> means C<< <child> >> doesn't create a new child object,
but accesses one already in the parent.  The C<< id="my_checkbutton" >> is
the name to refer to it elsewhere in the Builder specification and any later
C<< $builder->get_object() >>.  That C<id> setting must be present even if
not used.

The C<overflow_menuitem> child has the effect of immediately creating the
overflow item, where it waits until the toolbar needs an overflow (which
might be never).

=head1 BUGS

As of Perl-Gtk 1.223 the C<Gtk2::Buildable> interface from Perl code doesn't
chain up to the parent buildable methods, so some of GtkWidget specifics may
be lost, such as the C<< <accessibility> >> tags.

=head1 SEE ALSO

L<Gtk2::ToggleToolButton>,
L<Gtk2::CheckButton>,
L<Gtk2::Ex::ToolItem::OverflowToDialog>,
L<Gtk2::Ex::ToolItem::ComboEnum>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2011, 2012 Kevin Ryde

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
