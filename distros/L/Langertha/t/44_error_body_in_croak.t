#!/usr/bin/env perl
# ABSTRACT: Non-success HTTP responses surface the provider error body in the croak (karr k181)
use strict;
use warnings;
use Test2::Bundle::More;
use HTTP::Response;
use HTTP::Request;

use Langertha::Engine::vLLM;

# A mock LWP::UserAgent that hands back a canned response for the streaming
# path, which fetches through $self->user_agent->request($request).
{
  package MockUA;
  use parent -norequire, 'LWP::UserAgent';
  sub new {
    my ( $class, $canned ) = @_;
    my $self = $class->SUPER::new;
    $self->{_canned} = $canned;
    return $self;
  }
  sub request { return $_[0]->{_canned} }
}

# The real-world payload from k155: a 400 whose JSON body is the only place
# the actual cause ("Unsupported value: 'temperature' ...") appears.
my $error_json =
  '{"error":{"message":"Unsupported value: \'temperature\' does not support '
  . '0.7 with this model. Only the default (1) value is supported.",'
  . '"type":"invalid_request_error","param":"temperature",'
  . '"code":"unsupported_value"}}';

sub error_response {
  my ($body) = @_;
  my $http = HTTP::Response->new(400, 'Bad Request');
  $http->header('Content-Type' => 'application/json');
  $http->content($body) if defined $body;
  return $http;
}

my $engine = Langertha::Engine::vLLM->new( url => 'http://x' );

# --- parse_response: provider error body is appended --------------------------
{
  my $err = do {
    local $@;
    eval { $engine->parse_response(error_response($error_json)) };
    $@;
  };
  like($err, qr/request failed: 400 Bad Request/,
    'parse_response: status-line prefix preserved');
  like($err, qr/Unsupported value: 'temperature'/,
    'parse_response: provider error message surfaced in croak');
  like($err, qr/unsupported_value/,
    'parse_response: provider error code surfaced too');
}

# --- parse_response: empty-body fallback keeps today's message ----------------
{
  my $err = do {
    local $@;
    eval { $engine->parse_response(error_response(undef)) };
    $@;
  };
  like($err, qr/request failed: 400 Bad Request/,
    'parse_response: empty body still croaks with status line');
  unlike($err, qr/400 Bad Request\s+-/,
    'parse_response: empty body appends no separator');
}

# --- parse_response: whitespace/newlines collapsed to one-ish line ------------
{
  my $err = do {
    local $@;
    eval { $engine->parse_response(error_response(qq({"error":\n  {"message":"multi\nline"}}))) };
    $@;
  };
  like($err, qr/\{"error": \{"message":"multi line"\}\}/,
    'parse_response: whitespace and newlines collapsed');
}

# --- parse_response: long body is length-limited with an ellipsis -------------
{
  my $long = '{"error":{"message":"' . ('x' x 2000) . '"}}';
  my $err = do {
    local $@;
    eval { $engine->parse_response(error_response($long)) };
    $@;
  };
  like($err, qr/\.\.\./, 'parse_response: over-long body truncated with ellipsis');
  # The appended body is capped; the whole 2000-char message must not appear.
  unlike($err, qr/x{600}/, 'parse_response: full over-long body not emitted');
}

# --- execute_streaming_request: provider error body is appended --------------
{
  my $streaming = Langertha::Engine::vLLM->new(
    url        => 'http://x',
    user_agent => MockUA->new(error_response($error_json)),
  );
  my $err = do {
    local $@;
    eval {
      $streaming->execute_streaming_request(HTTP::Request->new(POST => 'http://x'));
    };
    $@;
  };
  like($err, qr/streaming request failed: 400 Bad Request/,
    'streaming: status-line prefix preserved');
  like($err, qr/Unsupported value: 'temperature'/,
    'streaming: provider error message surfaced in croak');
}

# --- execute_streaming_request: empty-body fallback --------------------------
{
  my $streaming = Langertha::Engine::vLLM->new(
    url        => 'http://x',
    user_agent => MockUA->new(error_response(undef)),
  );
  my $err = do {
    local $@;
    eval {
      $streaming->execute_streaming_request(HTTP::Request->new(POST => 'http://x'));
    };
    $@;
  };
  like($err, qr/streaming request failed: 400 Bad Request/,
    'streaming: empty body still croaks with status line');
  unlike($err, qr/400 Bad Request\s+-/,
    'streaming: empty body appends no separator');
}

done_testing;
