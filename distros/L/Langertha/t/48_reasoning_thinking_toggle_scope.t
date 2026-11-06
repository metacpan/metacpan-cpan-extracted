#!/usr/bin/env perl
# ABSTRACT: The MiniMax/Kimi thinking toggle is opt-in per engine; every other engine keeps its pre-k209 body

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use Path::Tiny;
use Module::Runtime qw( require_module );
use Langertha::Reasoning;

# karr k209/k215 review (I1) / ADR 0023 k209 Update: the thinking:{type:...}
# object is the spelling of MiniMax's cloud API and Kimi's Messages face, not a
# property of the model. A self-hosted vLLM/SGLang server, an OpenAI-compatible
# proxy or another /anthropic shim serving a bare MiniMax-M3 / kimi-k2.6 id does
# not speak it. So only engines that opt in (MiniMax, MiniMaxAnthropic,
# MoonshotAnthropic) emit the toggle; every other engine must send exactly what
# it sent before the toggle rows existed. The expected bodies in
# t/data/reasoning_thinking_toggle_scope_base.json were generated from the base
# commit 4e7f9d8's lib/ (before k209), not hand-written. The stream request's
# stream_options (ADR 0038) came later and is no reasoning field, so it is
# left out of the comparison rather than written into that base.

my $canon = JSON::MaybeXS->new->canonical(1)->utf8(1);
my $want  = $canon->decode( path('t/data/reasoning_thinking_toggle_scope_base.json')->slurp_raw );

for my $key ( sort keys %$want ) {
  my ( $short, $model, $effort, $kind ) = split /\|/, $key;
  my $class = "Langertha::Engine::$short";
  require_module($class);
  my $engine = $class->new( url => 'http://localhost:1/v1', api_key => 'k', model => $model,
    ( $effort ne 'bare' ? ( reasoning_effort => $effort ) : () ), thinking_display => 'summarized' );
  my $body = $canon->decode( $engine->$kind( [ { role => 'user', content => 'hi' } ] )->content );
  delete $body->{stream_options} if $kind eq 'chat_stream_request';
  my $got = $canon->encode($body);
  my $expected = $want->{$key};
  # k382: LlamaCpp and SGLang moved to the chat_template_kwargs reasoning wire,
  # an intended change that is not the thinking:{type} toggle. Their effort
  # spelling is re-derived from the serializer; every other field stays the
  # pre-k209 snapshot, and the thinking key is still forbidden below.
  my $moved = $engine->reasoning_wire_format eq 'chat_template_kwargs';
  if ($moved) {
    my $base = $canon->decode($expected);
    delete $base->{reasoning_effort};
    $expected = $canon->encode( { %$base, ( $effort ne 'bare'
      ? Langertha::Reasoning->new( effort => $effort )->to('chat_template_kwargs') : () ) } );
  }
  is( exists $body->{thinking} ? 1 : 0, exists $canon->decode( $want->{$key} )->{thinking} ? 1 : 0,
    "thinking key present only where the pre-k209 body had it: $key" );
  is( $got, $expected, ( $moved ? "pre-k209 body plus the chat_template_kwargs wire" : "unchanged since 4e7f9d8" ) . ": $key" );
}

done_testing;
