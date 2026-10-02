#!/usr/bin/env perl
# ABSTRACT: aggregated thinking rides the stream path return + callback (karr k129)
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

# The streamed-thinking aggregation must reach the caller of the async stream
# path -- as a 4th return element of chat_stream_realtime_f -- and each chunk's
# thinking must reach the real-time callback. No Langertha::Response is built on
# the stream path; the aggregation is Role::Chat::aggregate_thinking over the
# collected chunks. All bodies are mocked SSE -- no live API calls.

# --- Mock transport: SSE body with reasoning_content deltas ahead of content ---
{
  package MockReasoningStreamAsyncHTTP;
  use Future;
  sub new { bless {}, $_[0] }
  sub do_request {
    my ($self, %args) = @_;
    my $body_cb = $args{on_header}->(HTTP::Response->new(200, 'OK'));
    $body_cb->("data: {\"choices\":[{\"delta\":{\"reasoning_content\":\"Let me \"}}]}\n\n");
    $body_cb->("data: {\"choices\":[{\"delta\":{\"reasoning_content\":\"think.\"}}]}\n\n");
    $body_cb->("data: {\"choices\":[{\"delta\":{\"content\":\"The answer\"}}]}\n\n");
    $body_cb->("data: {\"choices\":[{\"delta\":{\"content\":\" is 4.\"},\"finish_reason\":\"stop\"}]}\n\n");
    $body_cb->("data: [DONE]\n\n");
    $body_cb->(undef);
    return Future->done('done');
  }
}

# --- Mock transport: SSE body with inline <think> tags in the content ---
{
  package MockThinkTagStreamAsyncHTTP;
  use Future;
  sub new { bless {}, $_[0] }
  sub do_request {
    my ($self, %args) = @_;
    my $body_cb = $args{on_header}->(HTTP::Response->new(200, 'OK'));
    $body_cb->("data: {\"choices\":[{\"delta\":{\"content\":\"<think>secret</think>\"}}]}\n\n");
    $body_cb->("data: {\"choices\":[{\"delta\":{\"content\":\"visible\"},\"finish_reason\":\"stop\"}]}\n\n");
    $body_cb->("data: [DONE]\n\n");
    $body_cb->(undef);
    return Future->done('done');
  }
}

async sub run_tests {
  # --- Native reasoning deltas: aggregated thinking is the 4th return element ---
  {
    my $engine = Langertha::Engine::OpenAI->new(
      api_key     => 'k',
      model       => 'gpt-4o-mini',
      _async_http => MockReasoningStreamAsyncHTTP->new,
    );

    my @cb_thinking;
    my ($content, $chunks, $timing, $thinking) = await $engine->chat_stream_realtime_f(
      messages       => ['hi'],
      chunk_callback => sub {
        my ($chunk) = @_;
        push @cb_thinking, $chunk->thinking if $chunk->has_thinking;
      },
    );

    subtest 'native reasoning deltas surface aggregated thinking on the stream path' => sub {
      is($content, 'The answer is 4.', 'content aggregated from content deltas');
      is($thinking, 'Let me think.', 'thinking aggregated as the 4th return element');
      is(join('', @cb_thinking), 'Let me think.',
        'each per-chunk thinking reached the real-time callback');
    };

    # No Response is built on the stream path: the chunks are Stream::Chunk, and
    # the return tuple carries a plain aggregated string, never a Langertha::Response.
    subtest 'no Response object is built on the stream path' => sub {
      ok(!(ref $thinking), 'aggregated thinking is a plain scalar, not an object');
      isa_ok($chunks->[0], 'Langertha::Stream::Chunk');
      ok(!$chunks->[0]->isa('Langertha::Response'), 'chunk is not a Response');
    };
  }

  # --- <think> tag content: ThinkTag extraction wins and rides the 4th element ---
  {
    my $engine = Langertha::Engine::OpenAI->new(
      api_key     => 'k',
      model       => 'gpt-4o-mini',
      _async_http => MockThinkTagStreamAsyncHTTP->new,
    );

    my ($content, $chunks, $timing, $thinking) = await $engine->chat_stream_realtime_f(
      messages => ['hi'],
    );

    subtest 'think-tag thinking is extracted and returned as the 4th element' => sub {
      is($content, 'visible', 'think tags stripped from streamed content');
      is($thinking, 'secret', 'tag-extracted thinking rides the 4th return element');
    };
  }

  # --- Filter disabled: aggregated native thinking still returned, content raw ---
  {
    my $engine = Langertha::Engine::OpenAI->new(
      api_key          => 'k',
      model            => 'gpt-4o-mini',
      think_tag_filter => 0,
      _async_http      => MockReasoningStreamAsyncHTTP->new,
    );

    my ($content, $chunks, $timing, $thinking) = await $engine->chat_stream_realtime_f(
      messages => ['hi'],
    );

    subtest 'think_tag_filter=0 still carries the aggregated native thinking' => sub {
      is($content, 'The answer is 4.', 'content unchanged with filter off');
      is($thinking, 'Let me think.', 'native aggregated thinking preserved with filter off');
    };
  }
}

run_tests()->get;

done_testing;
