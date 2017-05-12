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

package Gtk2::Ex::ComboBox::Text;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util;
use Gtk2::Ex::ComboBoxBits 'set_active_text';

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { notify => \&_do_notify },
  properties => [ Glib::ParamSpec->string
                  ('active-text',
                   'Active text',
                   'The selected text value.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef  # default
                    : ''),   # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),


                  # these are not gettable, so the default doesn't matter,
                  # but give undef
                  #
                  Glib::ParamSpec->string
                  ('append-text',
                   'append-text',
                   'Append a text string.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef  # default
                    : ''),   # no undef/NULL before Perl-Glib 1.240
                   ['writable']),

                  Glib::ParamSpec->string
                  ('prepend-text',
                   'prepend-text',
                   'Prepend a text string.',
                   (eval {Glib->VERSION(1.240);1}
                    ? undef  # default
                    : ''),   # no undef/NULL before Perl-Glib 1.240
                   ['writable']),
                ];

# Gtk2::ComboBox::new_text creates a Gtk2::ComboBox, must override to get a
# subclass Gtk2::Ex::ComboBoxBits
# could think about offering this as a ComboBox::Subclass mix-in
sub new_text {
  return shift->new(@_);
}

my $renderer = Gtk2::CellRendererText->new;

sub INIT_INSTANCE {
  my ($self) = @_;

  # same as gtk_combo_box_new_text(), which alas it doesn't make available
  # for general use
  $self->set_model (Gtk2::ListStore->new ('Glib::String'));
  $self->pack_start ($renderer, 1);
  $self->set_attributes ($renderer, text => 0);
}

sub GET_PROPERTY {
  my ($self) = @_;
  ### Text GET_PROPERTY: $_[1]->get_name

  # my $pname = $pspec->get_name;
  # if ($pname eq 'active_text') {
  return $self->get_active_text;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  ### Text SET_PROPERTY: $pspec->get_name, $newval

  my $pname = $pspec->get_name;
  if ($pname eq 'active_text') {
    $self->set_active_text ($newval);
  } else {
    # append_text or prepend_text
    $self->$pname ($newval);
  }
}

# 'notify' class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  ### ComboBox-Test _do_notify()
  shift->signal_chain_from_overridden (@_);

  if ($pspec->get_name eq 'active') {
    $self->notify ('active-text');
  }
}

1;
__END__

=for stopwords Gtk2-Ex-ComboBoxBits ComboBoxBits combobox ComboBox Gtk BUILDABLE buildable Ryde

=head1 NAME

Gtk2::Ex::ComboBox::Text -- text combobox with "active-text" property

=head1 SYNOPSIS

 use Gtk2::Ex::ComboBox::Text;
 my $combo = Gtk2::Ex::ComboBox::Text->new_text;
 $combo->append_text ('First Choice');
 $combo->append_text ('Second Choice');

 $combo->set (active_text => 'Second Choice');

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ComboBox::Text> is a subclass of
C<Gtk2::ComboBox>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ComboBox
            Gtk2::Ex::ComboBox::Text

=head1 DESCRIPTION

This is a "text" style convenience C<Gtk2::ComboBox> with the addition of an
C<active-text> property, and a couple of pseudo-properties to help filling
in the choices.

    +-----------+
    | Text One  |
    +-----------+
      ...

The C<active-text> property is the same as C<< $combo->get_active_text >>
but as a property can be treated a bit more generally than a method call,
for instance link it up to another widget with
C<Glib::Ex::ConnectProperties>.

=head1 FUNCTIONS

=over 4

=item C<< $combobox = Gtk2::Ex::ComboBox::Text->new (key => value,...) >>

=item C<< $combobox = Gtk2::Ex::ComboBox::Text->new_text (key => value,...) >>

Create and return a new Text combobox object.  C<new> and C<new_text> are
the same thing, since a Text combobox is always text style.  Optional
key/value pairs set initial properties per C<< Glib::Object->new >>.

    my $combo = Gtk2::Ex::ComboBox::Text->new;

=item C<< $combobox->set_active_text ($str) >>

The choice C<$str> active, the same as setting the C<active-text> property.

It's slightly unspecified as yet what happens if C<$str> is not available as
a choice in C<$combobox>.

=back

=head1 PROPERTIES

=over 4

=item C<active-text> (string or C<undef>, default C<undef>)

The text of the selected item, or C<undef> if nothing selected.

=item C<append-text> (string, write-only)

=item C<prepend-text> (string, write-only)

Write-only pseudo-properties which add text choices to the combobox as per
the usual C<append_text> and C<prepend_text> methods.

=back

=head1 BUILDABLE

C<Gtk2::Ex::ComboBox::Text> inherits the usual buildable support from
C<Gtk2::ComboBox>, allowing C<Gtk2::Builder> (new in Gtk 2.12) to construct
a Text combobox.  The class name is C<Gtk2__Ex__ComboBox__Text> and
properties and signal handlers can be set in the usual way.

The C<append-text> property is a good way to add choices to the combobox
from within the builder specification.  Either C<active> or C<active-text>
can set an initial selection.  Here's a sample fragment, or see
F<examples/text-builder.pl> in the ComboBoxBits sources for a complete
program.

    <object class="Gtk2__Ex__ComboBox__Text" id="combo">
      <property name="append-text">First Choice</property>
      <property name="append-text">Second Choice</property>
      <property name="active">0</property>
    </object>

=head1 SEE ALSO

L<Gtk2::ComboBox>,
L<Gtk2::Ex::ComboBoxBits>,
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
