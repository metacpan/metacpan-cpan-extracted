use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;
use Langertha::ToolCall;

my $json = JSON::MaybeXS->new( utf8 => 1 );

my $tool_call = Langertha::ToolCall->new(
  id        => 'call_42',
  name      => 'get_weather',
  arguments => { city => 'Berlin' },
);

my $resp = Langertha::Knarr::Response->new(
  content       => 'Looking up the weather...',
  model         => 'gpt-test',
  tool_calls    => [ $tool_call ],
  finish_reason => 'tool_calls',
);

my $req = Langertha::Knarr::Request->new( protocol => 'openai', model => 'gpt-test' );

subtest 'OpenAI formatter emits tool_calls' => sub {
  my $proto = Langertha::Knarr::Protocol::OpenAI->new;
  my (undef, undef, $body) = $proto->format_chat_response($resp, $req);
  my $d = $json->decode($body);
  is $d->{choices}[0]{message}{content}, 'Looking up the weather...';
  is $d->{choices}[0]{finish_reason}, 'tool_calls';
  my $tc = $d->{choices}[0]{message}{tool_calls};
  ok $tc, 'tool_calls present';
  is $tc->[0]{id}, 'call_42';
  is $tc->[0]{type}, 'function';
  is $tc->[0]{function}{name}, 'get_weather';
  like $tc->[0]{function}{arguments}, qr/Berlin/, 'args serialized as JSON string';
};

subtest 'Anthropic formatter emits tool_use blocks' => sub {
  my $proto = Langertha::Knarr::Protocol::Anthropic->new;
  my $areq  = Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test' );
  my (undef, undef, $body) = $proto->format_chat_response($resp, $areq);
  my $d = $json->decode($body);
  my $blocks = $d->{content};
  is scalar(@$blocks), 2, 'text + tool_use blocks';
  is $blocks->[0]{type}, 'text';
  is $blocks->[1]{type}, 'tool_use';
  is $blocks->[1]{id},   'call_42';
  is $blocks->[1]{name}, 'get_weather';
  is $blocks->[1]{input}{city}, 'Berlin';
  is $d->{stop_reason}, 'tool_calls';  # finish_reason was preserved from response
};

subtest 'Anthropic formatter without finish_reason defaults to tool_use' => sub {
  my $proto = Langertha::Knarr::Protocol::Anthropic->new;
  my $r2 = Langertha::Knarr::Response->new(
    content => '',
    tool_calls => [ $tool_call ],
  );
  my $areq = Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test' );
  my (undef, undef, $body) = $proto->format_chat_response($r2, $areq);
  my $d = $json->decode($body);
  is $d->{stop_reason}, 'tool_use';
  is $d->{content}[0]{type}, 'tool_use';
};

subtest 'Ollama formatter emits tool_calls' => sub {
  my $proto = Langertha::Knarr::Protocol::Ollama->new;
  my $oreq  = Langertha::Knarr::Request->new( protocol => 'ollama', model => 'mistral-test' );
  my (undef, undef, $body) = $proto->format_chat_response($resp, $oreq);
  my $d = $json->decode($body);
  ok $d->{message}{tool_calls}, 'tool_calls present';
  is $d->{message}{tool_calls}[0]{function}{name}, 'get_weather';
};

done_testing;
