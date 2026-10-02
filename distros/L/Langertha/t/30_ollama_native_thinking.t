#!/usr/bin/env perl
# ABSTRACT: Ollama native /api/chat chat_response surfaces message.thinking (karr k129)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use HTTP::Response;

use Langertha::Engine::Ollama;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

my $ollama = Langertha::Engine::Ollama->new(
  url   => 'http://test.invalid:11434',
  model => 'qwen3:8b',
);

sub mock_http {
  my ($body) = @_;
  my $http = HTTP::Response->new(200, 'OK');
  $http->content($json->encode($body));
  $http->header('Content-Type' => 'application/json');
  return $http;
}

# Native /api/chat with think=true returns the chain-of-thought under
# message.thinking, parallel to message.content. It must reach Response.thinking.
{
  my $resp = $ollama->chat_response(mock_http({
    model      => 'qwen3:8b',
    done       => JSON->true,
    done_reason => 'stop',
    message    => {
      role     => 'assistant',
      thinking => 'The user greeted me, I should greet back.',
      content  => 'Hello!',
    },
  }));
  is("$resp", 'Hello!', 'Ollama native content parsed');
  ok($resp->has_thinking, 'Ollama native lifts message.thinking onto thinking');
  is($resp->thinking, 'The user greeted me, I should greet back.',
    'thinking carries the native message.thinking');
}

# A response without thinking carries none.
{
  my $resp = $ollama->chat_response(mock_http({
    model      => 'llama3.3',
    done       => JSON->true,
    done_reason => 'stop',
    message    => { role => 'assistant', content => 'plain answer' },
  }));
  is("$resp", 'plain answer', 'Ollama native content parsed (no thinking)');
  ok(!$resp->has_thinking, 'a native response without message.thinking has no thinking');
}

done_testing;
