#!/usr/bin/env perl
# ABSTRACT: Role::CachedContent routes every request URL through the consumer's endpoint/auth seam (karr #94)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;
use LWP::UserAgent;

use Langertha::Engine::Gemini;

# karr #88 gave Engine::Gemini an endpoint/auth seam (gemini_api_version /
# gemini_auth_query / gemini_endpoint / gemini_url / gemini_model_url) so a
# second consumer of the Gemini dialect is a subclass, not a fork (ADR 0016
# decision 3). Role::CachedContent used to place ?key= and /v1beta itself at
# seven spots, so a subclass that overrode the seam got correct chat and
# model-listing URLs but kept hitting the Developer API for the whole
# cachedContents lifecycle - a half-converted shim.
#
# This file pins both halves: the Developer API still emits exactly the URLs
# it always did, and a subclass that moves base URL, API version, resource
# prefix and auth scheme moves the lifecycle with it.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# A recording LWP::UserAgent: the engine's user_agent attribute is typed
# 'LWP::UserAgent', and going through the real generate_http_request means
# we assert the URL that would actually go on the wire, headers included.
{
  package Test::RecordingUA;
  our @ISA = ('LWP::UserAgent');

  sub new {
    my ( $class, %args ) = @_;
    my $self = LWP::UserAgent::new($class);
    $self->{seen} = [];
    return $self;
  }

  sub seen { return $_[0]->{seen} }

  sub request {
    my ( $self, $req ) = @_;
    push @{ $self->{seen} }, $req;
    my $res = HTTP::Response->new( 200, 'OK' );
    $res->header( 'Content-Type' => 'application/json' );
    $res->content( $self->{body} // '{}' );
    return $res;
  }

  sub body { my ( $self, $body ) = @_; $self->{body} = $body; return; }
}

# Drives the whole lifecycle once and returns the requests in issue order.
sub run_lifecycle {
  my ( $engine, $ua ) = @_;

  $ua->body( $json->encode(
    { name => 'cachedContents/created', model => 'models/gemini-2.5-pro' } ) );
  $engine->create_cached_content( model => 'models/gemini-2.5-pro', ttl => '300s' );

  $ua->body( $json->encode(
    { name => 'cachedContents/abc', model => 'models/gemini-2.5-pro' } ) );
  $engine->get_cached_content('cachedContents/abc');

  $ua->body( $json->encode( { cachedContents => [
    { name => 'cachedContents/abc', model => 'models/gemini-2.5-pro' } ] } ) );
  $engine->list_cached_contents;

  $ua->body( $json->encode(
    { name => 'cachedContents/abc', model => 'models/gemini-2.5-pro' } ) );
  $engine->update_cached_content( 'cachedContents/abc', ttl => '600s' );

  $ua->body('{}');
  $engine->delete_cached_content('cachedContents/abc');

  return @{ $ua->seen };
}

# --- Developer API: the URLs the lifecycle has always emitted -------------

{
  my $ua = Test::RecordingUA->new;
  my $engine = Langertha::Engine::Gemini->new(
    api_key    => 'test_api_key_123',
    model      => 'gemini-2.5-pro',
    user_agent => $ua,
  );

  my @req = run_lifecycle( $engine, $ua );
  my $base = 'https://generativelanguage.googleapis.com/v1beta/cachedContents';

  is( scalar @req, 5, 'lifecycle issued five requests' );

  is( join( ' ', map { uc $_->method } @req ),
    'POST GET GET PATCH DELETE',
    'create / get / list / update / delete use the documented HTTP verbs' );

  is( "" . $req[0]->uri, "$base?key=test_api_key_123",
    'create posts to the cachedContents collection with the key in the query' );
  is( "" . $req[1]->uri, "$base/abc?key=test_api_key_123",
    'get addresses the single resource' );
  is( "" . $req[2]->uri, "$base?key=test_api_key_123",
    'list walks the collection' );
  is( "" . $req[3]->uri, "$base/abc?key=test_api_key_123&updateMask=ttl",
    'update keeps the key ahead of updateMask' );
  is( "" . $req[4]->uri, "$base/abc?key=test_api_key_123",
    'delete addresses the single resource' );
}

# --- A shim that overrides the seam: Vertex-shaped path, bearer auth ------

{
  package Test::Gemini::CachedContentShim;
  use Moose;
  extends 'Langertha::Engine::Gemini';

  has '+url' => ( default => sub { 'https://vertex-shim.invalid' } );

  sub gemini_api_version { 'v1' }
  sub gemini_auth_query  { return () }

  # Vertex AI hangs its resources under a project/location prefix; the path
  # half of the seam is one override and every endpoint follows.
  around gemini_endpoint => sub {
    my ( $orig, $self, $path ) = @_;
    return $self->$orig( 'projects/p1/locations/europe-west4/' . $path );
  };

  around update_request => sub {
    my ( $orig, $self, $request ) = @_;
    $self->$orig($request);
    $request->header( 'authorization', 'Bearer ' . $self->api_key );
    return;
  };

  __PACKAGE__->meta->make_immutable;
}

{
  my $ua = Test::RecordingUA->new;
  my $shim = Test::Gemini::CachedContentShim->new(
    api_key    => 'adc_bearer_789',
    model      => 'gemini-2.5-pro',
    user_agent => $ua,
  );

  ok( $shim->supports('cached_content'),
    'the shim still advertises the capability it inherited' );

  my @req = run_lifecycle( $shim, $ua );
  my $base =
    'https://vertex-shim.invalid/v1/projects/p1/locations/europe-west4/cachedContents';

  is( "" . $req[0]->uri, $base,
    'create follows the overridden base URL, version and resource prefix' );
  is( "" . $req[1]->uri, "$base/abc", 'get follows the seam' );
  is( "" . $req[2]->uri, "$base", 'list follows the seam' );
  is( "" . $req[3]->uri, "$base/abc?updateMask=ttl",
    'update keeps updateMask when the auth query is empty' );
  is( "" . $req[4]->uri, "$base/abc", 'delete follows the seam' );

  # The two failure modes the old role had, stated directly.
  my @url = map { "" . $_->uri } @req;
  is( scalar( grep { /[?&]key=/ } @url ), 0,
    'no request smuggles ?key= past an auth scheme that does not use it' );
  is( scalar( grep { m{/v1beta/} } @url ), 0,
    'no request falls back to the hardcoded /v1beta' );

  is( scalar( grep { ( $_->header('authorization') // '' ) eq 'Bearer adc_bearer_789' } @req ),
    5, 'every lifecycle request carries the shim credential in a header' );

  # The credential-free resource URLs move too - they are what a caller uses
  # to name a cache rather than fetch it.
  is( $shim->_cached_contents_url, $base,
    '_cached_contents_url is the seam endpoint, without a credential' );
  is( $shim->_cached_content_url('cachedContents/zzz'), "$base/zzz",
    '_cached_content_url is the seam endpoint, without a credential' );

  # The chat endpoint moved in the same step (karr #88) - the point of the
  # ticket is that the lifecycle now agrees with it.
  is( "" . $shim->chat('hi')->uri,
    'https://vertex-shim.invalid/v1/projects/p1/locations/europe-west4/'
      . 'models/gemini-2.5-pro:generateContent',
    'chat and cachedContents agree on base URL, version and prefix' );
}

# --- The coupling is declared, not discovered at the first HTTP call ------

{
  # Role::CachedContent `requires` the seam, so composing it on a consumer
  # that does not speak the Gemini dialect fails at composition time.
  require Moose::Meta::Class;
  my $composed = eval {
    Moose::Meta::Class->create(
      'Test::CachedContent::NoSeam',
      methods => { json => sub { } },
      roles   => ['Langertha::Role::CachedContent'],
    );
    1;
  };
  my $err = $@;
  ok( !$composed, 'composing the role without the seam does not succeed' );
  like( $err, qr/requires the method(?:s)? .*gemini_/,
    'Moose names the missing seam method at composition time' );
}

# The name validator still rejects a malformed resource name before any URL
# is built, on both the credential-free and the request path.
{
  my $engine = Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro' );

  eval { $engine->_cached_content_url('nope/123') };
  like( $@, qr/cachedContents\/\{id\}/,
    '_cached_content_url rejects a foreign resource name' );

  eval { $engine->_cached_content_path('cachedContents/a/b') };
  like( $@, qr/cachedContents\/\{id\}/,
    '_cached_content_path rejects a nested name' );
}

done_testing;
