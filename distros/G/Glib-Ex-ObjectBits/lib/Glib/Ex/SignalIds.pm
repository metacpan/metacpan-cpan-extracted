# Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

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

package Glib::Ex::SignalIds;
use 5.008;
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
    or croak 'Glib::Ex::SignalIds->new(): first param must be the target object';

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
sub ids {
  my ($self) = @_;
  return @{$self}[1..$#$self];
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

=for stopwords Glib-Ex-ObjectBits Ryde SignalIds Eg

=head1 NAME

Glib::Ex::SignalIds -- hold connected Glib signal handler IDs

=for test_synopsis my ($obj)

=head1 SYNOPSIS

 use Glib::Ex::SignalIds;
 my $ids = Glib::Ex::SignalIds->new
             ($obj, $obj->signal_connect (foo => \&do_foo),
                    $obj->signal_connect (bar => \&do_bar));

 # disconnected when object destroyed
 $ids = undef;

=head1 DESCRIPTION

C<Glib::Ex::SignalIds> holds a set of signal handler connection IDs
(integers) and the object they're on.  When the SignalIds is destroyed it
disconnects those IDs.

This is designed as a reliable way to put connections on "external" objects
which you should cleanup either in your own object destruction or when
switching to a different target.

The SignalIds data object itself is compact so that it can be used on a
large number of objects.

=head2 Target Object Usage

A typical use is connecting to signals on a target object which is in one of
your properties.  For example a C<Gtk2::TreeModel> target in a viewer, or a
C<Gtk2::Adjustment> for scrolling.  The C<SET_PROPERTY> in a class might
look like

    sub SET_PROPERTY {
      my ($self, $pspec, $newval) = @_;
      my $pname = $pspec->get_name;
      $self->{$pname} = $newval;  # per default GET_PROPERTY

      if ($pname eq 'model') {
        my $model = $newval;
        $self->{'model_ids'} = $model && Glib::Ex::SignalIds->new
            ($model,
             $model->signal_connect
               (row_inserted => \&my_insert_handler, $self),
             $model->signal_connect
               (row_deleted  => \&my_delete_handler, $self));
      }
    }

The C<$model &&> part allows C<undef> for no model, in which case the
C<model_ids> becomes C<undef>.  Any previous SignalIds object in
C<model_ids> is discarded and thus disconnects the previous model.  In real
code you won't want C<$self> in the signal user data, but something weakened
to avoid a circular reference, the same as for all signal connections.

The key to this is that the target object might change and you want a
convenient way to connect to the new and disconnect from the old.  If
instead a sub-object or sub-widget belongs exclusively to you, never
changes, and is destroyed at the same time as your object, then there's no
need for disconnection and you don't need a SignalIds.

=head2 Weakening

SignalIds only keeps a weak reference to the target object, letting whoever
or whatever has connected the IDs manage the target lifetime.  In particular
this weakening means a SignalIds object can be kept in the instance data of
the target object itself without creating a circular reference.

If the target object is destroyed then all its signals are disconnected.
SignalIds knows no explicit disconnects are needed in that case.  SignalIds
also knows some forms of weakening can give slightly odd situations where
the target object has disconnected its signals but Perl hasn't yet zapped
references to the object.  For that reason SignalIds checks whether IDs are
still connected before disconnecting, to avoid warnings from Glib.

Warnings for "already disconnected" during target object destruction tend to
be a bit subtle.  You can end up with the Perl-level object hash still
existing yet all signals on the object already disconnected.  SignalIds is a
handy way to avoid trouble.

=head2 Global Destruction

During global destruction SignalIds doesn't disconnect any signals.  This
avoids warnings like

    (in cleanup) Foo=HASH(0x91e6ca0) is not a proper Glib::Object
        (it doesn't contain the right magic)
        at /usr/share/perl5/Glib/Ex/SignalIds.pm line 70 during global destruction.

Objects are destroyed in an unspecified order during global destruction so
it can happen that the target is already gone.  Perl is about to exit anyway
so disconnecting handlers is not necessary.  (See L<perlobj/Global
Destruction>.)

=head1 FUNCTIONS

=over 4

=item C<< $sigids = Glib::Ex::SignalIds->new ($object, $id1,$id2,...) >>

Create and return a SignalIds object holding the given C<$id> signal handler
IDs (integers) which are connected on C<$object> (a C<Glib::Object>).

SignalIds doesn't actually connect handlers.  You do that with
C<signal_connect()> etc in the usual ways and all the various possible
"before", "after", user data, detail, etc, then just pass the resulting ID
to SignalIds to look after. Eg.

    my $sigids = Glib::Ex::SignalIds->new
        ($obj, $obj->signal_connect (foo => \&do_foo),
               $obj->signal_connect_after (bar => \&do_bar));

=item C<< $sigids->add ($id1, $id2, ...) >>

Add further signal IDs to C<$sigids> for the C<$object>.  This can be a
further connection made later on, or only conditionally.

    my $sigids = Glib::Ex::SignalIds->new ($obj);
    $sigids->add ($obj->signal_connect (foo => \&do_foo));
    $sigids->add ($obj->signal_connect (bar => \&do_bar));

Adding IDs one by one is good if one of the C<signal_connect()> calls might
error out.  Previous connections are safely in the C<$sigids> and will be
cleaned up, whereas in a multiple-ID call some could leak on an error.  An
error making a connection is unlikely, unless perhaps the signal name comes
in externally, or the target object class hasn't been checked.

=item C<< $object = $sigids->object() >>

Return the object held in C<$sigids>, or C<undef> if it's been destroyed
(zapped by weakening).

=item C<< @ids = $sigids->ids() >>

Return a list of the signal IDs held in C<$sigids> (possibly an empty list
if nothing held).

=item C<< $sigids->disconnect() >>

Disconnect all the signal IDs held in C<$sigids>, if not already
disconnected.

This is done automatically when C<$sigids> is garbage collected, but you can
do it explicitly sooner if desired.  New signal IDs on the same C<$obj> can
be added again later with C<add>.

=back

=head1 SEE ALSO

L<Glib::Object>,
L<Glib::Ex::SourceIds>,
L<Glib::Ex::SignalBits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012, 2014 Kevin Ryde

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
