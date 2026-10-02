#!/usr/bin/env perl
# ABSTRACT: k186 table pinning which OpenAI model ids count as reasoning models
#           for the temperature gate (drop temperature vs keep temperature).

# The temperature gate (ADR 0025) first asks "is this an OpenAI reasoning model?"
# before it resolves the effort. Getting that classification wrong in the
# reasoning direction silently drops a caller's temperature on a model that
# would have honored it -- the worse error -- so every id below is pinned.
#
# Observation point: with an explicit, non-'none' reasoning effort the predicate
# Engine::OpenAI::_temperature_rejected_by_reasoning answers 1 exactly when the
# model is classified as a reasoning model (the effort resolution after the
# classification always rejects temperature at 'high'). This is independent of
# WHERE the classification lives, so the table holds across the k186 move of the
# classification from an engine regex into Langertha::Reasoning::Profile.
#
# Reasoning: o-series, gpt-5 (non-chat), gpt-5.N (non-chat), gpt-6*.
# Non-reasoning: gpt-4o / gpt-4.1, every gpt-5-chat and gpt-5.N-chat id, and any
# unknown id (the unlisted default must never classify as reasoning).

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Engine::OpenAI;
use Langertha::Engine::OpenAIResponses;
use Langertha::Reasoning;
use Langertha::Reasoning::Profile;

my @REASONING = qw(
  o1 o3 o3-mini o4-mini
  gpt-5 gpt-5-mini gpt-5-nano gpt-5-codex gpt-5-pro
  gpt-5.1 gpt-5.1-codex-max gpt-5.2 gpt-5.3 gpt-5.4
  gpt-5.5 gpt-5.5-pro gpt-5.6 gpt-5.6-luna gpt-5.6-terra gpt-5.7
  gpt-6 gpt-6-astra gpt-6-mini gpt-6.1 gpt-6.2-pro gpt-6.9
);

my @NON_REASONING = qw(
  gpt-4o gpt-4o-mini gpt-4o-mini-2024-07-18 gpt-4.1 gpt-4.1-mini
  gpt-5-chat gpt-5-chat-latest
  gpt-image-1 gpt-test gpt-x gpt-oss-120b
  claude-opus-4-8 gemini-2.5-flash some-unknown-model
);

# The dotted-chat ids: the pre-k186 regex (?!-chat) lookahead only saw a literal
# "-chat" directly after "gpt-5", so these were misclassified as reasoning.
my @DOTTED_CHAT = qw(
  gpt-5.1-chat-latest gpt-5.2-chat-latest gpt-5.3-chat-latest
  gpt-5.5-chat-latest gpt-5.6-chat gpt-5.6-chat-latest
);

sub classified_reasoning {
  my ( $class, $model ) = @_;
  my $engine = $class->new( api_key => 'k', model => $model );
  return $engine->_temperature_rejected_by_reasoning( { reasoning_effort => 'high' } );
}

for my $class (qw( Langertha::Engine::OpenAI Langertha::Engine::OpenAIResponses )) {
  for my $model (@REASONING) {
    is( classified_reasoning( $class, $model ), 1,
      "$class $model: reasoning model (temperature dropped at effort=high)" );
  }
  for my $model (@NON_REASONING) {
    is( classified_reasoning( $class, $model ), 0,
      "$class $model: non-reasoning (temperature kept)" );
  }
  for my $model (@DOTTED_CHAT) {
    is( classified_reasoning( $class, $model ), 0,
      "$class $model: dotted chat id is non-reasoning (temperature kept)" );
  }
}

# The classification is Profile wire-truth (k186): the engine reads it from
# Langertha::Reasoning::Profile->is_reasoning_model, not from its own regex.
for my $model (@REASONING) {
  is( Langertha::Reasoning::Profile->for_model($model)->is_reasoning_model, 1,
    "Profile $model: is_reasoning_model" );
}
for my $model ( @NON_REASONING, @DOTTED_CHAT, '' ) {
  is( Langertha::Reasoning::Profile->for_model($model)->is_reasoning_model, 0,
    "Profile '$model': not is_reasoning_model" );
}

# A chat carve-out changes only the classification, never the reasoning wire:
# it serializes exactly like the family it sits in, on every reasoning wire.
# Looped over every digit (karr k196): the carve-outs are generated per digit
# from each id's own family, so a newly curated gpt-5.N family is covered
# without anyone remembering to add its -chat pair.
my %CHAT_LIKE = (
  'gpt-5-chat'        => 'gpt-5',
  'gpt-5-chat-latest' => 'gpt-5',
  map { ( "gpt-5.$_-chat" => "gpt-5.$_", "gpt-5.$_-chat-latest" => "gpt-5.$_" ) } 0 .. 9,
);
for my $chat ( sort keys %CHAT_LIKE ) {
  is( Langertha::Reasoning::Profile->for_model($chat)->is_reasoning_model, 0,
    "Profile $chat: chat carve-out is not is_reasoning_model" );
  for my $wire (qw( openai responses anthropic gemini ollama )) {
    for my $effort (qw( none minimal low medium high xhigh max )) {
      is_deeply(
        { Langertha::Reasoning->new( model => $chat, effort => $effort )->to($wire) },
        { Langertha::Reasoning->new( model => $CHAT_LIKE{$chat}, effort => $effort )->to($wire) },
        "$chat serializes like $CHAT_LIKE{$chat} ($wire, $effort)" );
    }
  }
}

# Multi-digit guard (karr k196): a dotted family pattern must not match a second
# digit, so gpt-5.10 does not inherit gpt-5.1 (reasoning, default-off, gated
# ladder), gpt-5.20 does not inherit gpt-5.2, and gpt-5.50 not gpt-5.5. None of
# these ids is curated, so they are unknown ids: the k186 rule makes an unknown
# id non-reasoning (temperature kept) with the unlisted-id passthrough on every
# wire. The same guard keeps gemini-2.50 off the Gemini 2.5 budget family and
# qwen3.10 off the Qwen3.x template vocabulary, and the undotted gpt-6 / o-series
# rows get the same guard: gpt-60 is not gpt-6, o10 is not the o1 line. The
# gpt-6 row also stops at one digit after its dot (karr k201): gpt-6.10,
# gpt-6.20 and gpt-6.100 are not the gpt-6 generation.
my @MULTI_DIGIT = qw(
  gpt-60 gpt-600 gpt-61-mini o10 o100 o10-mini
  gpt-6.10 gpt-6.20 gpt-6.100 gpt-6.10-astra
  gpt-5.10 gpt-5.11 gpt-5.19 gpt-5.10-codex-max gpt-5.12-pro gpt-5.10-mini
  gpt-5.20 gpt-5.40 gpt-5.50 gpt-5.60 gpt-5.99
  gpt-5.10-chat gpt-5.10-chat-latest gpt-5.60-chat
  gemini-2.50 gemini-2.50-pro qwen3.10 Qwen/Qwen3.10-32B
);
for my $model (@MULTI_DIGIT) {
  is( Langertha::Reasoning::Profile->for_model($model)->is_reasoning_model, 0,
    "Profile $model: multi-digit id is not is_reasoning_model" );
  for my $class (qw( Langertha::Engine::OpenAI Langertha::Engine::OpenAIResponses )) {
    is( classified_reasoning( $class, $model ), 0,
      "$class $model: multi-digit id keeps temperature" );
    my $engine = $class->new( api_key => 'k', model => $model );
    is( $engine->_temperature_rejected_by_reasoning( {} ), 0,
      "$class $model: multi-digit id keeps temperature with no effort" );
  }
  for my $wire (qw( openai responses anthropic gemini ollama )) {
    for my $effort (qw( none minimal low medium high xhigh max )) {
      my $got = eval { +{ Langertha::Reasoning->new( model => $model, effort => $effort )->to($wire) } };
      is_deeply( $got,
        { Langertha::Reasoning->new( model => 'some-unknown-model', effort => $effort )->to($wire) },
        "$model serializes like an unknown id ($wire, $effort)" );
    }
  }
}

# Single-digit gpt-6.N keeps the full gpt-6 profile (karr k201). The gpt-6
# generation's doc-sourced ladder -- no none/minimal, 'max' Responses-only --
# is the best-known truth for its point releases; the uncurated passthrough
# would send none/minimal and chat 'max' to a generation documented to reject
# them. Only a second digit after the dot leaves the family (see above).
for my $model (qw( gpt-6.1 gpt-6.2-pro gpt-6.9 gpt-6-astra gpt-6-mini )) {
  my $profile = Langertha::Reasoning::Profile->for_model($model);
  is( $profile->model_match, Langertha::Reasoning::Profile->for_model('gpt-6')->model_match,
    "$model resolves to the gpt-6 row" );
  for my $wire (qw( openai responses anthropic gemini ollama )) {
    for my $effort (qw( none minimal low medium high xhigh max )) {
      is_deeply(
        { Langertha::Reasoning->new( model => $model,  effort => $effort )->to($wire) },
        { Langertha::Reasoning->new( model => 'gpt-6', effort => $effort )->to($wire) },
        "$model serializes like gpt-6 ($wire, $effort)" );
    }
  }
}

done_testing;
