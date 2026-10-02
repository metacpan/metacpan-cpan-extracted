#!/usr/bin/env perl
# ABSTRACT: Gemini endpoint + auth seam - the request URLs and their override points

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::Gemini;

# A second consumer of the Gemini dialect (Vertex AI express/standard, a
# Gemini-native gateway) differs from the Developer API only in base URL,
# API version, model-path prefix and auth scheme - never in the request
# envelope (ADR 0016, karr #88). Two things must hold for that to be a
# subclass rather than a fork:
#
#   1. the Developer API keeps emitting exactly the URLs it always did, and
#   2. those URLs are decided nowhere but in the seam methods.
#
# The literal URLs below are the pin for (1) - a future refactor that shifts
# a byte, a query-parameter order or the alt=sse switch fails here instead of
# failing against Google.

my $base = 'https://generativelanguage.googleapis.com/v1beta';

my $gemini = Langertha::Engine::Gemini->new(
  api_key => 'test_api_key_123',
  model   => 'gemini-2.0-flash',
);

is( "" . $gemini->chat('hi')->uri,
  "$base/models/gemini-2.0-flash:generateContent?key=test_api_key_123",
  'generateContent URL: model path, then the key in the query string' );

is( "" . $gemini->chat_stream('hi')->uri,
  "$base/models/gemini-2.0-flash:streamGenerateContent?key=test_api_key_123&alt=sse",
  'streamGenerateContent URL: key first, alt=sse after it' );

is( "" . $gemini->list_models_request->uri,
  "$base/models?key=test_api_key_123",
  'model listing URL' );

is( "" . $gemini->list_models_request( pageToken => 'tok123' )->uri,
  "$base/models?key=test_api_key_123&pageToken=tok123",
  'model listing URL keeps the key when a page token is appended' );

# The builders on their own, so a caller can see the contract without
# reaching through a request object.
is( $gemini->gemini_api_version, 'v1beta', 'API version segment' );

is( $gemini->gemini_url('models'), "$base/models?key=test_api_key_123",
  'gemini_url applies the auth query to a plain path' );

is( $gemini->gemini_url( 'models', pageSize => 5 ),
  "$base/models?key=test_api_key_123&pageSize=5",
  'gemini_url puts the auth query before the caller query' );

is( $gemini->gemini_model_url( 'gemini-3-pro-preview', 'generateContent' ),
  "$base/models/gemini-3-pro-preview:generateContent?key=test_api_key_123",
  'gemini_model_url builds models/{model}:{method}' );

is_deeply( [ $gemini->gemini_auth_query ], [ key => 'test_api_key_123' ],
  'gemini_auth_query carries the credential as a query pair' );

# api_key stays required for the Developer API: no key, no request.
{
  local %ENV = %ENV;
  delete $ENV{LANGERTHA_GEMINI_API_KEY};
  my $engine = Langertha::Engine::Gemini->new( model => 'gemini-2.0-flash' );
  my $url = eval { $engine->gemini_url('models') };
  like( $@, qr/requires LANGERTHA_GEMINI_API_KEY or api_key/,
    'Developer API still croaks without an api_key' );
}

# The seam is the whole extension surface: a consumer on another base URL,
# another API version, another model-path prefix and header auth overrides
# four methods and inherits every request body unchanged.
{
  package Test::Gemini::HeaderAuth;
  use Moose;
  extends 'Langertha::Engine::Gemini';

  has '+url' => ( default => sub { 'https://example-gateway.invalid' } );

  sub gemini_api_version { 'v1' }
  sub gemini_auth_query  { return () }

  sub gemini_model_url {
    my ( $self, $model, $method, @query ) = @_;
    return $self->gemini_url(
      'publishers/google/models/' . $model . ':' . $method, @query );
  }

  around update_request => sub {
    my ( $orig, $self, $request ) = @_;
    $self->$orig($request);
    $request->header( 'authorization', 'Bearer ' . $self->api_key );
    return;
  };

  __PACKAGE__->meta->make_immutable;
}

{
  my $shim = Test::Gemini::HeaderAuth->new(
    api_key => 'bearer_token_456',
    model   => 'gemini-2.0-flash',
  );
  my $shim_base = 'https://example-gateway.invalid/v1';

  my $request = $shim->chat('hi');
  is( "" . $request->uri,
    "$shim_base/publishers/google/models/gemini-2.0-flash:generateContent",
    'overriding the seam moves base URL, version and model path at once' );
  is( $request->header('authorization'), 'Bearer bearer_token_456',
    'the credential can leave the query string for a header' );

  is( "" . $shim->chat_stream('hi')->uri,
    "$shim_base/publishers/google/models/gemini-2.0-flash:streamGenerateContent?alt=sse",
    'streaming keeps alt=sse when the auth query is empty' );

  is( "" . $shim->list_models_request->uri, "$shim_base/models",
    'model listing follows the same seam' );

  is( $request->header('content-type'), 'application/json',
    'the inherited request envelope is untouched' );
}

done_testing;
