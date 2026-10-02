#!/usr/bin/env perl
# ABSTRACT: xAI's REST reference documents prompt_cache_key as a body field on chat/completions

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::XAI;

# Why (karr k202): k200's advisor note flagged Engine::XAI's prompt_cache_key
# as possibly over-claimed, because xAI's "Maximizing Cache Hits" how-to guide
# shows only the x-grok-conv-id HEADER for /v1/chat/completions. But xAI's REST
# reference for that same endpoint
# (https://docs.x.ai/developers/rest-api-reference/inference/chat-completions,
# read 2026-09-25) documents prompt_cache_key as an accepted BODY field,
# explicitly plumbed server-side to x-grok-conv-id -- the how-to guide simply
# never mentions the body alias. Do not clear engine_capabilities /
# prompt_cache_key for XAI on the strength of the guide alone; the REST
# reference is the source of truth here, and it confirms the field is wired.
# No code change follows from this -- this test pins the flag and the wire
# body so a future "over-claimed" read of the guide cannot silently regress it.

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub xai { Langertha::Engine::XAI->new( api_key => 'x', model => 'grok-4.6', @_ ) }

sub body_of {
  my ( $engine, %extra ) = @_;
  return $json->decode(
    $engine->chat_request( [ { role => 'user', content => 'hi' } ], %extra )->content );
}

ok xai()->supports('prompt_cache_key'), 'Engine::XAI advertises prompt_cache_key';

is body_of( xai( prompt_cache_key => 'conv_abc' ) )->{prompt_cache_key}, 'conv_abc',
  'engine attribute prompt_cache_key lands on the chat/completions body';

# karr #46: chat_f extracts prompt_cache_key into a canonical `controls` hash
# and hands it to chat_request under that key; exercised here the same way
# chat_f itself calls chat_request, without going through the async/mocked-HTTP
# layer this request-building check does not need.
is body_of( xai(), controls => { prompt_cache_key => 'conv_xyz' } )->{prompt_cache_key},
  'conv_xyz', 'per-request chat_f control (karr #46) lands on the chat/completions body';

done_testing;
