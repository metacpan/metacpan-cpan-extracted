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

package Gtk2::Ex::Menu::EnumRadio;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Glib::Ex::FreezeNotify;
use Glib::Ex::SignalBits;
use Glib::Ex::EnumBits;

use Gtk2::Ex::Menu::EnumRadio::Item;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

use Glib::Object::Subclass
  'Gtk2::Menu',
  signals => { 'nick-to-display'
               => { param_types   => ['Glib::String'],
                    return_type   => 'Glib::String',
                    flags         => ['action','run-last'],
                    class_closure => \&default_nick_to_display,
                    accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined,
                  },
             },
  properties => [
                 # FIXME: default enum-type is undef but
                 # Glib::ParamSpec->gtype() comes out as 'Glib::Enum'
                 #
                 (Glib::Param->can('gtype')
                  ?
                  # gtype() new in Glib 2.10 and Perl-Glib 1.240
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
                   (eval {Glib->VERSION(1.240);1}
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE)),

                 Glib::ParamSpec->string
                 ('active-nick',
                  'Active nick',
                  'The selected enum value, as its nick.',
                  (eval {Glib->VERSION(1.240);1}
                   ? undef # default
                   : ''),  # no undef/NULL before Perl-Glib 1.240
                  Glib::G_PARAM_READWRITE),
                ];

# sub INIT_INSTANCE {
#   my ($self) = @_;
# }

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### Enum GET_PROPERTY: $pname

  if ($pname eq 'active_nick') {
    return $self->get_active_nick;
  }
  # $pname eq 'enum_type'
  return $self->{$pname};
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### Enum SET_PROPERTY: $pname, $newval

  if ($pname eq 'enum_type') {
    my $enum_type = $self->{$pname} = $newval;

    # preserve active-nick if the current active exists in the new
    # enum-type, perhaps at a different position
    $newval = $self->get('active-nick');

    # remove old
    foreach my $item ($self->get_children) {
      if ($item->isa ('Gtk2::Ex::Menu::EnumRadio::Item')) {
        ### remove: "$item"
        $self->remove ($item);
      }
    }
    ### children now: "@{[$self->get_children]}"

    # add new
    if (defined $enum_type && $enum_type ne '') {
      my $item;
      foreach my $info (Glib::Type->list_values($enum_type)) {
        my $nick = $info->{'nick'};
        my $str = $self->signal_emit ('nick-to-display', $nick);
        $item = Gtk2::Ex::Menu::EnumRadio::Item->new_with_label
          ($str);
        $item->set (nick => $nick);
        ### sig: $item->signal_connect (activate => sub { print "activate $item ",$item->get_active,"\n" })
        $item->show;
        $self->append ($item);
      }
    }
  }

  # $pname eq 'active_nick', and also fall-through from 'enum_type' possibly
  # preserving active nick
  $self->set_active_nick ($newval);
  ### actives now: map {$_->get_active} $self->get_children
}

sub default_nick_to_display {
  my ($self, $nick) = @_;
  my $enum_type;
  return (($enum_type = $self->{'enum_type'})
          && Glib::Ex::EnumBits::to_display ($enum_type, $nick));
}

sub get_active_nick {
  my ($self) = @_;
  foreach my $item ($self->get_children) {
    if ($item->isa('Gtk2::Ex::Menu::EnumRadio::Item')
        && $item->get_active) {
      return $item->{'nick'};
    }
  }
  return undef;
}

# Each menuitem set_active() only does something if the new activeness is
# different.  If different then its activate handler raises
# "notify::active-nick" back up here on the menu.
#
sub set_active_nick {
  my ($self, $nick) = @_;

  # just one notify, not two for turning on and off
  my $freezer = Glib::Ex::FreezeNotify->new ($self);

  foreach my $item ($self->get_children) {
    if ($item->isa('Gtk2::Ex::Menu::EnumRadio::Item')) {
      if (defined $nick) {
        if ($item->{'nick'} eq $nick) {
          $item->set_active (1);
          last;
        }
      } else {
        ### inactive: $item->{'nick'}
        $item->set_active (0);
      }
    }
  }
}

1;
__END__

=for stopwords Gtk2-Ex-ComboBoxBits enum ParamSpec GType pspec Enum Ryde

=head1 NAME

Gtk2::Ex::Menu::EnumRadio -- menu of enum values as radio items

=head1 SYNOPSIS

 use Gtk2::Ex::Menu::EnumRadio;
 my $menu = Gtk2::Ex::Menu::EnumRadio->new
              (enum_type   => 'Glib::UserDirectory',
               active_nick => 'home');  # initial selection

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::Menu::EnumRadio> is a subclass of C<Gtk2::Menu>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::MenuShell
          Gtk2::Menu
            Gtk2::Ex::Menu::EnumRadio

=head1 DESCRIPTION

C<Gtk2::Ex::Menu::EnumRadio> displays the values of a C<Glib::Enum> in a
menu as a radio group allowing the user to select one of them.  The
C<active-nick> property is the user's selection.

    +----+
    |Menu|
    +--------------------+
    |  Enum Value One    |
    |* Enum Value Two    |
    |  Enum Value Third  |
    |  Enum Value Fourth |
    +--------------------+

The text shown for each entry is per L<Glib::Ex::EnumBits> C<to_display()>,
so an enum class can arrange how its values appear, or the default is a
sensible word split and capitalization.

(There's a secret experimental might change in the future C<nick-to-display>
signal for per-instance control of the display.  A signal is good for a
callback, but some care may be needed to have it connected early enough, or
for the calls to be made later than when C<enum-type> is set, since that
property will often be set before making signal connections.)

There's no way to set mnemonics for each enum value.  A semi-automatic way
to pick sensible ones might be good.

=head2 Implementation

For reference, in the current code the menu items are a private subclass of
C<Gtk2::CheckMenuItem>.  They're not C<Gtk2::RadioMenuItem> because it
insists on having one value always selected whereas for this EnumRadio the
initial default is nothing selected, similar to a ComboBox.  The items
display in C<draw-as-radio> style when possible (Gtk 2.4 up).

The current code will tolerate extra items added to the menu.  Only those
which are enum values are updated, deleted, etc.  The idea is to allow say a
C<Gtk2::TearoffMenuItem> or equivalent like C<Gtk2::Ex::Dashes::MenuItem> at
the start.  But this is not quite settled, so beware of future changes.  In
particular it may need something to express whether extra items belong
before or after the enum items.

=head1 FUNCTIONS

=over 4

=item C<< $menu = Gtk2::Ex::Menu::EnumRadio->new (key=>value,...) >>

Create and return a new C<EnumRadio> menu object.  Optional key/value pairs
set initial properties per C<< Glib::Object->new >>.

    my $menu = Gtk2::Ex::Menu::EnumRadio->new
                 (enum_type   => 'Gtk2::TextDirection',
                  active_nick => 'ltr');


=item C<< $str = $menu->get_active_nick() >>

Return the nick of the currently selected enum value, or C<undef> if nothing
selected.  This is the C<active-nick> property.

=item C<< $menu->set_active_nick($str) >>

Set the enum value selected, by its nick, or C<undef> to select nothing.
This is the C<active-nick> property.

In the current code if C<$str> is not a nick in the current C<enum-type>
then C<set_active_nick> (and the property setting) quietly set to nothing
selected.  Perhaps this will change.

=back

=head1 PROPERTIES

=over 4

=item C<enum-type> (type name, default C<undef>)

The enum type to display and select from.  Until this is set the Menu is
empty.

When changing C<enum-type> if the current selected C<active-nick> also
exists in the new type then it remains selected (possibly a different menu
item).  If the C<active-nick> doesn't exist in the new type then the menu
changes to nothing selected.

This property is a C<Glib::Param::GType> when possible or
C<Glib::Param::String> otherwise.  In both cases at the Perl level the value
is a type name string, but a GType will check the given type really is an
enum.

=item C<active-nick> (string or C<undef>, default C<undef>)

The nick of the selected enum value.  The nick is the usual way an enum
value appears at the Perl level.

If there's no active row in the menu or no C<enum-type> has been set
then C<active-nick> is C<undef>.

There's no default for C<active-nick>, so when creating an Enum menu it's
usual to set the desired initial selection.

=back

=head1 BUGS

The C<enum-type> paramspec default is not the actual default C<undef> (in
particular when it's a C<GType> it's C<"Glib::Enum"> instead).

    # this should be undef, usually isn't
    $menu->find_property('enum-type')->get_default_value

=head1 SEE ALSO

L<Gtk2::Menu>,
L<Glib::Ex::EnumBits>,
L<Gtk2::Ex::ComboBox::Enum>

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

# =head1 SIGNALS
#
# =over 4
#
# =item C<nick-to-display> (parameters: menu, nick -- return: string)
#
# Emitted to turn an enum nick into a text display string.  The default is
# the C<to_display> of C<Glib::Ex::EnumBits>.
#
# =back

