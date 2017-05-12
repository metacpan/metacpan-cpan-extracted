# Copyright 2008, 2009, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::SignalHookIds;
use 5.006;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use Devel::GlobalDestruction 'in_global_destruction';

our $VERSION = 16;

sub new {
  my ($class, $object, @ids) = @_;

  # it's easy to forget the object in the call (and pass only the IDs), so
  # validate the first arg now
  (Scalar::Util::blessed($object) && $object->isa('Glib::Object'))
    or croak 'Glib::Ex::SignalHookIds->new(): first param must be the target object';

  my $self = bless [ $object ], $class;
  Scalar::Util::weaken ($self->[0]);
  $self->add (@ids);
  return $self;
}
sub add {
  my ($self, @ids) = @_;
  push @$self, @ids; # grep {$_} @ids;
}

sub DESTROY {
  my ($self) = @_;
  unless (in_global_destruction()) {
    $self->disconnect;
  }
}

sub object {
  my ($self) = @_;
  return $self->[0];
}

sub disconnect {
  my ($self) = @_;

  my $object = $self->[0];
  if (! $object) { return; }  # target object already destroyed

  while (@$self > 1) {
    my $id = pop @$self;

    # might have been disconnected by $object in the course of its destruction
    if ($object->signal_handler_is_connected ($id)) {
      $object->signal_handler_disconnect ($id);
    }
  }
}

1;
__END__

=head1 NAME

Glib::Ex::SignalHookIds -- hold connected signal handler IDs

=head1 SYNOPSIS

 use Glib::Ex::SignalHookIds;
 my $ids = Glib::Ex::SignalHookIds->new
             ($obj, $obj->signal_add_emission_hook (foo => \&do_foo),
                    $obj->signal_connect (bar => \&do_bar));

 # disconnected when object destroyed
 $ids = undef;

=head1 DESCRIPTION

C<Glib::Ex::SignalHookIds> holds a set of signal handler connection IDs and the
object they're on.  When the SignalHookIds is destroyed it disconnects those
IDs.

This is designed to make life easier when putting connections on "external"
objects which you should cleanup either in your own object destruction or
when switching to a different target.

=head2 Sub-Object Usage

A typical use is connecting to signals on a sub-object set into a property,
like a C<Gtk2::TreeModel> in a viewer, or a C<Gtk2::Adjustment> for
scrolling.  The C<SET_PROPERTY> in your new class might look like

    sub SET_PROPERTY {
      my ($self, $pspec, $newval) = @_;
      my $pname = $pspec->get_name;
      $self->{$pname} = $newval;  # per default GET_PROPERTY

      if ($pname eq 'model') {
        my $model = $newval;
        $self->{'model_ids'} = $model && Glib::Ex::SignalHookIds->new
            ($model,
             $model->signal_connect
               (row_inserted => \&my_insert_handler, $self),
             $model->signal_connect
               (row_deleted  => \&my_delete_handler, $self));
      }
    }

The C<$model &&> part allows C<undef> for no model, in which case the
C<model_ids> becomes undef.  Either way any previous SignalHookIds object in
C<model_ids> is discarded and it disconnects the previous model.  (Note in
the signal user data you won't want C<$self> but something weakened, to
avoid a circular reference, the same as with all signal connections.)

The key to this kind of usage is that the target object may change and you
want a convenient way to connect to the new and disconnect from the old.  If
however a sub-object or sub-widget belongs exclusively to you, never
changes, and is destroyed at the same time as your object, then there's no
need for disconnection and you won't need a SignalHookIds.

=head2 Weakening

SignalHookIds keeps only a weak reference to the target object, letting whoever
or whatever has connected the IDs manage the target lifetime.  In particular
this weakening means a SignalHookIds object can be kept in the instance data of
the target object itself without creating a circular reference.

If the target object is destroyed then all its signals are disconnected.
SignalHookIds knows no explicit disconnects are needed in that case.  SignalHookIds
also knows some forms of weakening and Perl's "global destruction" stage can
give slightly odd situations where the target object has disconnected its
signals but Perl hasn't yet zapped references to the object.  SignalHookIds
therefore checks whether its IDs are still connected before disconnecting,
to avoid warnings from Glib.

=head1 FUNCTIONS

=over 4

=item C<< Glib::Ex::SignalHookIds->new ($object, $id,$id,...) >>

Create and return a SignalHookIds object holding the given C<$id> signal handler
IDs (integers) which are connected on C<$object> (a C<Glib::Object>).

SignalHookIds doesn't actually connect handlers.  You do that with
C<signal_connect> etc in the usual ways and all the various possible
"before", "after", user data, detail, etc, then just pass the resulting ID
to SignalHookIds to look after. Eg.

    my $sigids = Glib::Ex::SignalHookIds->new
        ($obj, $obj->signal_connect (foo => \&do_foo),
               $obj->signal_connect_after (bar => \&do_bar));

=item C<< $sigids->object() >>

Return the object held in C<$sigids>, or C<undef> if it's been destroyed
(zapped by weakening).

=item C<< $sigids->disconnect() >>

Disconnect the signal IDs held in C<$sigids>, if not already disconnected.
This is done automatically when C<$sigids> is garbage collected, but you can
do it explicitly sooner if desired.

=back

=head1 SEE ALSO

L<Glib::Object>, L<Glib::Ex::SourceHookIds>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2011, 2012, 2014 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
