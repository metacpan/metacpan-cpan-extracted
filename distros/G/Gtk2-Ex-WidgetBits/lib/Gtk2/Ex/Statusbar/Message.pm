# Copyright 2009, 2010, 2012 Kevin Ryde

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

package Gtk2::Ex::Statusbar::Message;
use 5.008;
use strict;
use warnings;
use Gtk2;
use Scalar::Util;
use Gtk2::Ex::Statusbar::DynamicContext;

our $VERSION = 48;

use Glib::Object::Subclass
  'Glib::Object',
  properties => [ Glib::ParamSpec->object
                  ('statusbar',
                   'statusbar',
                   'Statusbar to display the message in.',
                   'Gtk2::Statusbar',
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->string
                  ('message',
                   'message',
                   'The message text to display.',
                   '', # default
                   Glib::G_PARAM_READWRITE) ];

# uncomment this to run the ### lines
#use Smart::Comments;


# sub INIT_INSTANCE {
#   my ($self) = @_;
#   Glib::Ex::TieWeakNotify->setup($self, 'statusbar');
# }

sub FINALIZE_INSTANCE {
  my ($self) = @_;
  ### Statusbar-Message FINALIZE_INSTANCE() ...
  ### statusbar: $self->{'statusbar'}
  _remove_message ($self);
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;

  if ($pname eq 'statusbar') {
    _remove_message($self);
    delete $self->{'dctx'}; # context on old statusbar

    Scalar::Util::weaken ($self->{$pname} = $newval);

    _install_message($self);

  } elsif ($pname eq 'message') {
    $self->set_message ($newval);
  }
}

sub set_message {
  my ($self, $message) = @_;

  if (_messages_equal($message, $self->{'message'})) {
    # unchanged
    return;
  }

  $self->{'message'} = $message;  # per default GET_PROPERTY
  _remove_message($self);
  _install_message($self);

  # Not sure whether to notify "message" property before or after pushing
  # into the statusbar.  After means the statusbar is up-to-date when the
  # notify signal comes.  Don't depend on this yet ...
  #
  $self->notify('message');
}

# Return true if message strings $x, $y are equal.
# If both undef then they're equal.
# If both are non-undef then "eq" test.
# If one undef and the other not then not equal.
#
sub _messages_equal {
  my ($x, $y) = @_;
  return (defined $x
          ? (defined $y && $x eq $y)
          : (! defined $y));
}

# not documented yet ...
sub raise {
  my ($self) = @_;
  _remove_message($self);
  _install_message($self);
}

sub _remove_message {
  my ($self) = @_;
  ### Statusbar-Message _remove_message() ...

  my $statusbar = $self->{'statusbar'} || return;
  my $dctx = $self->{'dctx'} || return;
  my $message_id = delete $self->{'message_id'} || return;
  ### context id: $dctx->id
  ### $message_id
  $statusbar->remove ($dctx->id, $message_id);
}

sub _install_message {
  my ($self) = @_;
  if (my $statusbar = $self->{'statusbar'}) {
    my $message = $self->{'message'};
    if (defined $message && $message ne '') {
      my $dctx = ($self->{'dctx'} ||=
                  Gtk2::Ex::Statusbar::DynamicContext->new($statusbar));
      $self->{'message_id'} = $statusbar->push ($dctx->id, $message);
      return;
    }
  }
  # release DynamicContext when not needed
  delete $self->{'dctx'};
}

1;
__END__

=head1 NAME

Gtk2::Ex::Statusbar::Message -- message displayed in a Statusbar

=for test_synopsis my ($statusbar)

=head1 SYNOPSIS

 use Gtk2::Ex::Statusbar::Message;
 my $msg = Gtk2::Ex::Statusbar::Message->new (statusbar => $statusbar);
 $msg->set_message ('Hello World');
 $msg->set_message (undef);

=head1 OBJECT HIERARCHY

C<Gtk2::Ex::Statusbar::Message> is a subclass of C<Glib::Object>,

    Glib::Object
      Gtk2::Ex::Statusbar::Message

=head1 DESCRIPTION

This is an object-oriented approach to a message in a C<Gtk2::Statusbar>.

                                Statusbar
    Message object             +--------------------+
      "hello"       ----->     | hello              |
                               +--------------------+

A Message object holds a string and a target statusbar widget which is where
it should display.  If the Message object is destroyed the string is removed
from the statusbar.

The idea is that it can be easier to manage the lifespan of an object than
to keep a C<$message_id> from the statusbar and remember to pop or remove
when a job object or similar ends or is destroyed.

=head1 FUNCTIONS

=over 4

=item C<< $msg = Gtk2::Ex::Statusbar::Message->new (key=>value, ...) >>

Create and return a new Message object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.

    my $msg = Gtk2::Ex::Statusbar::Message->new
                (statusbar => $statusbar,
                 message   => 'Hello World');

=item C<< $msg->set_message($str) >>

Set the message string to display, as per the C<message> property below.

=back

=head1 PROPERTIES

=over 4

=item C<statusbar> (C<Gtk2::Statusbar> or undef)

The Statusbar widget to display, or undef not to display anywhere.

The Message object only keeps a weak reference to this statusbar.

=item C<message> (string or undef)

The message string to display, or C<undef> not to add anything to the
Statusbar.

Currently an empty string is treated the same as C<undef>, meaning it's not
added to the Statusbar.

=back

=head1 SEE ALSO

L<Gtk2::Statusbar>

L<Gtk2::Ex::Statusbar::DynamicContext>,
L<Gtk2::Ex::Statusbar::MessageUntilKey>

=head1 BUGS

If the C<statusbar> property changes to becomes C<undef> due to the
statusbar weakening away then a C<notify> signal is not emitted for the
property change.

Changing the Message object string raises the message to the top of the
statusbar stack.  Sometimes this is good, but it might be better to keep the
same position, if that could be done easily.

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
