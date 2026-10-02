#!/usr/bin/env perl
# ABSTRACT: _process_stream_buffer flushes the final unterminated event and tolerates CRLF (karr k166)

# The async streaming path (Role::Chat::chat_stream_realtime_f) feeds body
# fragments into _process_stream_buffer incrementally, then calls it once more
# with $final=1 to flush whatever is left after the connection closes. A last
# SSE event / NDJSON line that arrives WITHOUT its terminator (no blank line for
# SSE, no newline for NDJSON) used to stay stuck in the buffer and be dropped,
# losing its finish_reason / usage — while the sync process_stream_data path,
# which splits the whole body at once, kept it. The final flush now parses the
# remainder, and the SSE separator / line breaks are matched CRLF-tolerantly
# (\r?\n) to match that sync path.

use strict;
use warnings;
use Test2::Bundle::More;

use Langertha::Engine::OpenAI;
use Langertha::Engine::Ollama;

my $openai = Langertha::Engine::OpenAI->new( api_key => 'test', model => 'gpt-4o-mini' );
my $ollama = Langertha::Engine::Ollama->new( url => 'http://test.invalid:11434', model => 'llama3.1' );

# ======================================================================
# SSE — the confirmed k166 bug
# ======================================================================

# A final data: event WITHOUT the terminating blank line: buffered mid-stream,
# recovered on the final flush.
{
  my $event  = 'data: {"choices":[{"delta":{},"finish_reason":"stop"}]}';
  my $buffer = $event;

  my $mid = $openai->_process_stream_buffer( \$buffer, 'sse' );
  is( scalar @$mid, 0, 'SSE: unterminated final event is not parsed mid-stream' );
  is( $buffer, $event, 'SSE: unterminated event stays buffered mid-stream' );

  my $final = $openai->_process_stream_buffer( \$buffer, 'sse', 1 );
  is( scalar @$final, 1, 'SSE: final flush parses the unterminated event' );
  ok( $final->[0]->is_final, 'SSE: recovered event marked final' );
  is( $final->[0]->finish_reason, 'stop', 'SSE: finish_reason recovered from the final event' );
}

# A fully terminated event is still consumed even when $final is set.
{
  my $buffer = qq[data: {"choices":[{"delta":{"content":"Hi"}}]}\n\n];
  my $chunks = $openai->_process_stream_buffer( \$buffer, 'sse', 1 );
  is( scalar @$chunks, 1, 'SSE: terminated event parsed under final flush' );
  is( $chunks->[0]->content, 'Hi', 'SSE: terminated event content' );
  is( $buffer, '', 'SSE: buffer fully consumed' );
}

# CRLF: \r\n\r\n event separator and \r\n line breaks parse cleanly.
{
  my $buffer = qq[data: {"choices":[{"delta":{"content":"Hi"}}]}\r\n\r\n];
  my $chunks = $openai->_process_stream_buffer( \$buffer, 'sse' );
  is( scalar @$chunks, 1, 'SSE CRLF: \r\n\r\n-separated event parsed' );
  is( $chunks->[0]->content, 'Hi', 'SSE CRLF: content parsed cleanly (no trailing \r)' );
  is( $buffer, '', 'SSE CRLF: buffer fully consumed' );
}

# CRLF + unterminated final event: the tail (\r\n but no blank line) is flushed.
{
  my $buffer = qq[data: {"choices":[{"delta":{},"finish_reason":"stop"}]}\r\n];
  my $final  = $openai->_process_stream_buffer( \$buffer, 'sse', 1 );
  is( scalar @$final, 1, 'SSE CRLF: unterminated final event flushed' );
  is( $final->[0]->finish_reason, 'stop', 'SSE CRLF: finish_reason recovered' );
}

# ======================================================================
# NDJSON — same divergence for the newline-delimited dialect
# ======================================================================

# A final line WITHOUT its trailing newline: buffered mid-stream, recovered on
# the final flush.
{
  my $line   = '{"message":{"content":""},"done":true,"done_reason":"stop","eval_count":7}';
  my $buffer = $line;

  my $mid = $ollama->_process_stream_buffer( \$buffer, 'ndjson' );
  is( scalar @$mid, 0, 'NDJSON: unterminated final line is not parsed mid-stream' );
  is( $buffer, $line, 'NDJSON: unterminated line stays buffered mid-stream' );

  my $final = $ollama->_process_stream_buffer( \$buffer, 'ndjson', 1 );
  is( scalar @$final, 1, 'NDJSON: final flush parses the unterminated line' );
  ok( $final->[0]->is_final, 'NDJSON: recovered line marked final' );
  is( $final->[0]->finish_reason, 'stop', 'NDJSON: finish_reason recovered from the final line' );
}

# CRLF: a \r\n-terminated line parses cleanly (no trailing \r reaching decode).
{
  my $buffer = qq[{"message":{"content":"a"},"done":false}\r\n];
  my $chunks = $ollama->_process_stream_buffer( \$buffer, 'ndjson' );
  is( scalar @$chunks, 1, 'NDJSON CRLF: \r\n-terminated line parsed' );
  is( $chunks->[0]->content, 'a', 'NDJSON CRLF: content parsed cleanly' );
  is( $buffer, '', 'NDJSON CRLF: buffer fully consumed' );
}

done_testing;
