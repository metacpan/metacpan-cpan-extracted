#!/usr/bin/env perl
# ABSTRACT: MiniMaxAnthropic sends no output_config.effort; the thinking block stays (karr k209)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::MiniMaxAnthropic;
use Langertha::Engine::Anthropic;

# karr k209 / ADR 0009: MiniMax's /anthropic CreateMessageReq
# (openapi-chat-anthropic.json) has a `thinking` object (default disabled on
# M3) but no `output_config`, for every model on that endpoint. The inherited
# Anthropic serializer sent output_config.effort anyway. The field is dropped
# at the engine, since it is a property of MiniMax's endpoint, not of a model
# id; thinking:{type:adaptive} stays, because it is how an effort turns
# thinking on there. Advisor 2026-09-25, from MiniMax's documentation, not
# live-verified.

my $json = JSON::MaybeXS->new->canonical(1);

sub body {
  my ( $class, %args ) = @_;
  my $controls = delete $args{controls} // {};
  my $engine = $class->new( api_key => 'k', %args );
  return $json->decode( $engine->chat_request(
    [ { role => 'user', content => 'hi' } ], controls => $controls )->content );
}

for my $model (qw( MiniMax-M3 MiniMax-M2.7 )) {
  for my $effort (qw( none minimal low medium high xhigh max )) {
    my $got = body( 'Langertha::Engine::MiniMaxAnthropic', model => $model, reasoning_effort => $effort );
    ok( !exists $got->{output_config}, "MiniMaxAnthropic $model '$effort': no output_config" );
    # k209 part 1: both ids are thinking-toggle Profile rows. Any level turns
    # thinking on; none turns it off explicitly on M3 and is omitted on M2.7,
    # which cannot turn thinking off.
    my $want = $effort ne 'none'      ? { type => 'adaptive' }
             : $model eq 'MiniMax-M3' ? { type => 'disabled' }
             :                          undef;
    is_deeply( $got->{thinking}, $want,
      "MiniMaxAnthropic $model '$effort': thinking " . ( $want ? $want->{type} : 'absent' ) );
  }
}

my $ctl = body( 'Langertha::Engine::MiniMaxAnthropic', controls => { reasoning_effort => 'high' } );
ok( !exists $ctl->{output_config}, 'MiniMaxAnthropic: a per-request effort sends no output_config' );
is_deeply( $ctl->{thinking}, { type => 'adaptive' }, 'MiniMaxAnthropic: a per-request effort turns thinking on' );

# The strip is scoped to MiniMax's endpoint: first-party Anthropic keeps it.
is_deeply( body( 'Langertha::Engine::Anthropic', model => 'claude-opus-4-8', reasoning_effort => 'high' )
    ->{output_config}, { effort => 'high' }, 'Anthropic still sends output_config.effort' );

done_testing;
