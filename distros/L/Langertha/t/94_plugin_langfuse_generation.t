#!/usr/bin/env perl
# ABSTRACT: Plugin::Langfuse generation events carry model, usage, cost, input and output
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use Test::MockAsyncHTTP;
use Langertha::Chat;
use Langertha::Engine::OpenAI;
use Langertha::Content::Image;
use Langertha::Plugin::Langfuse;
use Langertha::Pricing;
use Langertha::Response;

# karr k304: the plugin's generation events had only a name and timestamps,
# so Langfuse's token, cost and model views stayed empty for every
# Langertha::Chat user, while the engine-level Role::Langfuse sent model and
# usage. A generation now carries the model that answered, the token usage
# (plus cost when a Langertha::Pricing is given), the conversation sent (a
# JSON-safe snapshot: an image appears as its compact description, never its
# bytes), the answer (text, and tool calls in the canonical ToolCall shape),
# and completionStartTime from the response's time to first token.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub completion {
  my (%message) = @_;
  return Test::MockAsyncHTTP->mock_json_response({
    id => 'c1', object => 'chat.completion', created => 1, model => 'gpt-served',
    usage   => { prompt_tokens => 1000, completion_tokens => 500, total_tokens => 1500 },
    choices => [ { index => 0, finish_reason => 'stop', message => { role => 'assistant', %message } } ],
  });
}

sub chat_with {
  my ( $response, %plugin ) = @_;
  my $engine = Langertha::Engine::OpenAI->new(
    api_key => 'k', model => 'gpt-configured',
    _async_http => Test::MockAsyncHTTP->new( responses => [$response] ),
  );
  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [ Langfuse => { public_key => 'pk', secret_key => 'sk', %plugin } ],
  );
  return ( $chat, $chat->plugin_instances->[0] );
}

sub generations { grep { $_->{type} eq 'generation-create' } @{ $_[0]->_batch } }

my $pixel = encode_base64( "\x89PNG\r\n\x1a\n" . ( "\0" x 64 ), '' );

subtest 'Chat generation: model, usage, cost, input snapshot, output' => sub {
  my ( $chat, $lf ) = chat_with(
    completion( content => 'a cat' ),
    pricing => Langertha::Pricing->new( rules => {
      'gpt-served' => { input_per_million => 2, output_per_million => 8 } } ),
  );
  my $image = Langertha::Content::Image->from_base64( $pixel, media_type => 'image/png' );
  my $response = $chat->simple_chat_f({ role => 'user', content => [ 'What is this?', $image ] })->get;
  is( "$response", 'a cat', 'chat answered' );

  my ($gen) = generations($lf);
  ok( $gen, 'one generation' );
  my $body = $gen->{body};
  is( $body->{model}, 'gpt-served', 'the model that answered, not only the configured one' );
  is( $body->{usage}{input},  1000, 'input tokens' );
  is( $body->{usage}{output}, 500,  'output tokens' );
  is( $body->{usage}{total},  1500, 'total tokens' );
  ok( abs( $body->{usage}{inputCost}  - 0.002 ) < 1e-12, 'input cost from the pricing rule' );
  ok( abs( $body->{usage}{outputCost} - 0.004 ) < 1e-12, 'output cost' );
  ok( abs( $body->{usage}{totalCost}  - 0.006 ) < 1e-12, 'total cost' );
  is( $body->{output}, 'a cat', 'output text' );

  my $input = $json->encode( $body->{input} );
  like( $input, qr/What is this\?/, 'input carries the conversation' );
  like( $input, qr/data:image\/png;base64,\[\d+ bytes omitted\]/, 'the image is described by its size' );
  unlike( $input, qr/\Q$pixel\E/, 'but its bytes are not in the trace' );
  my $wire = $lf->_json->encode( $lf->_batch );
  unlike( $wire, qr/\Q$pixel\E/, 'nor anywhere in the batch' );
};

subtest 'no pricing: usage without cost; unknown model rule: no cost' => sub {
  my ( $chat, $lf ) = chat_with( completion( content => 'x' ) );
  $chat->simple_chat_f('hi')->get;
  my ($gen) = generations($lf);
  is_deeply( $gen->{body}{usage}, { input => 1000, output => 500, total => 1500 }, 'tokens only' );
};

subtest 'tool calls in the answer land on output in the ToolCall shape' => sub {
  my ( $chat, $lf ) = chat_with( completion(
    content    => undef,
    tool_calls => [ { id => 'call_1', type => 'function',
      function => { name => 'lookup', arguments => '{"q":"perl"}' } } ],
  ) );
  $chat->simple_chat_f('find perl')->get;
  my ($gen) = generations($lf);
  my $calls = $gen->{body}{output}{tool_calls};
  is( scalar @{ $calls // [] }, 1, 'one tool call' );
  is( $calls->[0]{name}, 'lookup', 'name' );
  is_deeply( $calls->[0]{arguments}, { q => 'perl' }, 'decoded arguments' );
};

subtest 'completionStartTime from ttft_seconds; hooks on a raw tool-loop body' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-configured' );
  my $lf = Langertha::Plugin::Langfuse->new( host => $engine, public_key => 'pk', secret_key => 'sk' );

  my $conversation = [ { role => 'user', content => 'hi' } ];
  $lf->plugin_before_llm_call( $conversation, 1 )->get;
  push @$conversation, { role => 'assistant', content => 'later turn' };   # the loop mutates it
  $lf->plugin_after_llm_response( Langertha::Response->new(
    content => 'hello', model => 'gpt-served',
    timing  => { ttft_seconds => 0.25, total_seconds => 0.5 },
  ), 1 )->get;
  my ($gen) = generations($lf);
  ok( $gen->{body}{completionStartTime}, 'completionStartTime set' );
  ok( $gen->{body}{completionStartTime} ge $gen->{body}{startTime}, 'not before the start' );
  is( scalar @{ $gen->{body}{input} }, 1, 'input is the snapshot taken before the call' );

  # The Chat tool loop hands the hooks the raw decoded body, not a Response.
  $lf->_batch([]);
  $lf->plugin_before_llm_call( [ { role => 'user', content => 'hi' } ], 2 )->get;
  $lf->plugin_after_llm_response( {
    model   => 'gpt-raw',
    usage   => { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
    choices => [ { index => 0, message => { role => 'assistant', content => 'raw text' } } ],
  }, 2 )->get;
  ($gen) = generations($lf);
  is( $gen->{body}{model}, 'gpt-raw', 'model from the raw body' );
  is_deeply( $gen->{body}{usage}, { input => 7, output => 3, total => 10 }, 'usage from the raw body' );
  is( $gen->{body}{output}, 'raw text', 'output text through the engine' );
};

subtest 'image objects and bare base64 in the input are described, not copied' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-configured' );
  my $lf = Langertha::Plugin::Langfuse->new( host => $engine, public_key => 'pk', secret_key => 'sk' );
  my $big = encode_base64( "\0" x 3000, '' );
  $lf->plugin_before_llm_call( [
    { role => 'user', content => [ 'look', Langertha::Content::Image->from_base64( $pixel, media_type => 'image/png' ) ] },
    { role => 'user', content => [ { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $big } } ] },
  ], 1 )->get;
  $lf->plugin_after_llm_response( Langertha::Response->new( content => 'x' ), 1 )->get;
  my ($gen) = generations($lf);
  my $input = $gen->{body}{input};
  is( $input->[0]{content}[1]{type}, 'image', 'a Content::Image becomes its TO_JSON description' );
  is( $input->[1]{content}[0]{source}{data}, '[base64: 3000 bytes omitted]', 'a bare base64 payload is shortened' );
  unlike( $lf->_json->encode( $lf->_batch ), qr/\Q$big\E/, 'no payload in the batch' );
};

subtest 'no model in the answer: falls back to the engine chat_model' => sub {
  my $engine = Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-configured' );
  my $lf = Langertha::Plugin::Langfuse->new( host => $engine, public_key => 'pk', secret_key => 'sk' );
  $lf->plugin_before_llm_call( [ { role => 'user', content => 'hi' } ], 1 )->get;
  $lf->plugin_after_llm_response( Langertha::Response->new( content => 'x' ), 1 )->get;
  my ($gen) = generations($lf);
  is( $gen->{body}{model}, 'gpt-configured', 'engine chat_model' );
  ok( !exists $gen->{body}{usage}, 'no usage reported, none invented' );
};

done_testing;
