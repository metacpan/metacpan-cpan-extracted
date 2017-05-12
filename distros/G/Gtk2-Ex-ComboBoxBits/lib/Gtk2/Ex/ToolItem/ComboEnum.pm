# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::ToolItem::ComboEnum;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Gtk2::Ex::ContainerBits;
use Gtk2::Ex::ComboBox::Enum 5; # v.5 for get_active_nick(),set_active_nick()

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

use Glib::Object::Subclass
  'Gtk2::ToolItem',
  interfaces => [
                 # Gtk2::Buildable new in Gtk 2.12, omit if not available
                 Gtk2::Widget->isa('Gtk2::Buildable') ? ('Gtk2::Buildable') : ()
                ],
  signals => { create_menu_proxy => \&_do_create_menu_proxy,
             },
  properties => [
                 # FIXME: default enum-type is undef but
                 # Glib::ParamSpec->string() doesn't allow that until
                 # Perl-Glib 1.240, in which case have
                 # Glib::ParamSpec->gtype().
                 #
                 (Glib::Param->can('gtype')
                  ?
                  # new in Glib 2.10 and Perl-Glib 1.240
                  Glib::ParamSpec->gtype
                  ('enum-type',
                   'Enum type',
                   'The enum class to display.',
                   'Glib::Enum',
                   Glib::G_PARAM_READWRITE)
                  :
                  Glib::ParamSpec->string
                  ('enum-type',
                   'Enum type',
                   'The enum class to display.',
                   '',
                   Glib::G_PARAM_READWRITE)),

                 Glib::ParamSpec->string
                 ('active-nick',
                  'Active nick',
                  'The selected enum value, as its nick.',
                  (eval {Glib->VERSION(1.240);1}
                   ? undef # default
                   : ''),  # no undef/NULL before Perl-Glib 1.240
                  Glib::G_PARAM_READWRITE),

                 Glib::ParamSpec->string
                 ('overflow-mnemonic',
                  'Overflow menu mnemonic',
                  'A mnemonic label string to show in the overflow menu.  Default is some mangling of the enum-type.',
                  (eval {Glib->VERSION(1.240);1}
                   ? undef # default
                   : ''),  # no undef/NULL before Perl-Glib 1.240
                  Glib::G_PARAM_READWRITE),
                ];

sub INIT_INSTANCE {
  my ($self) = @_;
  my $combobox = Gtk2::Ex::ComboBox::Enum->new;
  $combobox->show;
  $combobox->signal_connect ('notify::active-nick'  => \&_do_combobox_notify);
  $combobox->signal_connect ('notify::enum-type'    => \&_do_combobox_notify);
  $combobox->signal_connect ('notify::add-tearoffs'
                             => \&_do_combobox_notify_add_tearoffs);
  $self->add ($combobox);
}

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  if (my $menuitem = delete $self->{'menuitem'}) {
    $menuitem->destroy;  # destroy circular MenuItem<->AccelLabel
  }
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### ComboEnum GET_PROPERTY: $pname

  if ($pname eq 'enum_type' || $pname eq 'active_nick') {
    ### fetch from combobox: $self->get_child && $self->get_child->get($pname)
    my $combobox;
    return (($combobox = $self->get_child)  # no child when destroyed, maybe
            && $combobox->get($pname));
  }

  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### ComboEnum SET_PROPERTY: $pname, $newval

  if ($pname eq 'enum_type' || $pname eq 'active_nick') {
    foreach my $target
      ($self->get_child,
       ($self->{'menuitem'} && $self->{'menuitem'}->get_submenu)) {

      if ($target) { # no children when destroyed maybe
        ### ComboEnum propagate to: "$target"
        $target->set ($pname => $newval);
      }
    }
  } else {
    $self->{$pname} = $newval;
  }

  if ($pname eq 'overflow_mnemonic'
      || $pname eq 'enum_type') { # for when showing enum-type as fallback
    _update_overflow_mnemonic($self);
  }
}

sub _do_combobox_notify {
  my ($combobox, $pspec) = @_;
  ### ComboEnum _do_combobox_notify()
  if (my $self = $combobox->parent) { # in case unparented maybe
    $self->notify($pspec->get_name);
  }
}
sub _do_combobox_notify_add_tearoffs {
  my ($combobox, $pspec) = @_;
  ### ComboEnum _do_combobox_notify_add_tearoffs()
  if (my $self = $combobox->parent) { # in case unparented maybe
    _update_overflow_tearoff ($self);
  }
}

sub _do_create_menu_proxy {
  my ($self) = @_;
  ### _do_create_menu_proxy()
  my $combobox = $self->get_child || return 0;  # if being destroyed maybe

  if (! $self->{'menuitem'}) {
    require Gtk2::Ex::Menu::EnumRadio;
    require Glib::Ex::ConnectProperties;
    my $menu = Gtk2::Ex::Menu::EnumRadio->new;
    # enum-type first otherwise active-nick not settable
    Glib::Ex::ConnectProperties->new ([$self,'enum-type'],
                                      [$menu,'enum-type']);
    Glib::Ex::ConnectProperties->new ([$self,'active-nick'],
                                      [$menu,'active-nick']);
    # ComboBox tearoff-title new in 2.10, but Menu tearoff-title always present
    if ($combobox->find_property('tearoff-title')) {
      Glib::Ex::ConnectProperties->new ([$combobox,'tearoff-title'],
                                        [$menu,'tearoff-title']);
    }
    ### initial menu enum-type: $menu->get_active_nick 
    ### initial menu active-nick: $menu->get_active_nick 

    # prompt store to $self->{'menuitem'} for safe destroy if any error
    my $menuitem = $self->{'menuitem'} = Gtk2::MenuItem->new_with_mnemonic ('');
    $menuitem->set_submenu ($menu);
    _update_overflow_mnemonic ($self); # initial label
    _update_overflow_tearoff ($self);  # initial tearoff
  }

  $self->set_proxy_menu_item (__PACKAGE__, $self->{'menuitem'});
  return 1;
}

sub _update_overflow_mnemonic {
  my ($self) = @_;
  ### ComboEnum _update_overflow_mnemonic()

  my $menuitem = $self->{'menuitem'} || return;
  my $label = $menuitem->get_child || return; # just in case gone

  my $str = $self->{'overflow_mnemonic'};
  if (! defined $str) {
    if (my $combobox = $self->get_child) {
      if (defined ($str = $combobox->get('enum-type'))) {
        $str =~ s/.*:://;
      } else {
        $str = $combobox->get_name;
      }
    } else {
      $str = $self->get_name;
    }
    require Glib::Ex::EnumBits;
    $str = Glib::Ex::EnumBits::to_display_default (undef, $str);
    require Gtk2::Ex::MenuBits;
    $str = Gtk2::Ex::MenuBits::mnemonic_escape($str);
  }
  ### $str
  $label->set_label ($str);
}

sub _update_overflow_tearoff {
  my ($self) = @_;
  ### ComboEnum _update_overflow_tearoff()
  my $combobox = $self->get_child || return 0;  # if being destroyed maybe
  my $menuitem = $self->{'menuitem'} || return;
  my $menu = $menuitem->get_submenu || return;  # if being destroyed maybe
  $combobox->find_property('add-tearoffs') || return;  # not in Gtk 2.4
  if ($combobox->get('add-tearoffs')) {
    ### tearoff wanted
    unless (List::Util::first
            {$_->isa('Gtk2::TearoffMenuItem')}
            $menu->get_children) {
      ### add new TearoffMenuItem
      $menu->prepend (Gtk2::TearoffMenuItem->new);
    }
  } else {
    ### tearoff not wanted
    Gtk2::Ex::ContainerBits::remove_widgets
        ($menu,
         grep {$_->isa('Gtk2::TearoffMenuItem')} $menu->get_children);
  }
}

#------------------------------------------------------------------------------
# Gtk2::Buildable interface

sub GET_INTERNAL_CHILD {
  my ($self, $builder, $name) = @_;
  if ($name eq 'combobox') {
    return $self->get_child;
  }
  return undef;
}

1;
__END__

# Maybe allowing a different ComboBox subclass to be plugged in ...
#
# add => \&_do_add,
#                remove => \&_do_remove,
# use Glib::Ex::SignalIds;
# sub _do_add {
#   my ($self, $child) = @_;
#   my ($enum_type, $active_nick) = $self->get('enum_type','active_nick');
#   shift->signal_chain_from_overridden (@_);
#
#   $self->set(enum_type => $enum_type,
#              active_nick => $active_nick);
#   $self->{'child_ids'} = Glib::Ex::SignalIds->new
#     ($child,
#      $child->signal_connect ('notify::active-nick'
#                              => \&_do_combobox_notify_nick));
# }
# sub _do_remove {
#   my ($self, $child) = @_;
#   delete $self->{'child_ids'};
#   shift->signal_chain_from_overridden (@_);
# }
#
# sub ADD_CHILD {
#   my ($self, $builder, $child, $type) = @_;
#   # replace default combobox created in init
#   Gtk2::Ex::ContainerBits::remove_all($self);
#   $self->add ($child);
# }


# If doing menu property linkage explicitly instead of ConnectProperties.
#
    # if (my $menuitem = $self->get_proxy_menu_item (__PACKAGE__)) {
    #   $menuitem->get_submenu->set ($pname => $combobox->get('active-nick'));
    # }
  # $menu->signal_connect ('notify::active-nick'
  #                        => \&_do_menu_notify_nick);
# sub _do_menu_notify_nick {
#   my ($menu) = @_;
#   if (my $self = $combobox->parent) { # perhaps in case unparented
#     $self->notify('active-nick');
#     if (my $menuitem = $self->get_proxy_menu_item (__PACKAGE__)) {
#       $menuitem->get_submenu->set ($pname => $combobox->get('active-nick'));
#     }
#   }
# }

=for stopwords enum ParamSpec GType pspec Enum Ryde toolitem combobox Gtk ToolItem ComboBox

=head1 NAME

Gtk2::Ex::ToolItem::ComboEnum -- toolitem with combobox of enum values

=head1 SYNOPSIS

 use Gtk2::Ex::ToolItem::ComboEnum;
 my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
                  (enum_type   => 'Glib::UserDirectory',
                   overflow_mnemonic => '_Directory',
                   active_nick => 'home');  # initial selection

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ToolItem::ComboEnum> is a subclass of
C<Gtk2::ToolItem> (new in Gtk 2.4).

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ToolItem
            Gtk2::Ex::ToolItem::ComboEnum

and implements interfaces

    Gtk2::Buildable  (in Gtk 2.12 up)

=head1 DESCRIPTION

This is a ToolItem holding a C<Gtk2::Ex::ComboBox::Enum> to let the user
choose a value from an enum.  It shows the ComboBox normally, or in an
overflow menu offers the same choices in a radio menu using
C<Gtk2::Ex::Menu::EnumRadio>.  The menu is linked to the combobox so they
update together.

    toolbar overflow
       +---+    
       | V |  
       +---------------+
       | Other         |
       | Enumeration > |+------------+
       | Other         ||   EChoice1 |
       +---------------+|   EChoice2 |
                        | * EChoice3 |   <-- active-nick
                        |   EChoice4 |       radio choice
                        +------------+

The C<enum-type> and C<active-nick> properties on the ToolItem act on the
ComboBox.  They're on the ToolItem for ease of initialization.

The ComboBox child can be accessed with C<< $toolitem->get_child >> in the
usual way if desired, perhaps to set ComboBox specific properties.  See
L</BUILDABLE> below for doing the same from C<Gtk2::Builder>.

=head2 Implementation

This is a subclass rather than just a C<create-menu-proxy> helper function
so as to have C<overflow-mnemonic> as an actual property, and since
C<enum-type> and C<active-nick> on item means less setup code for an
application.

=head1 FUNCTIONS

=over 4

=item C<< $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new (key=>value,...) >>

Create and return a new C<ComboEnum> toolitem widget.  Optional key/value
pairs set initial properties per C<< Glib::Object->new >>.

    my $toolitem = Gtk2::Ex::ToolItem::ComboEnum->new
                     (enum_type   => 'Gtk2::TextDirection',
                      active_nick => 'ltr',
                      overflow_mnemonic => '_Direction');

=item C<< $combobox = $toolitem->get_child >>

The usual C<get_child> method (from L<Gtk2::Bin>) gives the child ComboBox
if you want to set properties etc on it.

=back

=head1 PROPERTIES

=over 4

=item C<enum-type> (type name, default C<undef>)

The enum type to display and select from.  This is the child ComboBox
property made available on the ToolItem for convenience.

=item C<active-nick> (string or C<undef>, default C<undef>)

The nick of the selected enum value.  This is the child ComboBox property
made available on the ToolItem for convenience.

=item C<overflow-mnemonic> (string or C<undef>, default C<undef>)

A mnemonic style string to show in the overflow menu.

If C<undef> then currently the fallback is to present the enum type, which
might at least suggest what the item is for if you forgot to set
C<overflow-mnemonic>.

=back

The C<add-tearoffs> property on the ComboBox child is propagated to the
overflow enum submenu so if there's a tearoff on the ComboBox then there's
also a tearoff on the enum menu.

=head1 BUILDABLE

C<Gtk2::Ex::ToolItem::ComboEnum> can be constructed with C<Gtk2::Builder>
(new in Gtk 2.12).  The class name is C<Gtk2__Ex__ToolItem__ComboEnum> and
properties and signal handlers can be set in the usual way.

The child combobox is made available as an "internal child" under the name
"combobox".  This can be used to set desired properties on that child (those
not otherwise offered on the ToolItem).  Here's a sample fragment, or see
F<examples/tool-enum-builder.pl> in the ComboBoxBits sources for a complete
program.

    <object class="Gtk2__Ex__ToolItem__ComboEnum" id="toolitem">
      <child internal-child="combobox">
        <object class="Gtk2__Ex__ComboBox__Enum" id="blah_combo">
          <property name="tooltip-text">Tooltip for the ComboBox</property>
        </object>
      </child>
    </object>

The C<internal-child> means C<< <child> >> is not creating a new child
object, but accessing one already built.  The C<< id="blah_combo" >> part is
the name to refer to the child elsewhere in the Builder specification,
including a later C<< $builder->get_object >>.  That C<id> be present even
if unused.

=head1 BUGS

As of Perl-Gtk 1.223 the C<Gtk2::Buildable> interface from Perl code doesn't
chain up to the parent buildable methods, so some of GtkWidget specifics may
be lost, such as the C<< <accessibility> >> tags.

=head1 SEE ALSO

L<Gtk2::ToolItem>,
L<Gtk2::Ex::ComboBox::Enum>,
L<Gtk2::Ex::Menu::EnumRadio>,
L<Gtk2::Ex::ToolItem::OverflowToDialog>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-comboboxbits/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-ComboBoxBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
