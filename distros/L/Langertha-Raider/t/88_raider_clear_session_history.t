#!/usr/bin/env perl
# ABSTRACT: Unit tests for Raider clear_session_history (karr #105)

use strict;
use warnings;

use Test2::Bundle::More;

use Langertha::Raider;

# --- Helper: minimal mock engine that satisfies Raider's needs ---

{
  package MockEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model => (is => 'ro', default => 'mock-model');
  has '+mcp_servers' => (default => sub { [] });

  sub format_tools { return $_[1] }
  sub response_tool_calls { return [] }
  sub extract_tool_call { return ($_[1]->{name}, $_[1]->{input}) }
  sub format_tool_results { return () }
  sub response_text_content { return 'mock response' }
  sub think_tag_filter { 0 }

  __PACKAGE__->meta->make_immutable;
}

# --- Helper: deterministic embedding engine ---

{
  package MockEmbeddingEngine;
  use Moose;
  use Future;
  my @VOCAB = qw( aardvark zebra narwhal tusk berlin weather time );

  sub simple_embedding {
    my ( $self, $text ) = @_;
    my $lc_text = lc $text;
    return [ map { scalar( () = $lc_text =~ /\Q$_\E/g ) } @VOCAB ];
  }

  # What raider calls: an already-completed Future, so the slot fills at once.
  sub simple_embedding_f {
    my ( $self, $text ) = @_;
    return Future->call(sub { Future->done($self->simple_embedding($text)) });
  }

  __PACKAGE__->meta->make_immutable;
}

# --- The POD-documented call dies because the accessor is read-only ---
#
# karr #105: =attr session_history used to advertise `$raider->session_history([])`
# as the way to clear, which crashes against `is => 'ro'`. The fix renames the
# route; this test guards against the bug coming back.

subtest 'POD-documented writer dies on read-only accessor' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
  );

  eval { $raider->session_history([]) };
  like(
    $@,
    qr/Cannot assign a value to a read-only accessor.*session_history/,
    '$raider->session_history([]) dies with the read-only accessor error',
  );

  # And the fix-route works.
  push @{$raider->session_history},
    { role => 'user', content => 'aardvark question' };
  ok( $raider->clear_session_history,
    'clear_session_history is callable and returns the raider' );
};

# --- clear_session_history empties both arrays in lock-step ---

subtest 'clear_session_history empties session_history and _session_embeddings' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
  );

  $raider->_push_session_history(
    { role => 'user',      content => 'Aardvark migration question' },
    { role => 'assistant', content => 'The zebra crossing report' },
    { role => 'assistant', content => 'Narwhal tusk measurements are stable' },
  );

  is( scalar @{ $raider->session_history }, 3,
    'session_history holds three messages before clear' );
  is( scalar @{ $raider->_session_embeddings }, 3,
    '_session_embeddings holds three slots before clear' );

  my $ret = $raider->clear_session_history;
  is( $ret, $raider, 'returns $self for chaining' );

  is_deeply( $raider->session_history, [],
    'session_history is empty after clear' );
  is_deeply( $raider->_session_embeddings, [],
    '_session_embeddings is empty after clear' );

  is( scalar @{ $raider->session_history },
      scalar @{ $raider->_session_embeddings },
      '1:1 invariant preserved after clear' );
};

# --- clear_session_history is safe to call on a fresh raider ---

subtest 'clear_session_history on a fresh raider is a no-op' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
  );

  is_deeply( $raider->session_history, [],
    'fresh raider has empty session_history' );
  is_deeply( $raider->_session_embeddings, [],
    'fresh raider has empty _session_embeddings' );

  my $ret = $raider->clear_session_history;
  is( $ret, $raider, 'returns $self on no-op clear' );
  is_deeply( $raider->session_history, [],
    'session_history still empty after no-op clear' );
  is_deeply( $raider->_session_embeddings, [],
    '_session_embeddings still empty after no-op clear' );
};

# --- After clear, pushing new messages restores correct search results ---
#
# The previous failure mode (#99/#105): spliced the public ArrayRef,
# _session_embeddings stayed stale, _query_session_history_f silently
# degraded to the text fallback and the embedding route was never usable
# again. clear_session_history fixes that by clearing both sides, so a
# fresh push re-aligns the arrays and semantic search resumes.

subtest 'after clear, new pushes restore aligned embedding search' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
    raider_mcp       => 1,
  );

  # Push, clear, push again — the second push must land in step with the
  # embeddings array, otherwise search returns the wrong message.
  $raider->_push_session_history(
    { role => 'assistant', content => 'old message about berlin weather' },
  );
  $raider->clear_session_history;

  $raider->_push_session_history(
    { role => 'assistant', content => 'new message about narwhal tusk' },
  );

  is( scalar @{ $raider->session_history },
      scalar @{ $raider->_session_embeddings },
    'arrays are aligned after clear + push' );

  my $text = $raider->_query_session_history_f({ search => 'narwhal tusk' })->get;
  like( $text, qr/narwhal tusk/, 'embedding search returns the new message' );
  unlike( $text, qr/berlin weather/,
    'embedding search does not return the cleared message' );
};

# --- add_session_history (session resume) keeps the embeddings in step ---

subtest 'add_session_history appends through the embedding pusher' => sub {
  my $raider = Langertha::Raider->new(
    engine           => MockEngine->new,
    embedding_engine => MockEmbeddingEngine->new,
  );
  ok( $raider->add_session_history(
    { role => 'user', content => 'zebra' },
    { role => 'assistant', content => [ { type => 'tool_use', name => 'bash', input => {} } ] },
  ), 'returns the raider' );
  is( scalar @{$raider->session_history}, 2, 'two entries' );
  is( scalar @{$raider->_session_embeddings}, 2, 'one embedding slot each' );
  is( scalar @{$raider->history}, 0, 'the working history is untouched' );
};

done_testing;
