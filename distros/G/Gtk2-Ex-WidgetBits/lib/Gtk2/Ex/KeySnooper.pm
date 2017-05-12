# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.

package Gtk2::Ex::KeySnooper;
use 5.008;
use strict;
use warnings;
use Gtk2;

our $VERSION = 48;

sub new {
  my ($class, $func, $userdata) = @_;
  my $self = bless {}, $class;
  $self->install ($func, $userdata);
  return $self;
}

# not yet documented ...
sub install {
  my ($self, $func, $userdata) = @_;
  $self->remove;
  if ($func) {
    $self->{'id'} = Gtk2->key_snooper_install ($func, $userdata);
  }
}

sub DESTROY {
  my ($self) = @_;
  $self->remove;
}

sub remove {
  my ($self) = @_;
  if (my $id = delete $self->{'id'}) {
    Gtk2->key_snooper_remove ($id);
  }
}

1;
__END__

=for stopwords KeySnooper ie Ryde Gtk2-Ex-WidgetBits Gtk Gtk2-Perl

=head1 NAME

Gtk2::Ex::KeySnooper -- keyboard snooper as object

=for test_synopsis my ($mydata);

=head1 SYNOPSIS

 use Gtk2::Ex::KeySnooper;
 my $snooper = Gtk2::Ex::KeySnooper->new (\&myfunc, $mydata);

 # calls &myfunc($widget,$event,$mydata) as usual 

 # myfunc disconnected when object destroyed
 $snooper = undef;

=head1 DESCRIPTION

A C<Gtk2::Ex::KeySnooper> object installs a given function as a key snooper
in the Gtk main loop.  When the KeySnooper object is destroyed it removes
that function.  The idea is that it can be easier to manage the lifespan of
an object than to keep an integer ID safe somewhere and remember
C<< Gtk2->key_snooper_remove >> at the right places.

=head1 FUNCTIONS

=over 4

=item C<< $ks = Gtk2::Ex::KeySnooper->new ($func) >>

=item C<< $ks = Gtk2::Ex::KeySnooper->new ($func, $userdata) >>

Create and return a KeySnooper object calling the given C<$func>.  The calls
made are the same as C<< Gtk2->key_snooper_install >>, ie.

    $stop = &$func ($widget,$event,$userdata)

where C<$func> should return true if it wants to stop event processing,
ie. to consume the event, or false to let it propagate to other handlers
(the same as event signal handler returns, and you can use
C<Gtk2::EVENT_STOP> and C<Gtk2::EVENT_PROPAGATE> in Gtk2-Perl 1.220 and up).
For example,

    my $snooper = Gtk2::Ex::KeySnooper->new (\&myfunc, $mydata);

    sub myfunc {
      my ($widget, $event, $userdata) = @_;
      if ($event->type eq 'key-press') {
        if ($event->keyval == MY_DESIRED_KEYVAL) {
          do_something();
          return 1;  # don't propagate event further
        }
      } else {
        # key release
        ...
      }
      return 0;  # propagate event
    }

=item C<< $snooper->remove() >>

Remove the snooper function, if not already removed.  This is done
automatically when C<$snooper> is destroyed, but you can do it explicitly
sooner if desired.

=back

=head1 SEE ALSO

L<Gtk2::Widget>, L<Gtk2::Ex::WidgetBits>, L<Glib::Ex::SignalIds>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-widgetbits/index.html>

=head1 LICENSE

Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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
