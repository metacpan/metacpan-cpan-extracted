#!/usr/bin/env perl
# ABSTRACT: Gemini cachedContents wire shape: create body tools, server expireTime, generateContent with a bound cache (karr k327)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Gemini;
use Langertha::CachedContent;
use Langertha::Tool;

# karr k327, three wire truths of the Gemini explicit cache
# (ai.google.dev/api/caching):
#  1. cachedContents.create takes `tools: Tool[]`, each Tool being
#     { functionDeclarations: [...] } -- the shape generateContent takes. The
#     create body used to peel the wrapper off and send bare declarations,
#     which the server cannot read as Tool objects.
#  2. `expiration` is a proto oneof, flat in JSON: a resource comes back with
#     a top-level expireTime (ttl is input only). from_hash read only an
#     `expiration` wrapper, so expire_time was never set and is_expired was
#     always false for a real server resource.
#  3. A generateContent request naming a cachedContent may not also set
#     systemInstruction, tools or toolConfig; the server answers 400
#     "CachedContent can not be used with GenerateContent request setting
#     system_instruction, tools or tool_config. Proposed fix: move those
#     values to CachedContent from GenerateContent request." Those come from
#     the cache, so the engine leaves them out and carps once.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $tool = {
  name         => 'lookup',
  description  => 'Look a word up',
  input_schema => { type => 'object', properties => { word => { type => 'string' } } },
};

# --- 1. create body carries Tool objects -------------------------------------

{
  my $cc = Langertha::CachedContent->new(
    model => 'models/gemini-2.5-pro', ttl => '60s', tools => [$tool],
  );
  my $tools = $cc->to_create_body->{tools};
  is_deeply( $tools, Langertha::Tool->format_list( 'gemini', [$tool] ),
    'create body tools is the generateContent tools shape' );
  is( ref $tools->[0]{functionDeclarations}, 'ARRAY',
    'each Tool wraps its functionDeclarations' );
  is( $tools->[0]{functionDeclarations}[0]{name}, 'lookup',
    'the declaration sits inside the Tool' );
}

# --- 2. server resource: top-level expireTime --------------------------------

{
  # CachedContent JSON representation as the reference documents it: output
  # fields next to a flat expireTime.
  my $resource = {
    name          => 'cachedContents/abc123',
    displayName   => 'reviewer',
    model         => 'models/gemini-2.5-pro',
    createTime    => '2019-12-31T23:00:00.123456Z',
    updateTime    => '2019-12-31T23:00:00.123456Z',
    expireTime    => '2020-01-01T00:00:00Z',
    usageMetadata => { totalTokenCount => 4096 },
  };
  my $cc = Langertha::CachedContent->from_hash($resource);
  is( $cc->expire_time, '2020-01-01T00:00:00Z', 'top-level expireTime is read' );
  ok( $cc->is_expired, 'a resource past its expireTime is_expired' );

  my $live = Langertha::CachedContent->from_hash( { %$resource, expireTime => '2099-01-01T00:00:00Z' } );
  ok( !$live->is_expired, 'a resource before its expireTime is not expired' );

  my $both = eval { Langertha::CachedContent->from_hash( { %$resource, ttl => '60s' } ) };
  is( $@, '', 'a response carrying expireTime and ttl does not croak' );
  is( $both && $both->expire_time, '2020-01-01T00:00:00Z', 'expireTime wins over ttl' );

  my $wrapped = Langertha::CachedContent->from_hash( { name => 'cachedContents/w', model => 'm',
    expiration => { expireTime => '2020-01-01T00:00:00Z' } } );
  is( $wrapped->expire_time, '2020-01-01T00:00:00Z', 'the expiration wrapper is still read' );
}

# --- 3. generateContent with a bound cache -----------------------------------

sub engine {
  my (%args) = @_;
  return Langertha::Engine::Gemini->new(
    api_key => 'k', model => 'gemini-2.5-pro', system_prompt => 'Be terse.', %args );
}

sub bound { Langertha::CachedContent->new( name => 'cachedContents/abc', model => 'models/gemini-2.5-pro' ) }

{
  my $e = engine( cached_content => bound() );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $body = $json->decode( $e->chat_request( $e->chat_messages('hi'),
    tools => Langertha::Tool->format_list( 'gemini', [$tool] ), tool_choice => 'auto' )->content );
  is( $body->{cachedContent}, 'cachedContents/abc', 'cachedContent is on the body' );
  ok( !exists $body->{systemInstruction}, 'no systemInstruction next to the cache' );
  ok( !exists $body->{tools}, 'no tools next to the cache' );
  ok( !exists $body->{toolConfig}, 'no toolConfig next to the cache' );
  is( $body->{contents}[0]{parts}[0]{text}, 'hi', 'the user turn still goes out' );

  my $sbody = $json->decode( $e->chat_stream_request( $e->chat_messages('hi'),
    tools => Langertha::Tool->format_list( 'gemini', [$tool] ), tool_choice => 'auto' )->content );
  is( $sbody->{cachedContent}, 'cachedContents/abc', 'streaming: cachedContent is on the body' );
  ok( !exists $sbody->{$_}, "streaming: no $_ next to the cache" ) for qw( systemInstruction tools toolConfig );

  is( scalar @warnings, 1, 'carps once per engine' );
  like( $warnings[0] // '', qr/cached_content.*systemInstruction.*tools.*toolConfig/s,
    'the carp names the fields and the cache' );
}

{
  # Nothing to drop: no carp.
  my $e = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-2.5-pro', cached_content => bound() );
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $e->chat_request( $e->chat_messages('hi') );
  is( scalar @warnings, 0, 'no carp when the request sets none of them' );
}

{
  # Without a bound cache all three reach the wire as before.
  my $e = engine();
  my $body = $json->decode( $e->chat_request( $e->chat_messages('hi'),
    tools => Langertha::Tool->format_list( 'gemini', [$tool] ), tool_choice => 'auto' )->content );
  ok( exists $body->{$_}, "without a cache $_ is sent" ) for qw( systemInstruction tools toolConfig );
}

done_testing;
