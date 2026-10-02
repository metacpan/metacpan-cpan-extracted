#!/usr/bin/env perl
# ABSTRACT: Langertha::Request::SyncHTTP satisfies the do_request contract over LWP, sync
use strict; use warnings;
use Test2::Bundle::More;
use HTTP::Response;
use HTTP::Request;
use HTTP::Status ();
use Langertha::Request::SyncHTTP;

# Mock UA: no content callback -> returns a canned HTTP::Response
{
  package MockUA;
  use Moose;
  has calls => (is => 'ro', default => sub { [] });
  sub request {
    my ($self, $request, $content_cb) = @_;
    push @{$self->calls}, $request;
    my $response = HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'text/plain' ], 'hello');
    return $response;
  }
  __PACKAGE__->meta->make_immutable;
}

my $client = Langertha::Request::SyncHTTP->new( user_agent => MockUA->new );
my $future = $client->do_request( request => HTTP::Request->new(GET => 'http://x/') );
isa_ok($future, ['Future'], 'do_request returns a Future');
ok($future->is_ready, 'future is already complete (no loop needed)');
my $response = $future->get;
is($response->code, 200, 'resolves to the HTTP::Response');
is($response->decoded_content, 'hello', 'body present');

# Streaming mock UA, faithful to LWP::Protocol::collect: the content callback
# ($data, $response, $protocol) fires per chunk only for a success response;
# a non-success body is accumulated on the response and the callback is never
# called. t/45_sync_http_real_lwp.t checks the same against a real LWP.
{
  package MockStreamUA;
  use Moose;
  has chunks => (is => 'ro', default => sub { [qw(foo bar baz)] });
  has code   => (is => 'ro', default => 200);
  sub request {
    my ($self, $request, $content_cb) = @_;
    my $response = HTTP::Response->new($self->code, HTTP::Status::status_message($self->code),
      [ 'Content-Type' => 'text/event-stream' ]);
    if ($response->is_success) {
      $content_cb->($_, $response) for @{$self->chunks};
    }
    else {
      $response->add_content($_) for @{$self->chunks};
    }
    return $response;
  }
  __PACKAGE__->meta->make_immutable;
}

my @seen; my $header_response; my $end_seen = 0;
my $sclient = Langertha::Request::SyncHTTP->new( user_agent => MockStreamUA->new );
my $sfuture = $sclient->do_request(
  request   => HTTP::Request->new(GET => 'http://x/stream'),
  on_header => sub {
    my ($response) = @_;
    $header_response = $response;
    return sub { my ($data) = @_; defined $data ? push(@seen, $data) : $end_seen++ };
  },
);
ok($sfuture->is_ready, 'streaming future already complete');
is($header_response->code, 200, 'on_header got the response');
is_deeply(\@seen, [qw(foo bar baz)], 'chunks delivered incrementally, in order');
is($end_seen, 1, 'end-of-body signalled once with undef');
is($sfuture->get->code, 200, 'future resolves to the response');

# Non-success: LWP never calls the content callback, the shim must still call
# on_header (the caller's is_success check depends on it) and hand over the body.
{
  my @error_seen; my $error_header; my $error_end = 0;
  my $eclient = Langertha::Request::SyncHTTP->new(
    user_agent => MockStreamUA->new( code => 401, chunks => ['{"error":"bad key"}'] ) );
  my $efuture = $eclient->do_request(
    request   => HTTP::Request->new(GET => 'http://x/stream'),
    on_header => sub {
      ($error_header) = @_;
      return sub { my ($data) = @_; defined $data ? push(@error_seen, $data) : $error_end++ };
    },
  );
  ok($efuture->is_done, '401 resolves the future (contract)');
  is($error_header && $error_header->code, 401, 'on_header called with the 401 response');
  is_deeply(\@error_seen, ['{"error":"bad key"}'], 'error body handed to the chunk-sub');
  is($error_end, 1, 'end-of-body signalled once');
}

done_testing;
