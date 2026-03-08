#!/usr/bin/env perl
# ABSTRACT: Tests for Langertha::Plugin::Langfuse

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;
use MIME::Base64 qw( decode_base64 );

use LWP::UserAgent;
use HTTP::Response;

use Langertha::Plugin::Langfuse;
use Langertha::Chat;
use Langertha::Embedder;

my $json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

# --- Mock engine ---

{
  package MockChatRequest;
  sub new { bless { response_call => $_[1] }, $_[0] }
  sub response_call { $_[0]->{response_call} }
}

{
  package MockUserAgent;
  sub new { bless {}, $_[0] }
  sub request { 'fake_response' }
}

{
  package MockChatEngine;
  use Moose;

  has model => (is => 'ro', default => 'test-model');
  has chat_model => (is => 'ro', lazy => 1, default => sub { $_[0]->model });
  has user_agent => (is => 'ro', default => sub { MockUserAgent->new });

  sub does {
    my ($self, $role) = @_;
    return 1 if $role eq 'Langertha::Role::Chat';
    return $self->SUPER::does($role);
  }

  sub chat_request {
    my ($self, $messages, %extra) = @_;
    return MockChatRequest->new(sub { 'mock response' });
  }

  __PACKAGE__->meta->make_immutable;
}

# --- Mock embedding engine ---

{
  package MockEmbedRequest;
  sub new { bless { response_call => $_[1] }, $_[0] }
  sub response_call { $_[0]->{response_call} }
}

{
  package MockEmbeddingEngine;
  use Moose;

  has model => (is => 'ro', default => 'embed-model');
  has embedding_model => (is => 'ro', lazy => 1, default => sub { $_[0]->model });
  has user_agent => (is => 'ro', default => sub { MockUserAgent->new });

  sub does {
    my ($self, $role) = @_;
    return 1 if $role eq 'Langertha::Role::Embedding';
    return $self->SUPER::does($role);
  }

  sub simple_embedding { [0.1, 0.2, 0.3] }

  sub embedding_request {
    my ($self, $input, %extra) = @_;
    return MockEmbedRequest->new(sub { [0.4, 0.5, 0.6] });
  }

  __PACKAGE__->meta->make_immutable;
}

# --- Tests ---

subtest 'Plugin instantiation with explicit keys' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-lf-test',
    secret_key => 'sk-lf-test',
  );

  ok($lf->enabled, 'enabled with both keys');
  is($lf->public_key, 'pk-lf-test', 'public_key set');
  is($lf->secret_key, 'sk-lf-test', 'secret_key set');
  is($lf->url, 'https://cloud.langfuse.com', 'url defaults to cloud');
  is($lf->trace_name, 'llm-call', 'trace_name defaults');
  ok(!$lf->auto_flush, 'auto_flush defaults to false');
};

subtest 'Plugin disabled without keys' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(host => $chat);

  ok(!$lf->enabled, 'disabled without keys');

  # Hooks should pass through without creating events
  my $conv = [{ role => 'user', content => 'hi' }];
  my $result = $lf->plugin_before_llm_call($conv, 1)->get;
  is_deeply($result, $conv, 'before_llm_call passes through');
  is(scalar @{$lf->_batch}, 0, 'no events batched');
};

subtest 'create_trace creates event' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $tid = $lf->create_trace(
    name  => 'test-trace',
    input => { query => 'hello' },
  );

  ok($tid, 'returns trace ID');
  like($tid, qr/^[0-9a-f-]+$/, 'trace ID looks like UUID');
  is(scalar @{$lf->_batch}, 1, 'one event in batch');

  my $event = $lf->_batch->[0];
  is($event->{type}, 'trace-create', 'event type');
  is($event->{body}{name}, 'test-trace', 'trace name');
  is_deeply($event->{body}{input}, { query => 'hello' }, 'trace input');
};

subtest 'create_generation creates event' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $gid = $lf->create_generation(
    trace_id   => 'trace-1',
    name       => 'gen-1',
    model      => 'gpt-4o',
    start_time => '2026-01-01T00:00:00.000Z',
    end_time   => '2026-01-01T00:00:01.000Z',
  );

  ok($gid, 'returns generation ID');
  my $event = $lf->_batch->[0];
  is($event->{type}, 'generation-create', 'event type');
  is($event->{body}{traceId}, 'trace-1', 'linked to trace');
  is($event->{body}{model}, 'gpt-4o', 'model set');
};

subtest 'create_generation requires trace_id' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  eval { $lf->create_generation(name => 'no-trace') };
  like($@, qr/requires trace_id/, 'dies without trace_id');
};

subtest 'create_span creates event' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $sid = $lf->create_span(
    trace_id => 'trace-1',
    name     => 'tool:search',
    input    => { q => 'perl' },
  );

  ok($sid, 'returns span ID');
  my $event = $lf->_batch->[0];
  is($event->{type}, 'span-create', 'event type');
  is($event->{body}{name}, 'tool:search', 'span name');
};

subtest 'update_trace upserts' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $id = $lf->update_trace(id => 'trace-1', output => 'done');
  is($id, 'trace-1', 'returns same ID');

  my $event = $lf->_batch->[0];
  is($event->{type}, 'trace-create', 'uses trace-create (upsert)');
  is($event->{body}{output}, 'done', 'output set');
};

subtest 'flush sends HTTP request' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-lf-mykey',
    secret_key => 'sk-lf-mysecret',
    url        => 'https://langfuse.test.invalid',
  );

  $lf->_batch([
    { id => '1', type => 'trace-create', body => { id => 't1' } },
  ]);

  my $captured_request;
  {
    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
      my ($ua, $req) = @_;
      $captured_request = $req;
      return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], '{}');
    };

    $lf->flush;
  }

  ok($captured_request, 'flush sent request');
  is($captured_request->method, 'POST', 'uses POST');
  like($captured_request->uri, qr{/api/public/ingestion$}, 'correct endpoint');
  like($captured_request->uri, qr{^https://langfuse\.test\.invalid}, 'correct URL');

  # Verify auth
  my $auth = $captured_request->header('Authorization');
  like($auth, qr/^Basic /, 'uses Basic auth');
  my $decoded = decode_base64(($auth =~ /^Basic (.+)$/)[0]);
  is($decoded, 'pk-lf-mykey:sk-lf-mysecret', 'correct credentials');

  # Verify batch cleared
  is(scalar @{$lf->_batch}, 0, 'batch cleared after flush');
};

subtest 'flush with empty batch does nothing' => sub {
  my $engine = MockChatEngine->new;
  my $chat = Langertha::Chat->new(engine => $engine);
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => $chat,
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $captured;
  {
    no warnings 'redefine';
    local *LWP::UserAgent::request = sub { $captured = 1; HTTP::Response->new(200) };
    $lf->flush;
  }
  ok(!$captured, 'no HTTP request sent');
};

# --- Integration: Chat + Langfuse plugin ---

subtest 'Chat with Langfuse plugin creates trace + generation' => sub {
  my $engine = MockChatEngine->new;
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::Chat->new(engine => $engine),  # temp host for creation
    public_key => 'pk-test',
    secret_key => 'sk-test',
    trace_name => 'my-chat',
  );

  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [$lf],
  );

  $chat->simple_chat('Hello!');

  # Should have: trace-create, generation-create, trace-create (update)
  my @types = map { $_->{type} } @{$lf->_batch};
  is_deeply(\@types, ['trace-create', 'generation-create', 'trace-create'],
    'trace + generation + trace update created');

  # Trace
  my $trace = $lf->_batch->[0];
  is($trace->{body}{name}, 'my-chat', 'trace name from config');
  ok($trace->{body}{input}, 'trace has input');

  # Generation
  my $gen = $lf->_batch->[1];
  is($gen->{body}{traceId}, $trace->{body}{id}, 'generation linked to trace');
  is($gen->{body}{name}, 'generation-1', 'generation named with iteration');
  ok($gen->{body}{startTime}, 'generation has startTime');
  ok($gen->{body}{endTime}, 'generation has endTime');

  # Trace update
  my $update = $lf->_batch->[2];
  is($update->{body}{id}, $trace->{body}{id}, 'update targets same trace');
  is($update->{body}{output}, 'mock response', 'trace updated with response');
};

subtest 'Chat with Langfuse plugin passes trace metadata' => sub {
  my $engine = MockChatEngine->new;
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::Chat->new(engine => $engine),
    public_key => 'pk-test',
    secret_key => 'sk-test',
    user_id    => 'user-42',
    session_id => 'sess-abc',
    tags       => ['prod', 'v2'],
    metadata   => { env => 'test' },
  );

  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [$lf],
  );

  $chat->simple_chat('Test');

  my $trace = $lf->_batch->[0];
  is($trace->{body}{userId}, 'user-42', 'userId set');
  is($trace->{body}{sessionId}, 'sess-abc', 'sessionId set');
  is_deeply($trace->{body}{tags}, ['prod', 'v2'], 'tags set');
  is_deeply($trace->{body}{metadata}, { env => 'test' }, 'metadata set');
};

subtest 'Chat with Langfuse + tools creates spans for tool calls' => sub {
  # Mock MCP server
  {
    package LFTestMCPServer;
    use Future;

    sub new {
      my ($class, %tools) = @_;
      bless { tools => \%tools }, $class;
    }

    sub list_tools {
      my ($self) = @_;
      my @tools = map {
        { name => $_, description => "Tool $_", inputSchema => { type => 'object', properties => {} } }
      } keys %{$self->{tools}};
      return Future->done(\@tools);
    }

    sub call_tool {
      my ($self, $name, $input) = @_;
      my $handler = $self->{tools}{$name};
      return Future->done($handler->($input)) if $handler;
      return Future->fail("Unknown: $name");
    }
  }

  # Mock tool-calling engine
  {
    package LFTestToolEngine;
    use Moose;

    has model => (is => 'ro', default => 'mock-model');
    has chat_model => (is => 'ro', lazy => 1, default => sub { $_[0]->model });
    has user_agent => (is => 'ro', default => sub { MockUserAgent->new });
    has _response_queue => (is => 'ro', default => sub { [] });

    sub does {
      my ($self, $role) = @_;
      return 1 if $role eq 'Langertha::Role::Chat';
      return 1 if $role eq 'Langertha::Role::Tools';
      return $self->SUPER::does($role);
    }

    sub chat_request {
      my ($self, $messages, %extra) = @_;
      my $data = shift @{$self->_response_queue} // { final_text => 'done' };
      return MockChatRequest->new(sub { $data });
    }

    sub build_tool_chat_request {
      my ($self, $conversation, $formatted_tools, %extra) = @_;
      return $self->chat_request($conversation, tools => $formatted_tools, %extra);
    }
    sub format_tools { $_[1] }
    sub response_tool_calls { $_[1]->{tool_calls} // [] }
    sub extract_tool_call { ($_[1]->{name}, $_[1]->{input} // {}) }
    sub format_tool_results {
      my ($self, $data, $results) = @_;
      return (
        { role => 'assistant', content => 'tools' },
        map { { role => 'tool', content => join('', map { $_->{text} // '' } @{$_->{result}{content} // []}) } } @$results
      );
    }
    sub response_text_content { $_[1]->{final_text} // '' }
    sub parse_response { $_[1] }
    sub think_tag_filter { 0 }

    __PACKAGE__->meta->make_immutable;
  }

  my $mcp = LFTestMCPServer->new(
    calculator => sub { { content => [{ type => 'text', text => '42' }] } },
  );

  my $engine = LFTestToolEngine->new(
    _response_queue => [
      { tool_calls => [{ name => 'calculator', input => { expr => '6*7' } }] },
      { final_text => 'The answer is 42.' },
    ],
  );

  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::Chat->new(engine => $engine),
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $chat = Langertha::Chat->new(
    engine      => $engine,
    mcp_servers => [$mcp],
    plugins     => [$lf],
  );

  $chat->simple_chat_with_tools('What is 6*7?');

  # Expected events:
  # 1. trace-create (before iteration 1)
  # 2. generation-create (after iteration 1 LLM response)
  # 3. trace-create (update with output from iteration 1)
  # 4. span-create (tool: calculator)
  # 5. generation-create (after iteration 2 LLM response)
  # 6. trace-create (update with final output)
  my @types = map { $_->{type} } @{$lf->_batch};
  is_deeply(\@types, [
    'trace-create',       # initial trace
    'generation-create',  # iteration 1 LLM
    'trace-create',       # update trace (iteration 1)
    'span-create',        # tool: calculator
    'generation-create',  # iteration 2 LLM
    'trace-create',       # update trace (final)
  ], 'correct event sequence for tool loop');

  # Verify tool span
  my $tool_span = $lf->_batch->[3];
  is($tool_span->{body}{name}, 'tool:calculator', 'tool span named correctly');
  ok($tool_span->{body}{input}, 'tool span has input');
  ok($tool_span->{body}{output}, 'tool span has output');

  # Verify final trace update has the raw response data
  my $final_update = $lf->_batch->[5];
  is_deeply($final_update->{body}{output}, { final_text => 'The answer is 42.' },
    'trace output is final LLM response data');
};

subtest 'reset_trace starts new trace on next call' => sub {
  my $engine = MockChatEngine->new;
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::Chat->new(engine => $engine),
    public_key => 'pk-test',
    secret_key => 'sk-test',
  );

  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [$lf],
  );

  # First chat creates trace
  $chat->simple_chat('First');
  my $first_trace_id = $lf->_batch->[0]{body}{id};
  ok($first_trace_id, 'first trace created');

  # Second chat without reset reuses same trace
  $chat->simple_chat('Second');
  # The second call's generation should link to the same trace
  my $second_gen = $lf->_batch->[3];  # index 3 = second generation
  is($second_gen->{body}{traceId}, $first_trace_id, 'reuses same trace');

  # Reset and third chat gets new trace
  $lf->_batch([]);
  $lf->reset_trace;
  $chat->simple_chat('Third');
  my $third_trace_id = $lf->_batch->[0]{body}{id};
  ok($third_trace_id, 'third trace created');
  isnt($third_trace_id, $first_trace_id, 'new trace after reset');
};

subtest 'auto_flush sends events immediately' => sub {
  my $engine = MockChatEngine->new;
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::Chat->new(engine => $engine),
    public_key => 'pk-test',
    secret_key => 'sk-test',
    auto_flush => 1,
  );

  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [$lf],
  );

  my $flush_count = 0;
  {
    no warnings 'redefine';
    local *LWP::UserAgent::request = sub {
      $flush_count++;
      return HTTP::Response->new(200, 'OK', ['Content-Type' => 'application/json'], '{}');
    };

    $chat->simple_chat('Test');
  }

  is($flush_count, 1, 'auto_flush sent one request');
  is(scalar @{$lf->_batch}, 0, 'batch cleared by auto_flush');
};

# --- Embedder integration ---

subtest 'Embedder with Langfuse plugin creates trace + generation' => sub {
  my $engine = MockEmbeddingEngine->new;
  my $lf = Langertha::Plugin::Langfuse->new(
    host       => Langertha::Embedder->new(engine => $engine),
    public_key => 'pk-test',
    secret_key => 'sk-test',
    trace_name => 'embed',
  );

  my $embedder = Langertha::Embedder->new(
    engine  => $engine,
    plugins => [$lf],
  );

  my $vec = $embedder->simple_embedding('test text');
  is_deeply($vec, [0.1, 0.2, 0.3], 'embedding still works');

  my @types = map { $_->{type} } @{$lf->_batch};
  is_deeply(\@types, ['trace-create', 'generation-create', 'trace-create'],
    'trace + generation + trace update for embedding');

  my $trace = $lf->_batch->[0];
  is($trace->{body}{name}, 'embed', 'trace name from config');
  is($trace->{body}{input}, 'test text', 'trace input is text');

  my $gen = $lf->_batch->[1];
  is($gen->{body}{name}, 'embedding', 'generation named embedding');
  is($gen->{body}{input}, 'test text', 'generation input');

  my $update = $lf->_batch->[2];
  is_deeply($update->{body}{output}, { dimensions => 3 }, 'trace output has dimensions');
};

subtest 'Langfuse plugin via Name => Args syntax' => sub {
  my $engine = MockChatEngine->new;

  my $chat = Langertha::Chat->new(
    engine  => $engine,
    plugins => [Langfuse => {
      public_key => 'pk-test',
      secret_key => 'sk-test',
      trace_name => 'sugar-chat',
    }],
  );

  $chat->simple_chat('Hello');

  my $plugin = $chat->_plugin_instances->[0];
  isa_ok($plugin, 'Langertha::Plugin::Langfuse');
  ok($plugin->enabled, 'plugin enabled');

  my $trace = $plugin->_batch->[0];
  is($trace->{body}{name}, 'sugar-chat', 'trace name from sugar args');
};

done_testing;
