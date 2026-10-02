#!/usr/bin/env perl
# ABSTRACT: The MiniMax/Kimi thinking toggle is opt-in per engine; every other engine keeps its pre-k209 body

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;
use Module::Runtime qw( require_module );

# karr k209/k215 review (I1) / ADR 0023 k209 Update: the thinking:{type:...}
# object is the spelling of MiniMax's cloud API and Kimi's Messages face, not a
# property of the model. A self-hosted vLLM/SGLang server, an OpenAI-compatible
# proxy or another /anthropic shim serving a bare MiniMax-M3 / kimi-k2.6 id does
# not speak it. So only engines that opt in (MiniMax, MiniMaxAnthropic,
# MoonshotAnthropic) emit the toggle; every other engine must send exactly what
# it sent before the toggle rows existed. The expected bodies in
# t/data/reasoning_thinking_toggle_scope_base.json were generated from the base
# commit 4e7f9d8's lib/ (before k209), not hand-written.

my $canon = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $want  = $canon->decode( path('t/data/reasoning_thinking_toggle_scope_base.json')->slurp_raw );

for my $key ( sort keys %$want ) {
  my ( $short, $model, $effort, $kind ) = split /\|/, $key;
  my $class = "Langertha::Engine::$short";
  require_module($class);
  my $engine = $class->new( url => 'http://localhost:1/v1', api_key => 'k', model => $model,
    ( $effort ne 'bare' ? ( reasoning_effort => $effort ) : () ), thinking_display => 'summarized' );
  my $got = $canon->encode( $canon->decode(
    $engine->$kind( [ { role => 'user', content => 'hi' } ] )->content ) );
  is( $got, $want->{$key}, "unchanged since 4e7f9d8: $key" );
}

done_testing;
