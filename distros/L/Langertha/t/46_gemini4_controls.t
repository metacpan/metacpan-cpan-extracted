#!/usr/bin/env perl
# ABSTRACT: Gemini 4 (gemini-4-argon) request controls: thinkingLevel low|medium|high, no thinkingBudget, no explicit cache, no temperature (karr k381)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Gemini;
use Langertha::Reasoning;
use Langertha::Reasoning::Profile;
use Langertha::CachedContent;

# karr k381. Gemini 4 changes the request controls against Gemini 3
# (ai.google.dev/gemini-api/docs/generate-content/latest-model and the Vertex
# gemini-4-argon guide, fetched 2026-10-19; documentation-derived, not
# live-verified):
#  - thinkingLevel takes low|medium|high, medium is the default; Vertex answers
#    minimal with 400. Before k381 no Profile row matched gemini-4, so the id
#    took the binary low|high collapse of an unknown model and reasoning_effort
#    'medium' went out as thinkingLevel=low -- a silent downgrade below the
#    model's own default.
#  - thinkingBudget answers 400 on Vertex (AI Studio maps it with a warning):
#    Langertha never sends it on Gemini 4; asking for it croaks, as on Gemini 3.
#
# The family is gemini-4 followed by a non-digit (ADR 0023 k196 guard):
# gemini-40 is an unknown id.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub level_for {
  my ( $model, $effort ) = @_;
  my %kw = Langertha::Reasoning->new( effort => $effort, model => $model )->to('gemini');
  return $kw{thinkingConfig}{thinkingLevel};
}

sub body_for {
  my ( %args ) = @_;
  my $builder = delete $args{builder} // 'chat_request';
  my $controls = delete $args{controls} // {};
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', %args );
  return $json->decode( $engine->$builder(
    [ { role => 'user', content => 'hi' } ], controls => $controls )->content );
}

# --- reasoning: the Gemini 4 Profile row --------------------------------------

my %want_g4 = ( none => 'low', minimal => 'low', low => 'low', medium => 'medium',
                high => 'high', xhigh => 'high', max => 'high' );
for my $model (qw( gemini-4-argon gemini-4-argon-preview gemini-4.1-flash )) {
  ok( Langertha::Reasoning::Profile->for_model($model)->is_gemini3,
    "$model resolves to a thinkingLevel family row" );
  for my $effort ( sort keys %want_g4 ) {
    is( level_for( $model, $effort ), $want_g4{$effort},
      "$model: effort $effort -> thinkingLevel $want_g4{$effort}" );
  }
}

# Multi-digit guard: gemini-40 is not Gemini 4, it is an unknown id.
is( level_for( 'gemini-40-pro', 'medium' ), 'low',
  'gemini-40-pro is an unknown id: binary low|high collapse' );
ok( !Langertha::Reasoning::Profile->for_model('gemini-40-pro')->is_gemini3,
  'gemini-40-pro does not resolve to the Gemini 4 row' );

# Regression: the Gemini 3 rows are unchanged.
is( level_for( 'gemini-3-flash-preview', 'minimal' ), 'minimal', 'gemini-3-flash-preview keeps minimal' );
is( level_for( 'gemini-3.7-flash', 'minimal' ),       'low',     'gemini-3.7-flash still clamps minimal to low' );
is( level_for( 'gemini-3-pro-preview', 'medium' ),    'low',     'gemini-3-pro-preview still binary' );

# On the wire: generationConfig.thinkingConfig.thinkingLevel, both routes.
for my $builder (qw( chat_request chat_stream_request )) {
  is_deeply(
    body_for( model => 'gemini-4-argon', reasoning_effort => 'medium', builder => $builder )
      ->{generationConfig}{thinkingConfig},
    { thinkingLevel => 'medium' },
    "$builder: gemini-4-argon reasoning_effort=medium -> thinkingLevel medium" );
  is_deeply(
    body_for( model => 'gemini-4-argon', builder => $builder, controls => { reasoning_effort => 'minimal' } )
      ->{generationConfig}{thinkingConfig},
    { thinkingLevel => 'low' },
    "$builder: per-request minimal -> thinkingLevel low (minimal is not accepted)" );
}

# thinking_budget: never on the Gemini 4 wire; asking for it croaks before the
# request is built (same rule as Gemini 3).
{
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-4-argon',
    thinking_budget => 1024 );
  ok( !$engine->supports('thinking_budget'), 'gemini-4-argon does not advertise thinking_budget' );
  ok( $engine->supports('reasoning_effort'), 'gemini-4-argon advertises reasoning_effort' );
  like( eval { $engine->chat('hi'); 1 } ? '' : $@, qr/thinking_budget' is only valid/,
    'thinking_budget on gemini-4-argon croaks instead of sending thinkingBudget' );
  my $per_request = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-4-argon' );
  like( eval { $per_request->chat_request( [ { role => 'user', content => 'hi' } ],
          controls => { thinking_budget => 512 } ); 1 } ? '' : $@,
    qr/thinking_budget' is only valid/, 'a per-request thinking_budget croaks too' );
}

# Regression: Gemini 2.5 still takes thinkingBudget.
is_deeply(
  body_for( model => 'gemini-2.5-flash', thinking_budget => 1024 )->{generationConfig}{thinkingConfig},
  { thinkingBudget => 1024 }, 'gemini-2.5-flash still sends thinkingBudget' );

# --- capabilities -------------------------------------------------------------
#
# Explicit caching "is not supported on Gemini 4 Argon and returns an error"
# (only implicit caching remains); sampling parameters "are ignored" and the
# migration guide says to remove them.

my %caps_want = (
  'gemini-4-argon'         => { cached_content => 0, temperature => 0, thinking_budget => 0, reasoning_effort => 1 },
  'gemini-4.1-flash'       => { cached_content => 0, temperature => 0, thinking_budget => 0, reasoning_effort => 1 },
  'gemini-3-flash-preview' => { cached_content => 1, temperature => 1, thinking_budget => 0, reasoning_effort => 1 },
  'gemini-3.8-flash'       => { cached_content => 1, temperature => 1, thinking_budget => 0, reasoning_effort => 1 },
  'gemini-2.5-pro'         => { cached_content => 1, temperature => 1, thinking_budget => 1, reasoning_effort => 0 },
  'gemini-40-pro'          => { temperature => 1 },
);
for my $model ( sort keys %caps_want ) {
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => $model );
  for my $cap ( sort keys %{ $caps_want{$model} } ) {
    is( $engine->supports($cap) ? 1 : 0, $caps_want{$model}{$cap},
      "$model: supports('$cap') is $caps_want{$model}{$cap}" );
  }
}

# --- temperature: dropped on Gemini 4, with the shared drop carp ------------

sub temp_probe {
  my ( %args ) = @_;
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  my $body = body_for(%args);
  return ( $body->{generationConfig}, scalar grep { /dropping temperature=/ } @warns );
}

for my $builder (qw( chat_request chat_stream_request )) {
  my ( $gc, $carps ) = temp_probe( model => 'gemini-4-argon', temperature => 0.7, builder => $builder );
  ok( !exists $gc->{temperature}, "$builder: gemini-4-argon temperature attribute not sent" );
  is( $carps, 1, "$builder: dropping a caller temperature 0.7 carps" );

  ( $gc, $carps ) = temp_probe( model => 'gemini-4-argon', builder => $builder,
    controls => { temperature => 0.2 } );
  ok( !exists $gc->{temperature}, "$builder: per-request temperature not sent on gemini-4-argon" );
  is( $carps, 1, "$builder: per-request drop carps" );

  ( $gc, $carps ) = temp_probe( model => 'gemini-4-argon', temperature => 1, builder => $builder );
  ok( !exists $gc->{temperature}, "$builder: temperature=1 not sent either" );
  is( $carps, 0, "$builder: temperature=1 is dropped quietly" );

  # Regression: Gemini 3 / 2.5 / 2.0 keep sending temperature, without a carp.
  for my $model (qw( gemini-3-flash-preview gemini-2.5-flash gemini-2.0-flash gemini-40-pro )) {
    ( $gc, $carps ) = temp_probe( model => $model, temperature => 0.7, builder => $builder );
    is( $gc->{temperature}, 0.7, "$builder: $model still sends temperature" );
    is( $carps, 0, "$builder: $model does not carp" );
  }
}

# --- explicit cache: croak instead of a server error --------------------------
#
# A bound cache on a Gemini 4 request croaks before the request is built.
# Leaving the cachedContent reference out would answer without the cached
# contents (and without the systemInstruction / tools the cache owns, ADR 0035),
# so dropping it is not an option. Nothing is sent: the builders only build.

{
  my $cc = Langertha::CachedContent->new( name => 'cachedContents/abc', model => 'models/gemini-3-flash-preview' );
  for my $builder (qw( chat_request chat_stream_request )) {
    my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-4-argon',
      cached_content => $cc );
    like( eval { $engine->$builder( [ { role => 'user', content => 'hi' } ] ); 1 } ? '' : $@,
      qr/cached_content cachedContents\/abc is bound, but model 'gemini-4-argon' has no explicit context caching/,
      "$builder: bound cache on gemini-4-argon croaks" );

    # A per-request model names the model in the URL; that is the one checked.
    my $g3 = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-3-flash-preview',
      cached_content => $cc );
    like( eval { $g3->$builder( [ { role => 'user', content => 'hi' } ], model => 'gemini-4-argon' ); 1 } ? '' : $@,
      qr/model 'gemini-4-argon' has no explicit context caching/,
      "$builder: per-request gemini-4-argon with a bound cache croaks" );

    # Regression: Gemini 3 and 2.5 still send the reference.
    for my $model (qw( gemini-3-flash-preview gemini-2.5-pro gemini-40-pro )) {
      my $ok = Langertha::Engine::Gemini->new( api_key => 'k', model => $model, cached_content => $cc );
      my $body = $json->decode( $ok->$builder( [ { role => 'user', content => 'hi' } ] )->content );
      is( $body->{cachedContent}, 'cachedContents/abc', "$builder: $model still sends cachedContent" );
    }
  }
}

# cachedContents.create for a Gemini 4 model croaks before the request is
# built (the request builder is called directly; nothing is sent).
{
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', url => 'http://127.0.0.1:9',
    model => 'gemini-3-flash-preview' );
  like( eval { $engine->_create_cached_content_request( model => 'models/gemini-4-argon', ttl => '60s' ); 1 } ? '' : $@,
    qr/cannot create a cachedContent: model 'gemini-4-argon' has no explicit context caching/,
    'create with named args for models/gemini-4-argon croaks' );
  like( eval { $engine->_create_cached_content_request(
          Langertha::CachedContent->new( model => 'models/gemini-4.1-flash', ttl => '60s' ) ); 1 } ? '' : $@,
    qr/model 'gemini-4\.1-flash' has no explicit context caching/,
    'create with a CachedContent object for gemini-4.1-flash croaks' );
  my $req = $engine->_create_cached_content_request( model => 'models/gemini-3-flash-preview', ttl => '60s' );
  is( $json->decode( $req->content )->{model}, 'models/gemini-3-flash-preview',
    'create for a Gemini 3 model still builds the request' );
}

# The engine attribute warns once per engine instance (ADR 0025 k247 Update).
{
  my $engine = Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-4-argon', temperature => 0.5 );
  my @warns;
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $engine->chat('one');
  $engine->chat('two');
  is( scalar( grep { /dropping temperature=0\.5 -- model 'gemini-4-argon'/ } @warns ), 1,
    'attribute temperature drop carps once per engine' );
}

done_testing;
