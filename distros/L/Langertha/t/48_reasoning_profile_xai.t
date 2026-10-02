#!/usr/bin/env perl
# ABSTRACT: xAI grok reasoning_effort only reaches the wire with a level xAI accepts (karr k208)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::XAI;
use Langertha::Reasoning::Profile;

# karr k208 / ADR 0023: Engine::XAI used to resolve every grok id to the
# unlisted-id passthrough profile, so reasoning_effort none/minimal/max went to
# chat/completions unchanged although xAI accepts only low|medium|high|xhigh on
# grok-4.6 / grok-4.7 (default high) and low|medium|high on grok-4.5, and
# reasoning cannot be disabled (docs.x.ai reasoning page, updated 2026-09-21;
# advisor 2026-09-25, documentation only, not live-verified). An effort the
# model does not accept is dropped, as for every other curated family, and the
# server default (high) applies. grok-4.20-multi-agent reads effort as an agent
# count, so multi-digit ids stay unknown ids (the k196 guard).

my $json = JSON::MaybeXS->new->canonical(1);

sub body_effort {
  my ( $model, $effort ) = @_;
  my $engine = Langertha::Engine::XAI->new(
    api_key => 'k', model => $model, reasoning_effort => $effort );
  my $body = $json->decode(
    $engine->chat_request( [ { role => 'user', content => 'hi' } ] )->content );
  return $body->{reasoning_effort};
}

my %ACCEPTED = (
  'grok-4.7' => [qw( low medium high xhigh )],
  'grok-4.6' => [qw( low medium high xhigh )],
  'grok-4.5' => [qw( low medium high )],
);

for my $model ( sort keys %ACCEPTED ) {
  my %ok = map { $_ => 1 } @{ $ACCEPTED{$model} };
  for my $effort (qw( none minimal low medium high xhigh max )) {
    if ( $ok{$effort} ) {
      is( body_effort( $model, $effort ), $effort, "$model: '$effort' reaches the wire" );
    }
    else {
      is( body_effort( $model, $effort ), undef, "$model: '$effort' is dropped (not accepted)" );
    }
  }
  my $profile = Langertha::Reasoning::Profile->for_model($model);
  ok( !$profile->can_disable, "$model: reasoning cannot be disabled" );
  is_deeply( $profile->levels_by_wire,
    { openai => $ACCEPTED{$model}, responses => $ACCEPTED{$model} },
    "$model: same accepted set on chat and responses" );
}

# Multi-digit and uncurated grok ids stay unknown: the passthrough default.
my $default = Langertha::Reasoning::Profile->for_model('');
for my $id (qw( grok-4.20-multi-agent grok-4.10 grok-4.3 grok-build-0.1 )) {
  is( Langertha::Reasoning::Profile->for_model($id), $default, "$id: unknown id, provider default" );
}

done_testing;
