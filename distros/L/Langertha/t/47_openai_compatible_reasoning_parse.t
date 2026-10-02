#!/usr/bin/env perl
# ABSTRACT: Role::OpenAICompatible::chat_response reads the bare `reasoning` key (karr k129)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::vLLM;
use Langertha::Engine::VLLMHook;
use Langertha::Engine::Groq;
use Langertha::Engine::Cerebras;
use Langertha::Engine::OpenRouter;
use Langertha::Engine::AKIOpenAI;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

sub mock_http {
  my ($body) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode($body));
  $http->header('Content-Type' => 'application/json');
  return $http;
}

sub msg_response {
  my (%message) = @_;
  return mock_http({
    id      => 'chatcmpl-x',
    model   => 'm',
    choices => [{
      index         => 0,
      finish_reason => 'stop',
      message       => { role => 'assistant', %message },
    }],
  });
}

# The five shipped engines that put chain-of-thought under the bare `reasoning`
# key -- silently blank on ->thinking before k129, since the shared role read
# only `reasoning_content`.
my %ENGINE = (
  vLLM       => Langertha::Engine::vLLM->new(url => 'http://x'),
  VLLMHook   => Langertha::Engine::VLLMHook->new(url => 'http://x'),
  Groq       => Langertha::Engine::Groq->new(api_key => 'k', model => 'openai/gpt-oss-120b'),
  Cerebras   => Langertha::Engine::Cerebras->new(api_key => 'k'),
  OpenRouter => Langertha::Engine::OpenRouter->new(api_key => 'k', model => 'x/y'),
);

for my $name (sort keys %ENGINE) {
  my $engine = $ENGINE{$name};
  my $resp = $engine->chat_response(msg_response(
    reasoning => "$name thought process",
    content   => 'the answer',
  ));
  is("$resp", 'the answer', "$name: content parsed");
  ok($resp->has_thinking, "$name: bare reasoning key lifted onto thinking");
  is($resp->thinking, "$name thought process", "$name: thinking carries the bare reasoning");
}

# Canonical reasoning_content still wins where a provider sends both.
{
  my $engine = Langertha::Engine::vLLM->new(url => 'http://x');
  my $resp = $engine->chat_response(msg_response(
    reasoning_content => 'canonical spelling',
    reasoning         => 'bare spelling',
    content           => 'ok',
  ));
  is($resp->thinking, 'canonical spelling',
    'reasoning_content wins over the bare reasoning fallback');
}

# ... but only when it actually carries the thought. A back-compat stub that is
# present-but-empty beside a filled `reasoning` must be stepped over -- the
# failure mode the vLLM migration note calls out ("your client code could
# silently read an empty reasoning_content, even when reasoning is populated").
# The precedence therefore tests length, not defined. -- karr k79
{
  my $engine = Langertha::Engine::vLLM->new(url => 'http://x');
  my $resp = $engine->chat_response(msg_response(
    reasoning_content => '',
    reasoning         => 'the real thought',
    content           => 'ok',
  ));
  is($resp->thinking, 'the real thought',
    'an empty reasoning_content stub does not mask a filled reasoning');
}

# The !ref guard: OpenRouter ships a structured `reasoning_details` ARRAY and a
# `reasoning` STRING side by side. The string is lifted; a non-string `reasoning`
# must never reach the Str thinking attribute (Moose type-constraint death).
{
  my $engine = Langertha::Engine::OpenRouter->new(api_key => 'k', model => 'x/y');
  my $resp = $engine->chat_response(msg_response(
    reasoning         => 'the visible reasoning string',
    reasoning_details => [ { type => 'reasoning.text', text => 'block' } ],
    content           => 'answer',
  ));
  is($resp->thinking, 'the visible reasoning string',
    'the reasoning STRING is lifted alongside a reasoning_details ARRAY');
}
{
  # A `reasoning` that is itself a ref (arrayref / hashref) must be ignored, not
  # blow up the Str constraint -- the guard is what prevents that.
  my $engine = Langertha::Engine::vLLM->new(url => 'http://x');
  my $resp = eval {
    $engine->chat_response(msg_response(
      reasoning => [ 'not', 'a', 'string' ],
      content   => 'answer',
    ));
  };
  ok(!$@, 'a ref-valued reasoning key does not die on the Str thinking attribute')
    or diag($@);
  ok($resp && !$resp->has_thinking,
    'a ref-valued reasoning key is not lifted onto thinking (!ref guard)');
}

# A plain response carries no thinking on either spelling.
{
  my $engine = Langertha::Engine::vLLM->new(url => 'http://x');
  my $resp = $engine->chat_response(msg_response(content => 'hello'));
  ok(!$resp->has_thinking, 'plain response has no thinking');
}

# AKIOpenAI's k127 AKI-scoped lift is gone; the shared role now covers its bare
# `reasoning` spelling directly (the k127 override was redundant after k129).
# Behaviour is unchanged for callers -- proven here and in t/27_akiopenai_requests.t.
{
  my $aki = Langertha::Engine::AKIOpenAI->new(api_key => 'k', model => 'minimax-m2.5-230b');
  my $resp = $aki->chat_response(msg_response(
    reasoning => 'aki reasoning',
    content   => '22',
  ));
  is($resp->thinking, 'aki reasoning',
    'AKIOpenAI still surfaces the bare reasoning key via the shared role');
}

done_testing;
