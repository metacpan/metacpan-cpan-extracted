#!/usr/bin/env perl
# ABSTRACT: A single long raid compacts the in-flight context, keeping skill content
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use Langertha::Raider;

# karr k89: auto-compression used to run only in _raid_f, before a raid — so one
# long raid (many tool calls) grew $conversation without bound and blew past
# max_context_tokens on smaller models. It now also compacts INSIDE the tool loop
# (_run_raid_loop): when the last real prompt-token count crosses the threshold,
# the oldest tool exchanges are dropped from the in-flight conversation, oldest
# first, while the mission/system prompt (where activated skill content lives) is
# never touched. This test drives a scripted engine that reports STEADILY RISING
# input_tokens, so the threshold is crossed mid-raid, and checks both that the
# in-flight context stops growing and that the skill content survives every turn.

my $SENTINEL = 'SKILL-SENTINEL-KEEP-ME';

{
  package InLoopResp;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed engine (no tool_loop_response / chat_response, so Raider reads
  # the reply through the legacy fallback path). It answers with one 'noop' tool
  # call for the first six turns, then the final text, and reports input_tokens
  # of 30 * turn — a rising count that crosses the threshold partway through.
  # Every conversation it is asked to send is recorded for inspection.
  package InLoopEngine;
  use Moose;
  use IO::Async::Loop;
  has loop     => (is => 'ro', default => sub { IO::Async::Loop->new });
  has turn     => (is => 'rw', default => 0);
  has requests => (is => 'rw', default => 0);
  has recorded => (is => 'ro', default => sub { [] });

  sub async_loop  { $_[0]->loop }
  sub mcp_servers { [] }

  sub async_request_f {
    my ( $self ) = @_;
    $self->requests($self->requests + 1);
    return $self->loop->delay_future(after => 0)->then_done(InLoopResp->new);
  }

  sub build_tool_chat_request {
    my ( $self, $conversation ) = @_;
    push @{$self->recorded}, [ @$conversation ];
    return { request => 1 };
  }

  sub parse_response {
    my ( $self ) = @_;
    my $t = $self->turn + 1;
    $self->turn($t);
    my $has_call = $t <= 6;
    return {
      turn       => $t,
      usage      => { prompt_tokens => 30 * $t, completion_tokens => 1 },
      tool_calls => $has_call ? [ { name => 'noop', input => {} } ] : [],
      text       => $has_call ? '' : 'Fertig',
    };
  }

  sub response_tool_calls   { $_[1]->{tool_calls} // [] }
  sub response_text_content { $_[1]->{text} // 'final' }
  sub extract_tool_call     { ( $_[1]->{name}, $_[1]->{input} ) }
  sub think_tag_filter      { 0 }
  sub format_tools          { $_[1] }

  # A two-message exchange (assistant echo carrying the call + a chunky tool
  # result), so each retained exchange is worth compacting.
  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    my $id = 'c' . $data->{turn};
    return (
      { role => 'assistant', content => '',
        tool_calls => [ { id => $id, type => 'function',
          function => { name => 'noop', arguments => '{}' } } ] },
      { role => 'tool', tool_call_id => $id, content => ( 'RESULT-CHUNK ' x 40 ) },
    );
  }

  __PACKAGE__->meta->make_immutable;
}

my @inline_tools = ({
  name => 'noop', description => 'no-op',
  input_schema => { type => 'object', properties => {} },
  code => sub { $_[0]->text_result('ok') },
});

sub build_raider {
  my $engine = InLoopEngine->new;
  my $raider = Langertha::Raider->new(
    engine                => $engine,
    no_session_embeddings => 1,
    tools                 => \@inline_tools,
    # A large system prompt standing in for ~20k tokens of activated skill text.
    mission               => "You are helpful.\n\n# SKILL perl-things\n"
                             . "$SENTINEL — never drop these instructions.\n"
                             . ( 'skill body line. ' x 300 ),
    max_context_tokens    => 100,
    # threshold default 0.75 -> compaction target 75 tokens
  );
  return ( $engine, $raider );
}

# Runs the raid under an alarm so a hang fails the test instead of stalling CI.
sub raid_result {
  my ( $raider ) = @_;
  my ( $result, $err );
  {
    local $@;
    $result = eval {
      local $SIG{ALRM} = sub { die "TIMEOUT: raid hung\n" };
      alarm 10;
      my $r = $raider->raid('go');
      alarm 0;
      $r;
    };
    $err = $@;
    alarm 0;
  }
  return ( $result, $err );
}

sub tool_msg_count {
  my ( $req ) = @_;
  return scalar grep { ref eq 'HASH' && ( $_->{role} // '' ) eq 'tool' } @$req;
}

sub has_skill_system {
  my ( $req ) = @_;
  return scalar grep {
    ref eq 'HASH' && ( $_->{role} // '' ) eq 'system'
      && index( $_->{content} // '', $SENTINEL ) >= 0
  } @$req;
}

subtest 'in-loop compaction bounds a long raid and keeps skill content' => sub {
  my ( $engine, $raider ) = build_raider();
  my ( $result, $err ) = raid_result($raider);

  unlike($err, qr/TIMEOUT/, 'the raid does not hang');
  is($err, '', 'raid completes without error');
  is("$result", 'Fertig', 'the raid returns the final text');

  my @reqs = @{$engine->recorded};
  ok(@reqs >= 7, 'the raid ran many iterations') or diag "requests=".scalar(@reqs);
  is($raider->metrics->{tool_calls}, 6, 'six tool calls were executed');

  # Skill content: the mission/system prompt survives EVERY turn, before and
  # after compaction — the agent never loses its instructions mid-raid.
  ok(
    ( scalar grep { has_skill_system($_) } @reqs ) == @reqs,
    'every request still carries the skill content in its system prompt'
  );

  # In-loop compaction: the oldest tool exchanges are dropped, so the number of
  # tool results carried in the final request is far below the six that were
  # executed — pre-fix every result stayed and this would equal six.
  my $last_tools = tool_msg_count($reqs[-1]);
  ok($last_tools >= 1, 'the most recent tool exchange is still present');
  ok($last_tools < 6, "the final request drops older tool results (carries $last_tools of 6)");

  # The in-flight conversation stops growing once over threshold: without the
  # fix each request grows by one exchange (2 messages) every iteration and the
  # last would hold header + 6 exchanges = 14 messages.
  my $max = 0;
  $max = @$_ > $max ? scalar @$_ : $max for @reqs;
  ok($max <= 8, "the in-flight conversation stayed bounded (max $max messages)");
};

done_testing;
