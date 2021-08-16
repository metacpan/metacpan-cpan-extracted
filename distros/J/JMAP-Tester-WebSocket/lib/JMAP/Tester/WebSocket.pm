use v5.10.0;
use warnings;

package JMAP::Tester::WebSocket 0.003;
# ABSTRACT: a WebSocket JMAP client made for testing JMAP servers

use Moo;
use IO::Async::Loop;
use Net::Async::WebSocket::Client 0.13;
use Protocol::WebSocket::Request;
use Params::Util qw(_HASH0 _ARRAY0);
use Data::Dumper;
use Scalar::Util qw(weaken);
use Try::Tiny;

use JMAP::Tester::WebSocket::Response;
use JMAP::Tester::WebSocket::Result::Failure;

extends qw(JMAP::Tester);

has +json_codec => (
  is => 'bare',
  handles => {
    json_encode => 'encode',
    json_decode => 'decode',
  },
  default => sub {
    require JSON;

    # Not ->utf8-> or we die decoding things with "wide character"...
    # Maybe to be fixed in Protocol::WebSocket? Or IO::Async is doing this
    # for us?
    return JSON->new->convert_blessed;
  },
);


has 'ws_api_uri' => (
  is        => 'rw',
  required  => 1,
);

has cache_connection => (
  is      => 'ro',
  default => 0,
);

has 'authorization' => (
  is        => 'rw',
  predicate => 'has_authorization',
);

has _cached_client => (
  is => 'rw',
);

has loop => (
  is      => 'rw',
  default => sub { IO::Async::Loop->new }, 
);

sub request {
  my ($self, $input_request) = @_;

  state $ident = 'a';
  my %seen;
  my @suffixed;

  my %default_args = %{ $self->default_arguments };

  my $request = _ARRAY0($input_request)
              ? { methodCalls => $input_request }
              : { %$input_request };

  for my $call (@{ $request->{methodCalls} }) {
    my $copy = [ @$call ];
    if (defined $copy->[2]) {
      $seen{$call->[2]}++;
    } else {
      my $next;
      do { $next = $ident++ } until ! $seen{$ident}++;
      $copy->[2] = $next;
    }

    my %arg = (
      %default_args,
      %{ $copy->[1] // {} },
    );

    for my $key (keys %arg) {
      if ( ref $arg{$key}
        && ref $arg{$key} eq 'SCALAR'
        && ! defined ${ $arg{$key} }
      ) {
        delete $arg{$key};
      }
    }

    $copy->[1] = \%arg;

    push @suffixed, $copy;
  }

  $request->{methodCalls} = \@suffixed;

  $request = $request->{methodCalls}
    if $ENV{JMAP_TESTER_NO_WRAPPER} && _ARRAY0($input_request);

  if ($self->_has_default_using && ! exists $request->{using}) {
    $request->{using} = $self->default_using;
  }

  # Required by RFC 8887
  $request->{'@type'} = 'Request';

  my $json = $self->json_encode($request);

  my $client = $self->_cached_client || $self->connect_ws;

  $client->send_text_frame($json);

  my $res = $self->loop->run;

  unless ($self->_cached_client) {
    $self->loop->remove($client);
  }

  return $self->_jresponse_from_wsresponse($res);
}

sub connect_ws {
  my ($self) = @_;

  my $loop = $self->loop;

  weaken($loop);

  my $client = Net::Async::WebSocket::Client->new(
    on_text_frame => sub {
      my ($c, $f) = @_;

      $loop->stop($f);
    },
  );

  $client->{framebuffer} = Protocol::WebSocket::Frame->new(
    max_payload_size => 0
  );

  $self->loop->add($client);

  $client->connect(
    url => $self->ws_api_uri,
    req => Protocol::WebSocket::Request->new(
      headers => [
        ( $self->authorization
          ? ( Authorization => $self->authorization ) 
          : ()
        ),
      ],
      subprotocol => 'jmap',
    ),
  )->get;

  if ($self->cache_connection) {
    $self->_cached_client($client);
  }

  return $client;
}

sub _jresponse_from_wsresponse {
  my ($self, $ws_res) = @_;

  my ($data, $error);

  try {
    $data = $self->apply_json_types($self->json_decode( $ws_res ));
  } catch {
    $error = $_;
  };

  if (defined $error) {
    return JMAP::Tester::WebSocket::Result::Failure->new(
      ws_response => $ws_res,
      ident => $error,
    );
  }

  my ($items, $props);
  if (_HASH0($data)) {
    $props = $data;
    $items = $props->{methodResponses};
  } elsif (_ARRAY0($data)) {
    $props = {};
    $items = $data;
  } else {
    abort("illegal response to JMAP request: $data");
  }

  return JMAP::Tester::WebSocket::Response->new({
    items               => $items,
    ws_response         => $ws_res,
    wrapper_properties  => $props,
  });
}

1;

=pod

=encoding UTF-8

=head1 NAME

JMAP::Tester::WebSocket - a WebSocket JMAP client made for testing JMAP servers

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use JMAP::Tester::WebSocket;

  my $jtest = JMAP::Tester::WebSocket->new({
    ws_uri => 'ws://jmap.local/account/123',
  });

  my $response = $jtest->request([
    [ getMailboxes => {} ],
    [ getMessageUpdates => { sinceState => "123" } ],
  ]);

=head1 DESCRIPTION

This module provides a WebSockets wrapper around L<JMAP::Tester>.

See L<JMAP::Tester> for more information.

=head1 SEE ALSO

L<JMAP::Tester> - a JMAP client made for testing JMAP servers

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by FastMail, Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use JMAP::Tester::WebSocket;
#pod
#pod   my $jtest = JMAP::Tester::WebSocket->new({
#pod     ws_uri => 'ws://jmap.local/account/123',
#pod   });
#pod
#pod   my $response = $jtest->request([
#pod     [ getMailboxes => {} ],
#pod     [ getMessageUpdates => { sinceState => "123" } ],
#pod   ]);
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a WebSockets wrapper around L<JMAP::Tester>.
#pod
#pod See L<JMAP::Tester> for more information.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<JMAP::Tester> - a JMAP client made for testing JMAP servers
#pod
#pod =cut
