package Mastodon::Listener;

use strict;
use warnings;

our $VERSION = '0.012';

use Moo;
extends 'AnyEvent::Emitter';

use Carp;
use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Instance to_Status to_Notification );
use AnyEvent::HTTP;
use Try::Tiny;
use JSON::MaybeXS qw( decode_json );

use Log::Any;
my $log = Log::Any->get_logger(category => 'Mastodon');

has instance => (
  is => 'ro',
  isa => Instance,
  coerce => 1,
  default => 'mastodon.cloud',
);

has api_version => (
  is => 'ro',
  isa => Int,
  default => 1,
);

has url => (
  is => 'ro',
  lazy => 1,
  default => sub {
      $_[0]->instance
    . '/api/v' . $_[0]->api_version
    . '/streaming/' . $_[0]->stream;
  },
);

has stream => (
  is => 'ro',
  lazy => 1,
  default => 'public',
);

has access_token => (
  is => 'ro',
  required => 1,
);

has connection_guard => (
  is => 'rw',
  init_arg => undef,
);

has cv => (
  is => 'rw',
  init_arg => undef,
  lazy => 1,
  default => sub { AnyEvent->condvar },
);

has coerce_entities => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => 0,
);

sub BUILD {
  my ($self, $arg) = @_;
  $self->reset;
}

sub start {
  return $_[0]->cv->recv;
}

sub stop {
  return shift->cv->send(@_);
}

sub reset {
  $_[0]->connection_guard($_[0]->_set_connection);
  return $_[0];
}

around emit => sub {
  my $orig = shift;
  my $self = shift;

  my ($event, $data, @rest) = @_;
  if ($event =~ /(update|notification)/ and $self->coerce_entities) {
    $data = to_Notification($data) if $event eq 'notification';
    $data = to_Status($data)       if $event eq 'update';
  }

  $self->$orig($event, $data, @rest);
};

sub _set_connection {
  my $self = shift;
  my $x = http_request GET => $self->url,
    headers => { Authorization => 'Bearer ' . $self->access_token },
    handle_params => {
      max_read_size => 8168,
    },
    want_body_handle => 1,
    sub {
      my ($handle, $headers) = @_;

      if ($headers->{Status} !~ /^2/) {
        $self->emit( error => $handle, 1,
          'Could not connect to ' . $self->url . ': ' . $headers->{Reason}
        );
        $self->stop;
        undef $handle;
        return;
      }

      unless ($handle) {
        $self->emit( error => $handle, 1,
          'Could not connect to ' . $self->url
        );
        $self->stop;
        return;
      }

      my $event_pattern = qr{\s*(:thump|event: (\w+)).*?data:\s*}s;
      my $skip_pattern  = qr{\s*}s;

      my $parse_event;
      $parse_event = sub {
        shift;
        my $chunk = shift;
        my $event = $2;

        if (!defined $event) {
          # Heartbeats have no data
          $self->emit( 'heartbeat' );
          $handle->push_read( regex =>
              $event_pattern, undef, $skip_pattern, $parse_event );
        }
        elsif ($event eq 'delete') {
          # The payload for delete is a single integer
          $handle->push_read( line => sub {
            shift;
            my $line = shift;
            $self->emit( delete => $line );
            $handle->push_read( regex =>
              $event_pattern, undef, $skip_pattern, $parse_event );
          });
        }
        else {
          # Other events have JSON arrays or objects
          $handle->push_read( json => sub {
            shift;
            my $json = shift;
            $self->emit( $event => $json );
            $handle->push_read( regex =>
              $event_pattern, undef, $skip_pattern, $parse_event );
          });
        }
      };

      # Push initial reader: look for event name
      $handle->on_read(sub {
        $handle->push_read( regex => $event_pattern, $parse_event );
      });

      $handle->on_error(sub {
        undef $handle;
        $self->emit( error => @_ );
      });

      $handle->on_eof(sub {
        undef $handle;
        $self->emit( eof => @_ );
      });

    };
  return $x;
}

1;

__END__

=encoding utf8

=head1 NAME

Mastodon::Listener - Access the streaming API of a Mastodon server

=head1 SYNOPSIS

  # From Mastodon::Client
  my $listener = $client->stream( 'public' );

  # Or use it directly
  my $listener = Mastodon::Listener->new(
    url => 'https://mastodon.cloud/api/v1/streaming/public',
    access_token => $token,
    coerce_entities => 1,
  )

  $listener->on( update => sub {
    my ($listener, $status) = @_;
    printf "%s said: %s\n",
      $status->account->display_name,
      $status->content;
  });

  $listener->start;

=head1 DESCRIPTION

A Mastodon::Listener object is created by calling the B<stream> method from a
L<Mastodon::Client>, and it exists for the sole purpose of parsing a stream of
events from a Mastodon server.

Mastodon::Listener objects inherit from L<AnyEvent::Emitter>. Please refer to
their documentation for details on how to register callbacks for the different
events.

Once callbacks have been registered, the listener can be set in motion by
calling its B<start> method, which takes no arguments and never returns.
The B<stop> method can be called from within callbacks to disconnect from the
stream.

=head1 ATTRIBUTES

=over 4

=item B<access_token>

The OAuth2 access token of your application, if authorization is needed. This
is not needed for streaming from public timelines.

=item B<api_version>

The API version to use. Defaults to C<1>.

=item B<coerce_entities>

Whether JSON responses should be coerced into Mastodon::Entity objects.
Currently defaults to false (but this will likely change in v0.01).

=item B<instance>

The instance to use, as a L<Mastodon::Entity::Instance> object. Will be coerced
from a URL, and defaults to C<mastodon.social>.

=item B<stream>

The stream to use. Current valid streams are C<public>, C<user>, and tag
timelines. To access a tag timeline, the argument to this value should begin
with a hash character (C<#>).

=item B<url>

The full streaming URL to use. By default, it is constructed from the values in
the B<instance>, B<api_version>, and B<stream> attributes.

=back

=head1 EVENTS

=over 4

=item B<update>

A new status has appeared. Callback will be called with the listener and
the new status.

=item B<notification>

A new notification has appeared. Callback will be called with the listener
and the new notification.

=item B<delete>

A status has been deleted. Callback will be called with the listener and the
ID of the deleted status.

=item B<heartbeat>

A new C<:thump> has been received from the server. This is mostly for
debugging purposes.

=item B<error>

Inherited from L<AnyEvent::Emitter>, will be emitted when an error was found.
The callback will be called with the same arguments as the B<on_error> callback
for L<AnyEvent::Handle>: the handle of the current connection, a fatal flag,
and an error message.

=back

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
