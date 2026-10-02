package Langertha::Request::SyncHTTP;
# ABSTRACT: Synchronous LWP-backed HTTP client satisfying the async do_request contract
our $VERSION = '0.503';
use Moose;
use Future;

has user_agent => (
  is => 'ro',
  required => 1,
);


sub do_request {
  my ( $self, %args ) = @_;
  my $request   = $args{request};
  my $on_header = $args{on_header};

  if ($on_header) {
    my ( $chunk_handler, $header_seen, $callback_error );
    my $response = $self->user_agent->request($request, sub {
      my ( $data, $header_response ) = @_;
      my $ok = eval {
        unless ($header_seen) {
          $header_seen   = 1;
          $chunk_handler = $on_header->($header_response);
        }
        $chunk_handler->($data) if $chunk_handler;
        1;
      };
      return if $ok;
      # Remember the original exception (objects survive), then die again so
      # LWP stops reading the body.
      $callback_error = $@ || "streaming callback died\n";
      die $callback_error;
    });

    # LWP catches a die in the content callback (and a mid-body read failure)
    # and records it as X-Died on an otherwise successful-looking response.
    # Fail like Net::Async::HTTP does instead of resolving a truncated stream.
    return Future->fail( $callback_error, http => $response, $request )
      if defined $callback_error;
    if ( defined( my $died = $response->header('X-Died') ) ) {
      $died .= "\n" unless $died =~ /\n\z/;
      return Future->fail( $died, http => $response, $request );
    }

    # LWP never runs the content callback for a non-success response (the
    # body is accumulated on the response instead), nor for an internal error
    # (connection refused, DNS, timeout) or an empty body. Net::Async::HTTP
    # calls on_header for every response and hands it the body, so do the
    # same here once the request is done.
    my $ok = eval {
      unless ($header_seen) {
        $header_seen   = 1;
        $chunk_handler = $on_header->($response);
        my $body = $response->content;
        $chunk_handler->($body) if $chunk_handler && defined $body && length $body;
      }
      $chunk_handler->(undef) if $chunk_handler;   # the async end-of-body signal
      1;
    };
    return Future->fail( $@ || "streaming callback died\n", http => $response, $request )
      unless $ok;
    return Future->done($response);
  }

  my $response = $self->user_agent->request($request);
  return Future->done($response);
}


__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Request::SyncHTTP - Synchronous LWP-backed HTTP client satisfying the async do_request contract

=head1 VERSION

version 0.503

=head2 user_agent

The synchronous HTTP client used to run the request, normally an
L<LWP::UserAgent>. Any object with a
C<< ->request($http_request [, $content_cb]) >> method that returns an
L<HTTP::Response> satisfies the contract. Required.

=head2 do_request

    my $future = $client->do_request( request => $http_request );

    my $future = $client->do_request(
      request   => $http_request,
      on_header => sub {
        my ($response) = @_;
        return sub { my ($data) = @_; ... };   # per-chunk, undef at end
      },
    );

Runs C<$http_request> synchronously through L</user_agent> and returns an
already-complete L<Future> resolving to the L<HTTP::Response>. No event loop
is involved: because the future is already ready, any C<await> on it (or
C<< ->get >>) resolves immediately, so the whole C<_f> chain runs
synchronously and sequentially.

When an C<on_header> callback is given the request streams: L<LWP::UserAgent>'s
per-chunk content callback is bridged to the contract — C<on_header> is called
once with the L<HTTP::Response> (headers) and returns a chunk-sub, which then
receives each body chunk as LWP reads it from the socket and finally C<undef>
once to signal end-of-body. Delivery is incremental (the first chunk reaches
the caller before the body has finished arriving, so time-to-first-token is
real) but blocking: the calling thread waits inside the request until the
stream ends.

LWP runs the content callback only for a successful response. For a
non-success status, and for an LWP-internal error response (connection
refused, DNS failure, timeout), the shim still calls C<on_header> once with
the response and hands the chunk-sub the accumulated body, then C<undef> —
the same sequence L<Net::Async::HTTP> produces, so the caller's
C<< $response->is_success >> check fires the same way on both backends.

If the chunk-sub (or C<on_header>) dies, or LWP aborts reading the body
mid-stream (recorded in its C<X-Died> header), the returned future B<fails>
with that exception and no C<undef> end signal is sent: a truncated stream is
never resolved as a success.

This is the drop-in fallback backend for the async C<do_request> contract
(L<Langertha::Role::AsyncHTTP>): HTTP error statuses (4xx/5xx) B<resolve>
with the response — they do not fail the future — so the caller checks
C<< $response->is_success >>, exactly as with L<Net::Async::HTTP>.

=head1 SEE ALSO

=over

=item * L<Langertha::Role::AsyncHTTP> - Backend selection that falls back to this shim

=item * L<Langertha::Role::HTTP> - Provides the C<user_agent> this shim runs over

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
