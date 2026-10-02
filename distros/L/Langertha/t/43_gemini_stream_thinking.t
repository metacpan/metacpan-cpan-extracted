#!/usr/bin/env perl
# ABSTRACT: Gemini parse_stream_chunk walks all parts, thought parts are not content (karr k129)

use strict;
use warnings;

use Test2::Bundle::More;
use JSON::MaybeXS;

use Langertha::Engine::Gemini;

my $gemini = Langertha::Engine::Gemini->new(
  api_key => 'test_api_key',
  model   => 'gemini-3-flash-preview',
);

# A decoded JSON `true`, the value the wire carries for a thought part.
my $TRUE = JSON->true;

# Build the decoded shape a streamGenerateContent SSE chunk carries.
sub chunk {
  my (@parts) = @_;
  return {
    candidates => [{
      content => { parts => [ @parts ] },
    }],
  };
}

# --- Bug 1: a thought part ahead of the answer part -------------------------
# Reading only parts[0] both leaked the thought summary into content AND
# dropped the real answer that followed. All parts must be walked; thought
# parts must be excluded from content.
{
  my $c = $gemini->parse_stream_chunk(chunk(
    { text => 'let me think about this', thought => $TRUE },
    { text => 'the real answer' },
  ));
  is($c->content, 'the real answer',
    'answer following a thought part is kept (parts[0]-only bug fixed)');
  unlike($c->content, qr/think about this/,
    'thought text does not leak into streamed content');
}

# --- Bug 2: a lone thought part -> empty content, no leak -------------------
{
  my $c = $gemini->parse_stream_chunk(chunk(
    { text => 'internal reasoning only', thought => $TRUE },
  ));
  is($c->content, '', 'a chunk carrying only a thought part yields empty content');
}

# --- Plain single answer part still works -----------------------------------
{
  my $c = $gemini->parse_stream_chunk(chunk(
    { text => 'hello world' },
  ));
  is($c->content, 'hello world', 'a plain answer part is content');
}

# --- Multiple answer parts are concatenated (same as chat_response) ---------
{
  my $c = $gemini->parse_stream_chunk(chunk(
    { text => 'Hello' },
    { text => ' World' },
  ));
  is($c->content, 'Hello World', 'multiple answer parts are joined');
}

# --- Interleaved thought/answer parts: only answers become content ----------
{
  my $c = $gemini->parse_stream_chunk(chunk(
    { text => 'plan',      thought => $TRUE },
    { text => 'part-a' },
    { text => 'more plan', thought => $TRUE },
    { text => 'part-b' },
  ));
  is($c->content, 'part-apart-b', 'only non-thought parts are joined into content');
}

# --- finishReason drives is_final -------------------------------------------
{
  my $c = $gemini->parse_stream_chunk({
    candidates => [{
      content      => { parts => [ { text => 'done' } ] },
      finishReason => 'STOP',
    }],
  });
  ok($c->is_final, 'a chunk with finishReason is final');
  is($c->finish_reason, 'STOP', 'finish_reason surfaced');
}

# --- no candidates -> undef (unchanged) -------------------------------------
is($gemini->parse_stream_chunk({ candidates => [] }), undef,
  'a chunk with no candidates returns undef');

done_testing;
