#!/usr/bin/env perl
# ABSTRACT: Thinking Kimi models default max_tokens to 16000 on both Moonshot faces (karr k225)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Langertha::Engine::Moonshot;
use Langertha::Engine::MoonshotAnthropic;

# karr k225 / ADR 0019 (k225 Update): Kimi counts reasoning_content against
# max_tokens and recommends max_tokens >= 16000 while thinking is on
# (platform.kimi.ai, advisor 2026-09-25 on k219, docs only). The Moonshot
# engines default to 4096, which truncates a thinking reply before its answer.
# The fix is a per-model default for the ids that think (kimi-k3 and
# kimi-k2.7-code(-highspeed) always, kimi-k2.6 by default), not a higher
# engine default: every other id keeps 4096. The default is a ceiling only
# when the caller chose none -- an explicit response_size (lower or higher)
# and a per-request max_tokens always win and are never raised.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my @THINKING = qw( kimi-k3 kimi-k2.7-code kimi-k2.7-code-highspeed kimi-k2.6 );

sub body_of {
  my ( $engine, %opt ) = @_;
  my $kind = $opt{kind} // 'chat_request';
  my $req  = $engine->$kind( [ { role => 'user', content => 'hi' } ],
    ( $opt{controls} ? ( controls => $opt{controls} ) : () ) );
  return $json->decode( $req->content );
}

for my $class ( qw( Langertha::Engine::Moonshot Langertha::Engine::MoonshotAnthropic ) ) {
  ( my $face = $class ) =~ s/.*:://;

  for my $model ( @THINKING ) {
    my $engine = $class->new( api_key => 'k', model => $model );
    is( body_of($engine)->{max_tokens}, 16000,
      "$face $model: no response_size -> max_tokens 16000" );
    is( body_of( $engine, kind => 'chat_stream_request' )->{max_tokens}, 16000,
      "$face $model: streaming request carries the same default" )
      if $engine->can('chat_stream_request');

    my $low = $class->new( api_key => 'k', model => $model, response_size => 2048 );
    is( body_of($low)->{max_tokens}, 2048,
      "$face $model: explicit lower response_size is never raised" );

    my $high = $class->new( api_key => 'k', model => $model, response_size => 32000 );
    is( body_of($high)->{max_tokens}, 32000,
      "$face $model: explicit higher response_size wins" );

    is( body_of( $engine, controls => { max_tokens => 1000 } )->{max_tokens}, 1000,
      "$face $model: per-request max_tokens wins over the model default" );
  }

  my $default = $class->new( api_key => 'k' );
  is( body_of($default)->{max_tokens}, 16000,
    "$face default model (kimi-k3) gets the thinking default" );

  # An id outside the thinking set keeps the engine-wide default: the
  # per-model row must not leak into a global raise.
  my $other = $class->new( api_key => 'k', model => 'moonshot-v1-8k' );
  is( body_of($other)->{max_tokens}, 4096,
    "$face non-thinking id keeps the engine default 4096" );
  is( $other->get_response_size, 4096, "$face get_response_size agrees" );
}

done_testing;
