# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::History;
use 5.008;
use strict;
use warnings;
use Gtk2 1.220;
use POSIX ();
use Scalar::Util;

use Gtk2;
use Glib::Ex::SignalBits;
use Glib::Ex::FreezeNotify;

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 8;


# place-to-icon-pixbuf
# $h->dialog_class, default sub of self
# $h->dialog_popup (parent => ...)
# $h->menu_popup (parent => ..., way => ..., event => ...)
# MenuBits popup_for_event (parent, event)

# place-to-renderers
# place-to-cellinfo
# place-serialize     \ or Storable freeze
# place-unserialize   /

# place-to-selectiondata
#    default place-to-text
#    flag for set, or emptiness of SelectionData
# selectiondata-to-place
# Gtk2::SelectionData


use Glib::Object::Subclass
  'Glib::Object',
  signals => { 'place-to-text' =>
               { param_types   => ['Glib::Scalar'],
                 return_type   => 'Glib::String',
                 flags         => ['run-last'],
                 class_closure => \&_default_place_to_text,
                 accumulator   => \&Glib::Ex::SignalBits::accumulator_first_defined },

               'place-equal' =>
               { param_types   => ['Glib::Scalar', 'Glib::Scalar'],
                 return_type   => 'Glib::Boolean',
                 flags         => ['run-last'],
                 class_closure => \&_default_place_equal,
                 accumulator   => \&Glib::Ex::SignalBits::accumulator_first },
             },

  properties => [ Glib::ParamSpec->scalar
                  ('current',
                   'Current place object',
                   'Current place object in the history.',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('max-history',
                   'Maximum history count',
                   'The maximum number of places to keep in the history (backwards and forwards counted separately currently).',
                   0,                  # min
                   POSIX::INT_MAX(),   # max
                   40,                 # default
                   Glib::G_PARAM_READWRITE),

                  # this one not documented yet ...
                  Glib::ParamSpec->boolean
                  ('use-markup',
                   'Use markup',
                   'Blurb.',
                   0,  # default
                   Glib::G_PARAM_READWRITE),
                ];

BEGIN {
  Glib::Type->register_enum ('Gtk2::Ex::History::Way',
                             back    => 0,
                             forward => 1);
}

#------------------------------------------------------------------------------

sub INIT_INSTANCE {
  my ($self) = @_;

  $self->{'current'} = undef;

  require Gtk2::Ex::History::ListStore;
  my $back_model = $self->{'back_model'}
    = Gtk2::Ex::History::ListStore->new;

  my $forward_model = $self->{'forward_model'}
    = Gtk2::Ex::History::ListStore->new;

  my $current_model = $self->{'current_model'}
    = Gtk2::Ex::History::ListStore->new;
  $current_model->{'current'} = 1; # flag for ListStore drag/drop
  Scalar::Util::weaken ($current_model->{'history'} = $self);

  foreach my $aref ($back_model   ->{'others'} = [ $forward_model ],
                    $forward_model->{'others'} = [ $back_model ],
                    $current_model->{'others'} = [ $back_model, $forward_model ]) {
    foreach (@$aref) {
      Scalar::Util::weaken ($_);
    }
  }
  ### models: { back => $back_model, forward => $forward_model, current => $current_model }
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  if ($pname eq 'current') {
    $self->goto ($newval);
  } else {
    $self->{$pname} = $newval;
  }
}

sub _default_place_to_text {
  my ($self, $place) = @_;
  return "$place";
}
sub _default_place_equal {
  my ($self, $k1, $k2) = @_;
  ### _default_place_equal(): ($k1 eq $k2)
  if (defined $k1) {
    return (defined $k2 && $k1 eq $k2);
  } else {
    return (! defined $k2);
  }
}

#-----------------------------------------------------------------------------

# this one not documented yet
sub model {
  my ($self, $way) = @_;
  return $self->{"${way}_model"};
}

sub remove {
  my ($self, $place) = @_;
  require Gtk2::Ex::TreeModelBits;
  Gtk2::Ex::TreeModelBits->VERSION(16); # for extra remove args
  foreach my $model ($self->{'back_model'}, $self->{'forward_model'}) {
    Gtk2::Ex::TreeModelBits::remove_matching_rows
        ($model, \&_do_remove_match, [$self, $place]);
  }
}
sub _do_remove_match {
  my ($model, $iter, $userdata) = @_;
  my ($self, $place) = @$userdata;
  return $self->signal_emit ('place-equal',
                             $place,
                             $model->get_value ($iter, $model->COL_PLACE));
}

#-----------------------------------------------------------------------------

sub _set_current {
  my ($self, $place) = @_;
  my $model = $self->{'current_model'};
  my $iter = $model->get_iter_first || $model->append;
  $model->set ($iter, $model->COL_PLACE, $place);
  $self->{'current'} = $place;
  $self->notify('current');
}

sub goto {
  my ($self, $place) = @_;
  ### history goto: $place

  my $current = $self->{'current'};
  if (defined $current) {
    if ($self->signal_emit ('place-equal', $current, $place)) {
      ### same as current
      return;
    }
    ### push back_model: $current
    my $back_model = $self->{'back_model'};
    $back_model->insert_with_values (0, $back_model->COL_PLACE, $current);
    _limit ($self, $back_model);
  }
  _set_current ($self, $place);
}

sub back {
  my ($self, $n) = @_;
  if (! defined $n) { $n = 1; }
  ### History back: $n

  my $current = $self->{'current'};
  if ($n > 0) {
    my $back_model = $self->{'back_model'};
    my $forward_model = $self->{'forward_model'};
    while ($n-- > 0) {
      my $iter = $back_model->get_iter_first || do {
        ### no more back
        last;
      };
      my $place = $back_model->get_value ($iter, $back_model->COL_PLACE);
      ### back to: $place
      $back_model->remove ($iter);

      ### push forward: $current
      $forward_model->insert_with_values (0, $back_model->COL_PLACE, $current);
      _limit ($self, $forward_model);

      $current = $place;
    }
    ### back set current to: $place
    _set_current ($self, $current);
  }
  ### back at: $current
  return $current;
}

sub forward {
  my ($self, $n) = @_;
  if (! defined $n) { $n = 1; }
  ### History forward: $n

  my $freezer = Glib::Ex::FreezeNotify->new ($self); # hold off 'current' prop
  if ($n > 0) {
    my $forward_model = $self->{'forward_model'};
    while ($n--) {
      my $iter = $forward_model->get_iter_first || last;
      my $place = $forward_model->get_value ($iter, $forward_model->COL_PLACE);
      $forward_model->remove ($iter);

      $self->goto ($place);
    }
  }
  ### History forward to: $self->{'current'}
  return $self->{'current'};
}

# enforce 'max-history' on the given liststore model
# if it's too big then remove elements from the end
sub _limit {
  my ($self, $model) = @_;
  ### _limit to: $self->get('max-history'), "$model"
  my $len = $model->iter_n_children (undef);
  my $max = $self->get('max-history');
  for (my $pos = $len - 1; $pos >= $max; $pos--) {
    $model->remove ($model->iter_nth_child (undef, $pos));
  }
}


1;
__END__

=for stopwords goto UIManager filename arrayref stringize filenames filesystem charset boolean Ryde hashref Gtk2-Ex-History

=head1 NAME

Gtk2::Ex::History -- previously visited things

=head1 SYNOPSIS

 use Gtk2::Ex::History;
 my $history = Gtk2::Ex::History->new;

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::History> is a subclass of C<Glib::Object>.

    Glib::Object
      Gtk2::Ex::History

=head1 DESCRIPTION

A C<Gtk2::Ex::History> object records visited places and allows the user to
go "back" and "forward" with control buttons, menus, dialog, including
through a UIManager action.  (See L<Gtk2::Ex::History::Button> etc.)

A place is any Perl scalar.  It could be a byte string filename, a wide-char
document name, an object such as a C<URI>, or a little hashref or arrayref
to hold multiple bits together identifying a place.

=head1 FUNCTIONS

=over 4

=item C<< $history = Gtk2::Ex::History->new (key => value, ...) >>

Create and return a new history object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.

=cut

=item C<< $history->goto ($place) >>

Set C<$place> as the current place in C<$history>.  If the current is
different from C<$place> then that previous current is pushed onto the
"back" list.

=item C<< $place = $history->back () >>

=item C<< $place = $history->back ($n) >>

=item C<< $place = $history->forward () >>

=item C<< $place = $history->forward ($n) >>

Go back or forward in C<$history> one place, or a given C<$n> places.  The
return is the new current place, or C<undef> if nothing further to go to.

=item C<< $history->remove ($place) >>

Remove C<$place> from the history.

(At present it's not removed from the "current", only from the back and
forward lists.  This will probably change ...)

=back

=head1 PROPERTIES

=over 4

=item C<current> (scalar, default C<undef>)

The current place.

=item C<max-history> (integer, default 40)

The maximum number of items to record in the history.

=back

=head1 SIGNALS

=over 4

=item C<place-to-text> (scalar; return string)

This signal is emitted to turn a place object into text to display in the
Menu and Dialog user elements.  The default is a Perl stringize C<"$place">.

A handler should return a wide-char string.  If it's bytes then they're
"upgraded" in the usual way (treating the bytes as Latin-1).

For filenames C<Glib::filename_display_name()> (see L<Glib>) gives a
reasonable form to display, interpreting non-ASCII in the filesystem locale
charset.

See F<examples/iri.pl> in the Gtk2-Ex-History sources for a complete program
turning URL internationalized %-encodings into wide characters for display.

=item C<place-equal> (scalar, scalar; return boolean)

This signal is emitted to check equality of two places.  C<goto> and other
things use it to avoid pushing multiple copies of the same place onto the
history.  The default handler compares with Perl C<eq>.

=back

=head1 SEE ALSO

L<Gtk2::Ex::History::Action>,
L<Gtk2::Ex::History::Button>,
L<Gtk2::Ex::History::Dialog>,
L<Gtk2::Ex::History::Menu>,
L<Glib::Object>

=head1 HOME PAGE

L<http://usr42.tuxfamily.org/gtk2-ex-history/index.html>

=head1 LICENSE

Gtk2-Ex-History is Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-History is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-History is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-History.  If not, see L<http://www.gnu.org/licenses/>.

=cut
