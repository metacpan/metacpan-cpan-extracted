#!/usr/bin/env perl
# ABSTRACT: Test Future-based streaming method availability and %opts pass-through
use strict;
use warnings;
use Test2::Bundle::More;

# Skip if IO::Async not available
BEGIN {
  eval { require IO::Async::Loop; require Net::Async::HTTP; 1 }
    or plan skip_all => 'IO::Async and Net::Async::HTTP not installed';
}

use Future::AsyncAwait;
use HTTP::Response;
use Langertha::Engine::OpenAI;
use Langertha::Stream::Chunk;

# --- Mock HTTP transport that drives the on_header streaming callback ---

{
  package MockStreamAsyncHTTP;
  use Future;

  sub new { bless {}, $_[0] }

  sub do_request {
    my ($self, %args) = @_;
    my $on_header = $args{on_header};
    my $body_cb = $on_header->(HTTP::Response->new(200, 'OK'));
    $body_cb->('Hello ');
    $body_cb->('world');
    $body_cb->(undef);  # undef signals end of body
    return Future->done('done');
  }
}

# --- Mock HTTP transport that streams think-tagged content ---

{
  package MockThinkStreamAsyncHTTP;
  use Future;

  sub new { bless {}, $_[0] }

  sub do_request {
    my ($self, %args) = @_;
    my $on_header = $args{on_header};
    my $body_cb = $on_header->(HTTP::Response->new(200, 'OK'));
    $body_cb->('before');
    $body_cb->('<think>secret thought</think>');
    $body_cb->('after');
    $body_cb->(undef);  # undef signals end of body
    return Future->done('done');
  }
}

# --- Mock engine that captures what chat_stream_request receives ---

{
  package MockStreamOpenAI;
  use Moose;
  extends 'Langertha::Engine::OpenAI';

  has last_messages => (is => 'rw');
  has last_extra    => (is => 'rw');

  sub chat_stream_request {
    my ($self, $messages, %extra) = @_;
    $self->last_messages($messages);
    $self->last_extra(\%extra);
    return 'mock_request';
  }

  sub _process_stream_buffer {
    my ($self, $buffer_ref, $format, $final) = @_;
    my $data = $$buffer_ref;
    $$buffer_ref = '';
    return $data eq '' ? [] : [ Langertha::Stream::Chunk->new(content => $data) ];
  }

  __PACKAGE__->meta->make_immutable;
}

my $openai = Langertha::Engine::OpenAI->new(
  api_key => 'test-key',
  model => 'gpt-4o-mini',
);

# Test that the Future methods are available directly
ok($openai->can('simple_chat_f'), 'simple_chat_f method available');
ok($openai->can('simple_chat_stream_f'), 'simple_chat_stream_f method available');
ok($openai->can('simple_chat_stream_realtime_f'), 'simple_chat_stream_realtime_f method available');
ok($openai->can('chat_stream_realtime_f'), 'chat_stream_realtime_f method available');

# Test async http creation
my $http = $openai->_async_http;
ok($http->isa('Net::Async::HTTP'), '_async_http returns Net::Async::HTTP');

# Test loop creation
my $loop = $openai->_async_loop;
ok($loop->isa('IO::Async::Loop'), '_async_loop returns IO::Async::Loop');

async sub run_tests {
  # --- chat_stream_realtime_f passes %opts through to chat_stream_request ---
  my $opts_engine = MockStreamOpenAI->new(
    api_key     => 'test-key',
    model       => 'gpt-4o-mini',
    _async_http => MockStreamAsyncHTTP->new,
  );
  my ($opts_content, $opts_chunks, $opts_timing) = await $opts_engine->chat_stream_realtime_f(
    messages        => ['hi'],
    temperature     => 0.7,
    max_tokens      => 100,
    response_format => { type => 'json_object' },
  );

  subtest 'chat_stream_realtime_f passes generation opts to chat_stream_request' => sub {
    is($opts_content, 'Hello world', 'content streamed and concatenated');
    is(scalar @$opts_chunks, 2, 'two chunks collected');
    ok(defined $opts_timing->{ttft_seconds}, 'ttft_seconds present');
    ok(defined $opts_timing->{total_seconds}, 'total_seconds present');

    is($opts_engine->last_messages->[0]{role}, 'user', 'messages normalized');
    is($opts_engine->last_messages->[0]{content}, 'hi', 'message content preserved');
    # karr #46: canonical generation opts are extracted into the `controls`
    # hash (chat_stream_request places them on the engine's wire) instead of
    # being spread as raw target-wire kwargs.
    is($opts_engine->last_extra->{controls}{temperature}, 0.7,
      'temperature passed through as a control');
    is($opts_engine->last_extra->{controls}{max_tokens}, 100,
      'max_tokens passed through as a control');
    is_deeply($opts_engine->last_extra->{controls}{response_format}, { type => 'json_object' },
      'response_format passed through as a control');
    ok(!exists $opts_engine->last_extra->{temperature}
      && !exists $opts_engine->last_extra->{max_tokens}
      && !exists $opts_engine->last_extra->{response_format},
      'canonical controls not leaked as raw extras');
    ok(!exists $opts_engine->last_extra->{chunk_callback}, 'chunk_callback not leaked to the wire');
    ok(!exists $opts_engine->last_extra->{messages}, 'messages not leaked to the wire');
  };

  # --- simple_chat_stream_realtime_f stays back-compat ---
  my $simple_engine = MockStreamOpenAI->new(
    api_key     => 'test-key',
    model       => 'gpt-4o-mini',
    _async_http => MockStreamAsyncHTTP->new,
  );
  my @seen;
  my ($simple_content, $simple_chunks, $simple_timing) = await $simple_engine->simple_chat_stream_realtime_f(
    sub { push @seen, $_[0]->content },
    'hi',
  );

  subtest 'simple_chat_stream_realtime_f keeps its signature and behavior' => sub {
    is($simple_content, 'Hello world', 'content streamed and concatenated');
    is_deeply(\@seen, ['Hello ', 'world'], 'callback invoked per chunk');
    is(scalar @$simple_chunks, 2, 'two chunks collected');
    ok(defined $simple_timing->{ttft_seconds}, 'ttft_seconds present');
    ok(defined $simple_timing->{total_seconds}, 'total_seconds present');
    is_deeply($simple_engine->last_extra, {}, 'simple wrapper passes no extra opts');
  };

  # --- simple_chat_stream_f still works with undef callback ---
  my $plain_engine = MockStreamOpenAI->new(
    api_key     => 'test-key',
    model       => 'gpt-4o-mini',
    _async_http => MockStreamAsyncHTTP->new,
  );
  my ($plain_content, $plain_chunks) = await $plain_engine->simple_chat_stream_f('hi');

  subtest 'simple_chat_stream_f still works with undef callback' => sub {
    is($plain_content, 'Hello world', 'content streamed and concatenated');
    is(scalar @$plain_chunks, 2, 'two chunks collected');
  };

  # --- think-tag filtering still applies via the new entry point ---
  # ThinkTag wraps chat_stream_realtime_f (the wrapper delegates to it), so
  # both entry points must filter think tags identically.
  my $think_engine = MockStreamOpenAI->new(
    api_key     => 'test-key',
    model       => 'gpt-4o-mini',
    _async_http => MockThinkStreamAsyncHTTP->new,
  );
  my ($think_content) = await $think_engine->chat_stream_realtime_f(
    messages => ['hi'],
  );

  subtest 'think-tag filtering applies to chat_stream_realtime_f' => sub {
    is($think_content, 'beforeafter', 'think tags stripped from streamed content');
  };
}

run_tests()->get;

done_testing;
