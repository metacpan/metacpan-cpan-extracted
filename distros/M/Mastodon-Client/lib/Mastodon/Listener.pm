package Mastodon::Listener;

use strict;
use warnings;

our $VERSION = '0.013';

use Moo;
with 'Role::EventEmitter';

use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Instance to_Status to_Notification );
use IO::Async::Loop;
use Net::Async::HTTP;
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

has _ua => (
  is => 'rw',
  init_arg => undef,
  default => sub { Net::Async::HTTP->new },
);

has _future => (
  is => 'rw',
  init_arg => undef,
  lazy => 1,
  default => sub { Future->new },
);

has coerce_entities => (
  is => 'rw',
  isa => Bool,
  lazy => 1,
  default => 0,
);

sub BUILD {
  my ($self, $arg) = @_;
  IO::Async::Loop->new->add($self->_ua);
}

sub start {
  my $self = shift;

  my $current_event;
  my @buffer;

  my $on_error = sub { $self->emit( error => shift, shift, \@_ ) };

  $self->_future(
    $self->_ua->do_request(
      uri => $self->url,
      headers => {
        Authorization => 'Bearer ' . $self->access_token,
      },
      on_error => sub { $on_error->( 1, shift, \@_ ) },
      on_header => sub {
        my $response = shift;
        $on_error->( 1, $response->message, $response )
          unless $response->is_success;

        return sub {
          my $chunk = shift;
          push @buffer, split /\n/, $chunk;

          while (my $line = shift @buffer) {
            if ($line =~ /^(:thump|event: (\w+))$/) {
              my $event = $2;

              if (!defined $event) {
                # Heartbeats have no data
                $self->emit( 'heartbeat' );
                next;
              }
              else {
                $current_event = $event;
              }
            }

            return unless $current_event;
            return unless @buffer;

            my $data = shift @buffer;
            $data =~ s/^data:\s+//;

            if ($current_event eq 'delete') {
              # The payload for delete is a single integer
              $self->emit( delete => $data );
            }
            else {
              # Other events have JSON arrays or objects
              try {
                my $payload = decode_json $data;
                $self->emit( $current_event => $payload );
              }
              catch {
                $self->emit( error => 0,
                  "Error decoding JSON payload: $_", $data
                );
              };
            }

            $current_event = undef;
          }
        }
      },
    )
  );

  $self->_future->get;
}

sub stop {
  my $self = shift;
  $self->_future->done(@_) unless $self->_future->is_ready;
  return $self;
}

sub reset {
  my $self = shift;
  $self->stop->start;
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

Inherited from L<Role::EventEmitter>, will be emitted when an error was found.
The callback will be called with a fatal flag, an error message, and any
relevant data as a single third arghument.

If the error event is triggered in response to a 4xx or 5xx error, the data
payload will be an array reference with the response and request objects
as received from L<Net::Async::HTTP>.

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
