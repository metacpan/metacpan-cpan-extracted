#!/usr/bin/env perl
# ABSTRACT: Langertha::Chat's sync tool loop must see the raw wire body

# karr #81: Chat::_tool_loop_iteration preferred $request->response_call->($response)
# over parse_response. Role::HTTP::generate_http_request ALWAYS installs a
# response_call, so that branch always won and the loop received the engine's
# Langertha::Response -- a blessed object whose ->{content} is the flattened
# assistant text, not the provider's block list.
#
# Downstream that broke two ways, both reproduced offline here before the fix:
#   * anthropic: ToolCall->locate saw ref($data) ne 'HASH' and returned [], so the
#     tool_use blocks were dropped; response_text_content then did
#     @{ $data->{content} } on the flattened string and died
#     "Can't use string ("") as an ARRAY ref" (Role/Tools.pm).
#   * openai/ollama/gemini: $data->{choices} / {message} / {candidates} were
#     simply absent on the Response object, so the loop silently reported "no
#     tool calls" and returned an empty final answer without calling any tool.
#
# The invariant under test is therefore NOT "the line calls parse_response" but
# "what flows through the tool loop is the raw decoded wire body, with the
# provider's block list intact" -- which is also what the async sibling
# simple_chat_with_tools_f and Langertha::Role::Tools::chat_with_tools_f do.
#
# karr #85 extended the sweep to the two remaining tool_wire_formats, and the
# responses case caught a second, independent loop breakage: format_tool_results
# returned an ARRAYREF for 'responses' while every caller does
# `push @$conversation, $engine->format_tool_results(...)`. One arrayref landed
# in the conversation as a single element and the next turn died with
# "Not a HASH reference" in OpenAIResponses::chat_request. The responses branch
# also skipped the assistant echo, which the Responses API requires before a
# function_call_output. Both are covered below: driving a second turn is what
# makes the Result envelope's arity and shape observable.

use strict;
use warnings;

use Test2::Bundle::More;

use JSON::MaybeXS;
use HTTP::Response;
use Future;

use Langertha::Chat;
use Langertha::Engine::Anthropic;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;
use Langertha::Engine::Gemini;
use Langertha::Engine::OpenAIResponses;
use Langertha::Engine::NousResearch;

my $json = JSON::MaybeXS->new->canonical(1)->utf8(1);

# --- Offline plumbing ----------------------------------------------------

# A real LWP::UserAgent subclass (the engine attribute is typed
# isa => 'LWP::UserAgent') that serves canned HTTP::Response objects.
{
  package ToolLoopUserAgent;
  our @ISA = ('LWP::UserAgent');
  sub new {
    my ( $class, @responses ) = @_;
    my $self = $class->SUPER::new;
    $self->{queue} = [@responses];
    $self->{sent}  = [];
    return $self;
  }
  sub sent { $_[0]->{sent} }
  sub request {
    my ( $self, $request ) = @_;
    push @{ $self->{sent} }, $request;
    my $response = shift @{ $self->{queue} };
    die "ToolLoopUserAgent: no canned response left\n" unless $response;
    return $response;
  }
}

{
  package ToolLoopMCP;
  sub new { my ( $class, %tools ) = @_; return bless { tools => \%tools, calls => [] }, $class }
  sub calls { $_[0]->{calls} }
  sub list_tools {
    my ( $self ) = @_;
    return Future->done([
      map { {
        name        => $_,
        description => "Test tool $_",
        inputSchema => { type => 'object', properties => {} },
      } } sort keys %{ $self->{tools} }
    ]);
  }
  sub call_tool {
    my ( $self, $name, $input ) = @_;
    push @{ $self->{calls} }, { name => $name, input => $input };
    my $handler = $self->{tools}{$name} or return Future->fail("Unknown tool: $name");
    return Future->done( $handler->($input) );
  }
}

# Records every $data the tool loop hands to plugin_after_llm_response --
# the public seam through which the loop's raw wire body is observable -- and
# every conversation it hands to plugin_before_llm_call, which is where the
# Result envelope appended by the previous iteration becomes observable.
{
  package ToolLoopPlugin::DataSpy;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';

  has seen => ( is => 'ro', default => sub { [] } );
  has conversations => ( is => 'ro', default => sub { [] } );

  async sub plugin_after_llm_response {
    my ( $self, $data, $iteration ) = @_;
    push @{ $self->seen }, $data;
    return $data;
  }

  async sub plugin_before_llm_call {
    my ( $self, $conversation, $iteration ) = @_;
    # Snapshot: the loop keeps pushing onto this very arrayref.
    push @{ $self->conversations }, [@$conversation];
    return $conversation;
  }

  __PACKAGE__->meta->make_immutable;
}

sub canned_http {
  my ( $body ) = @_;
  return HTTP::Response->new( 200, 'OK',
    [ 'Content-Type' => 'application/json' ], $json->encode($body) );
}

# --- One case per tool_wire_format the sync loop can drive ---------------
#
# Each case: a real engine, the provider's own tool-call turn, and the
# provider's own final-text turn. tool_use / tool_calls / functionCall all sit
# in a block list that only survives on the raw body.

my @cases = (
  {
    name   => 'anthropic',
    engine => sub {
      Langertha::Engine::Anthropic->new(
        api_key => 'test-key', model => 'claude-x', response_size => 256,
        user_agent => $_[0],
      );
    },
    tool_turn => {
      id => 'msg_1', model => 'claude-x', stop_reason => 'tool_use',
      content => [ { type => 'tool_use', id => 'toolu_1', name => 'get_time', input => {} } ],
    },
    text_turn => {
      id => 'msg_2', model => 'claude-x', stop_reason => 'end_turn',
      content => [ { type => 'text', text => 'It is 12:00.' } ],
    },
    blocks => sub { $_[0]->{content} },
    block_desc => 'content[] block list',
  },
  {
    name   => 'openai',
    engine => sub {
      Langertha::Engine::OpenAI->new(
        api_key => 'test-key', model => 'gpt-x', user_agent => $_[0],
      );
    },
    tool_turn => {
      id => 'chatcmpl-1',
      choices => [ { index => 0, finish_reason => 'tool_calls', message => {
        role => 'assistant', content => undef,
        tool_calls => [ { id => 'call_1', type => 'function',
          function => { name => 'get_time', arguments => '{}' } } ],
      } } ],
    },
    text_turn => {
      id => 'chatcmpl-2',
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'It is 12:00.' } } ],
    },
    blocks => sub { $_[0]->{choices}[0]{message}{tool_calls} },
    block_desc => 'choices[0].message.tool_calls',
  },
  {
    name   => 'ollama',
    engine => sub {
      Langertha::Engine::Ollama->new(
        url => 'http://test.url:12345', model => 'test-model', user_agent => $_[0],
      );
    },
    tool_turn => {
      model => 'test-model', done => JSON::MaybeXS::false(),
      message => { role => 'assistant', content => '',
        tool_calls => [ { function => { name => 'get_time', arguments => {} } } ] },
    },
    text_turn => {
      model => 'test-model', done => JSON::MaybeXS::true(),
      message => { role => 'assistant', content => 'It is 12:00.' },
    },
    blocks => sub { $_[0]->{message}{tool_calls} },
    block_desc => 'message.tool_calls',
  },
  {
    name   => 'gemini',
    engine => sub {
      Langertha::Engine::Gemini->new(
        api_key => 'test-key', model => 'gemini-x', user_agent => $_[0],
      );
    },
    tool_turn => {
      candidates => [ { content => { role => 'model',
        parts => [ { functionCall => { name => 'get_time', args => {} } } ] } } ],
    },
    text_turn => {
      candidates => [ { content => { role => 'model',
        parts => [ { text => 'It is 12:00.' } ] } } ],
    },
    blocks => sub { $_[0]->{candidates}[0]{content}{parts} },
    block_desc => 'candidates[0].content.parts',
  },
  {
    name   => 'responses',
    engine => sub {
      Langertha::Engine::OpenAIResponses->new(
        api_key => 'test-key', model => 'gpt-5.5-pro', user_agent => $_[0],
      );
    },
    tool_turn => {
      id => 'resp_1', object => 'response', status => 'completed',
      output => [
        { type => 'reasoning', id => 'rs_1', summary => [] },
        { type => 'function_call', id => 'fc_1', call_id => 'call_1',
          name => 'get_time', arguments => '{}', status => 'completed' },
      ],
    },
    text_turn => {
      id => 'resp_2', object => 'response', status => 'completed',
      output => [
        { type => 'message', id => 'msg_2', status => 'completed',
          role => 'assistant',
          content => [ { type => 'output_text', text => 'It is 12:00.' } ] },
      ],
    },
    blocks => sub { $_[0]->{output} },
    block_desc => 'output[] item list',
    # The Responses API pairs a function_call_output with the call_id of a
    # preceding top-level function_call item; without the echo it answers
    # "No tool call found for function call output with call_id".
    wire_check => sub {
      my ( $body ) = @_;
      my @input = @{ $body->{input} // [] };
      my ($call)   = grep { ( $_->{type} // '' ) eq 'function_call' } @input;
      my ($output) = grep { ( $_->{type} // '' ) eq 'function_call_output' } @input;
      ok( $call, 'turn 2 input echoes the function_call item' );
      ok( $output, 'turn 2 input carries a function_call_output item' );
      is( $output->{call_id}, $call->{call_id},
        'the output is correlated with the echoed call' );
      like( $output->{output}, qr/12:00/, 'the tool result rode along in output' );
    },
  },
  {
    name   => 'hermes',
    engine => sub {
      Langertha::Engine::NousResearch->new(
        api_key => 'test-key', model => 'Hermes-4-70B', user_agent => $_[0],
      );
    },
    # hermes has no native tool channel: the call arrives as <tool_call> XML
    # inside the ordinary assistant content string.
    tool_turn => {
      id => 'chatcmpl-h1',
      choices => [ { index => 0, finish_reason => 'stop', message => {
        role => 'assistant',
        content => qq{<tool_call>\n{"name": "get_time", "arguments": {}}\n</tool_call>},
      } } ],
    },
    text_turn => {
      id => 'chatcmpl-h2',
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'It is 12:00.' } } ],
    },
    blocks => sub { $_[0]->{choices}[0]{message} },
    block_ref => 'HASH',
    block_desc => 'choices[0].message',
  },
);

for my $case (@cases) {
  subtest "sync tool loop on the raw wire body: $case->{name}" => sub {
    my $mcp = ToolLoopMCP->new(
      get_time => sub { { content => [ { type => 'text', text => '12:00' } ] } },
    );
    my $user_agent = ToolLoopUserAgent->new(
      canned_http( $case->{tool_turn} ),
      canned_http( $case->{text_turn} ),
    );
    my $engine = $case->{engine}->($user_agent);
    is( $engine->tool_wire_format, $case->{name}, "engine speaks $case->{name}" );

    my $chat = Langertha::Chat->new(
      engine      => $engine,
      mcp_servers => [$mcp],
      plugins     => [q{+ToolLoopPlugin::DataSpy}],
    );

    my $result = $chat->simple_chat_with_tools('What time is it?');

    # The point of the whole exercise: the tool call in the block list was
    # seen and dispatched, instead of being flattened away.
    is( scalar @{ $mcp->calls }, 1, 'the tool call reached the MCP server' );
    is( $mcp->calls->[0]{name}, 'get_time', 'with the tool name from the wire' );
    is( $result, 'It is 12:00.', 'final assistant text returned' );

    # And the reason it worked: what the loop passed around was the raw
    # decoded body, not the engine's flattened Langertha::Response.
    my $seen = $chat->_plugin_instances->[0]->seen;
    is( scalar @$seen, 2, 'two LLM turns observed' );
    is( ref $seen->[0], 'HASH',
      'iteration 1 data is an unblessed raw wire body, not a Langertha::Response' );
    ok( !eval { $seen->[0]->isa('Langertha::Response') },
      'iteration 1 data is not a Langertha::Response' );
    is( ref $case->{blocks}->( $seen->[0] ), ( $case->{block_ref} // 'ARRAY' ),
      "$case->{block_desc} survived on the raw body" );

    # karr #85: format_tool_results must return a LIST -- the loop appends it
    # with `push @$conversation, ...`, so an arrayref return would sit in the
    # conversation as one element and the next chat_request would walk it as a
    # message. Turn 2's conversation is the only place that is visible.
    my $conversations = $chat->_plugin_instances->[0]->conversations;
    is( scalar @$conversations, 2, 'two conversations built' );
    is( scalar( grep { ref $_ ne 'HASH' } @{ $conversations->[1] } ), 0,
      'every element of turn 2 is a message hashref, none an appended arrayref' );
    cmp_ok( scalar @{ $conversations->[1] }, '>', scalar @{ $conversations->[0] },
      'the Result envelope was appended as N elements' );

    $case->{wire_check}->( $json->decode( $user_agent->sent->[1]->content ) )
      if $case->{wire_check};
  };
}

# karr k136: the reasoning fields of the assistant turn must be back on the
# wire in the next iteration. DeepSeek returns HTTP 400 for a tool loop whose
# earlier assistant turn lost its reasoning_content (Moonshot requires the
# same, OpenRouter requires reasoning_details unmodified). Only the second
# request body proves it, so this drives the loop like the cases above.
subtest 'openai assistant echo carries reasoning fields onto the next request' => sub {
  my $details = [ { type => 'reasoning.text', text => 'I should call get_time.',
    signature => 'sig_1' } ];
  my $mcp = ToolLoopMCP->new(
    get_time => sub { { content => [ { type => 'text', text => '12:00' } ] } },
  );
  my $user_agent = ToolLoopUserAgent->new(
    canned_http( {
      id => 'chatcmpl-r1',
      choices => [ { index => 0, finish_reason => 'tool_calls', message => {
        role => 'assistant', content => undef,
        reasoning_content => 'I should call get_time.',
        reasoning_details => $details,
        tool_calls => [ { id => 'call_1', type => 'function',
          function => { name => 'get_time', arguments => '{}' } } ],
      } } ],
    } ),
    canned_http( {
      id => 'chatcmpl-r2',
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'It is 12:00.' } } ],
    } ),
  );
  my $chat = Langertha::Chat->new(
    engine => Langertha::Engine::OpenAI->new(
      api_key => 'test-key', model => 'gpt-x', user_agent => $user_agent,
    ),
    mcp_servers => [$mcp],
  );

  is( $chat->simple_chat_with_tools('What time is it?'), 'It is 12:00.',
    'the loop ran to its final answer' );

  my $body = $json->decode( $user_agent->sent->[1]->content );
  my ($echo) = grep { ( $_->{role} // '' ) eq 'assistant' } @{ $body->{messages} // [] };
  ok( $echo, 'turn 2 carries the assistant echo' );
  is( $echo->{reasoning_content}, 'I should call get_time.',
    'reasoning_content is back on the wire' );
  is_deeply( $echo->{reasoning_details}, $details,
    'reasoning_details round-tripped unmodified, signature included' );
  ok( !exists $echo->{reasoning},
    'a reasoning spelling the provider never sent is not invented' );
};

# The counterpart: a provider that sends no reasoning must produce the same
# echo it always did -- an allowlist, not a passthrough of the whole message.
subtest 'openai assistant echo without reasoning is unchanged' => sub {
  my $mcp = ToolLoopMCP->new(
    get_time => sub { { content => [ { type => 'text', text => '12:00' } ] } },
  );
  my $user_agent = ToolLoopUserAgent->new(
    canned_http( {
      id => 'chatcmpl-p1',
      choices => [ { index => 0, finish_reason => 'tool_calls', message => {
        role => 'assistant', content => undef, refusal => undef,
        tool_calls => [ { id => 'call_1', type => 'function',
          function => { name => 'get_time', arguments => '{}' } } ],
      } } ],
    } ),
    canned_http( {
      id => 'chatcmpl-p2',
      choices => [ { index => 0, finish_reason => 'stop',
        message => { role => 'assistant', content => 'It is 12:00.' } } ],
    } ),
  );
  my $chat = Langertha::Chat->new(
    engine => Langertha::Engine::OpenAI->new(
      api_key => 'test-key', model => 'gpt-x', user_agent => $user_agent,
    ),
    mcp_servers => [$mcp],
  );

  is( $chat->simple_chat_with_tools('What time is it?'), 'It is 12:00.',
    'the loop ran to its final answer' );

  my $body = $json->decode( $user_agent->sent->[1]->content );
  my ($echo) = grep { ( $_->{role} // '' ) eq 'assistant' } @{ $body->{messages} // [] };
  is_deeply( [ sort keys %$echo ], [qw( content role tool_calls )],
    'exactly role/content/tool_calls -- no reasoning_content => undef, no refusal' );
};


done_testing;
