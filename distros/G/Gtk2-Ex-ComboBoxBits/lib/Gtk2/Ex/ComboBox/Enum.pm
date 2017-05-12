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

package Gtk2::Ex::ComboBox::Enum;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util;
use Glib::Ex::SignalBits;
use Glib::Ex::EnumBits;
use Gtk2::Ex::ComboBoxBits 5; # v.5 for set_active_text() when no model

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { notify => \&_do_notify,
               'nick-to-display'
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
                 (Glib::ParamSpec->can('gtype')
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
                  'Active enum nick',
                  'The selected enum value, as its nick.',
                  (eval {Glib->VERSION(1.240);1}
                   ? undef # default
                   : ''),  # no undef/NULL before Perl-Glib 1.240
                  Glib::G_PARAM_READWRITE),
                ];

use constant _COLUMN_NICK => 0;

my $renderer = Gtk2::CellRendererText->new;
$renderer->set (ypad => 0);

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->pack_start ($renderer, 1);
  Scalar::Util::weaken (my $weak_self = $self);
  $self->set_cell_data_func ($renderer, \&_cell_data, \$weak_self);
}
sub _cell_data {
  my ($cellview, $renderer, $model, $iter, $ref_weak_self) = @_;
  ### ComboBox-Enum _cell_data()
  ### path: $model->get_path($iter)->to_string
  ### nick: $model->get_value ($iter, _COLUMN_NICK)

  my $self = $$ref_weak_self || return;
  my $nick = $model->get_value ($iter, _COLUMN_NICK);

  # can be called at the $store->append() stage, before nick stored
  if (defined $nick) {
    $nick = $self->signal_emit ('nick-to-display', $nick);
  }
  $renderer->set (text => $nick);
}

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

    # preserve active by its nick, if new type has that value
    # set_active() below will notify if the active changes, in particular to
    # -1 if nick not known in the new enum_type
    $newval = $self->get('active-nick');

    # Crib note: In gtk 2.4 believe set_model() doesn't accept NULL,
    # including through set_property(), though a combobox starts out with
    # NULL for the model.  If $enum_type is unset then just clear the
    # existing model, don't try to set undef.
    #
    my $model = $self->get_model;
    if ($model) {
      $model->clear;
    }
    if (defined $enum_type && $enum_type ne '') {
      if (! $model) {
        $model = Gtk2::ListStore->new ('Glib::String');
        $self->set_model ($model);
      }
      my @nicks = map {$_->{'nick'}} Glib::Type->list_values($enum_type);
      #       if ($self->{'sort'}) {
      #         , $self->signal_emit('nick-to-display',$_->{'nick'})
      #         @nicks = sort {$a->[1] cmp $b->[1]} @nicks;
      #       }

      ### @nicks
      foreach my $nick (@nicks) {
        $model->set ($model->append, _COLUMN_NICK, $nick);
      }
    }
  }

  # $pname eq 'active_nick'
  $self->set_active_nick ($newval);
}

sub get_active_nick {
  my ($self) = @_;
  my ($model, $iter);
  return (($model = $self->get_model)
          && ($iter = $self->get_active_iter)
          && $model->get_value ($iter, _COLUMN_NICK));
}
sub set_active_nick {
  my ($self, $nick) = @_;
  Gtk2::Ex::ComboBoxBits::set_active_text ($self, $nick);
}

sub default_nick_to_display {
  my ($self, $nick) = @_;
  my $enum_type;
  return (($enum_type = $self->{'enum_type'})
          && Glib::Ex::EnumBits::to_display ($enum_type, $nick));
}

# 'notify' class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  shift->signal_chain_from_overridden (@_);

  if ($pspec->get_name eq 'active') {
    $self->notify ('active-nick');
  }
}

1;
__END__

               # _COLUMN_DISPLAY => 1,
  # $renderer, text => _COLUMN_DISPLAY);
# sub _fill_display {
#   my ($self) = @_;
#   my $model = $self->get_model;
#   for (my $iter = $model->get_iter_first;
#        $iter;
#        $iter = $model->iter_next ($iter)) {
#     $model->set ($iter, _COLUMN_DISPLAY,
#                  $self->signal_emit('nick-to-display',
#                                     $model->get ($iter, _COLUMN_NICK)));
#   }
# }


=for stopwords Gtk2-Ex-ComboBoxBits enum ParamSpec GType pspec Enum Ryde ComboBoxBits combobox ComboBox paramspec

=head1 NAME

Gtk2::Ex::ComboBox::Enum -- combobox for values of a Glib::Enum

=head1 SYNOPSIS

 use Gtk2::Ex::ComboBox::Enum;
 my $combo = Gtk2::Ex::ComboBox::Enum->new
                 (enum_type   => 'Glib::UserDirectory',
                  active_nick => 'home');  # initial selection

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ComboBox::Enum> is a subclass of C<Gtk2::ComboBox>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ComboBox
            Gtk2::Ex::ComboBox::Enum

=head1 DESCRIPTION

C<Gtk2::Ex::ComboBox::Enum> displays the values of a C<Glib::Enum>.  The
C<active-nick> property is the user's selection.  The usual ComboBox
C<active> property row number works too, though the nick is normally the
useful bit.

      +--------------------+
      |  Enum Value One    |
    +-|                    |-+---+
    + |> Enum Value Two   <| | V |     ComboBox popped up
    +-|                    |-+---+
      |  Enum Value Third  |
      |                    |
      |  Enum Value Fourth |
      +--------------------+

The text shown for each entry is per C<to_display> of L<Glib::Ex::EnumBits>,
so an enum class can arrange how its values appear, or the default is a
sensible word split and capitalization.

(There's a secret experimental might change in the future C<nick-to-display>
signal for per-instance control of the display.  A signal is a good way to
express a callback, but some care may be needed to get it connected early
enough, or for the calls to be later than when C<enum-type> is set, since
that property will often be set before making signal connections.)

=head1 FUNCTIONS

=over 4

=item C<< $combobox = Gtk2::Ex::ComboBox::Enum->new (key=>value,...) >>

Create and return a new C<Enum> combobox object.  Optional key/value
pairs set initial properties per C<< Glib::Object->new >>.

    my $combo = Gtk2::Ex::ComboBox::Enum->new
                  (enum_type => 'Gtk2::TextDirection',
                   active    => 0); # the first row

=item C<< $str = $combobox->get_active_nick >>

=item C<< $combobox->set_active_nick ($str) >>

Get or set the C<active-nick> property described below.  C<set_active_nick>
does nothing if C<$str> is already the active nick, in particular it doesn't
emit a C<notify>.

=back

=head1 PROPERTIES

=over 4

=item C<enum-type> (type name, default C<undef>)

The enum type to display and select from.  Until this is set the ComboBox is
empty.

When changing C<enum-type> if the current selected C<active-nick> also
exists in the new type then it remains selected, possibly on a different
row.  If the C<active-nick> doesn't exist in the new type then the combobox
changes to nothing selected.

(This property is a C<Glib::Param::GType> in new enough Glib and Perl-Glib,
or a C<Glib::Param::String> otherwise.  In both cases it's a type name
string at the Perl level, but GType checks a setting really is an enum.)

=item C<active-nick> (string or C<undef>, default C<undef>)

The nick of the selected enum value.  The nick is the usual way an enum
value appears at the Perl level.

If there's no active row in the combobox or no C<enum-type> has been set
then C<active-nick> is C<undef>.

There's no default for C<active-nick>, just as there's no default for the
ComboBox C<active>, so when creating an Enum combobox it's usual to set the
desired initial selection, either by nick or perhaps just C<active> row 0
for the first value.

=back

=head1 BUGS

There's no way to set mnemonics for each enum value.  A semi-automatic way
to pick sensible ones might be good.

The C<enum-type> paramspec C<get_default_value> should be C<undef> but is
not.  For the C<GType> case it's C<"Glib::Enum">, or for the C<String> it's
an empty C<"">.

    # should be undef, but isn't
    $combobox->find_property('enum-type')->get_default_value

=head1 SEE ALSO

L<Gtk2::ComboBox>,
L<Glib::Ex::EnumBits>,
L<Gtk2::Ex::ComboBox::Text>

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
# =item C<nick-to-display> (parameters: combobox, nick -- return: string)
# 
# Emitted to turn an enum nick into a text display string.  The default is
# the C<to_display> of C<Glib::Ex::EnumBits>.
# 
# =back
