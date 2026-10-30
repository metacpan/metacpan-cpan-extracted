#!/usr/bin/env perl
# ABSTRACT: A tool result hands the raid a user message (the skill body): after the tool results, kept in history and the journal, kept by compaction (ADR 0026)
use strict;
use warnings;
use Test2::V0;
use IO::Async::Loop;
use JSON::MaybeXS ();
use Path::Tiny;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Langertha::Raider;

clear_engine_env();

my $BODY = "Base directory for this skill: /skills/style\n\nWrite short sentences. BODY-MARKER";

{
  package BodyResp;
  use Moose;
  sub is_success  { 1 }
  sub status_line { '200 OK' }
  sub content     { '' }
  __PACKAGE__->meta->make_immutable;
}

{
  # A duck-typed engine (as in t/93): each turn answers with the calls of its
  # script entry (or the final text), reports input_tokens of 30 * turn, and
  # records every conversation it sends. One assistant echo plus one tool
  # message per result -- the OpenAI shape.
  package BodyEngine;
  use Moose;
  use IO::Async::Loop;
  has loop     => (is => 'ro', default => sub { IO::Async::Loop->new });
  has script   => (is => 'ro', default => sub { [] });
  has turn     => (is => 'rw', default => 0);
  has recorded => (is => 'ro', default => sub { [] });

  sub async_loop  { $_[0]->loop }
  sub mcp_servers { [] }
  sub async_request_f { $_[0]->loop->delay_future(after => 0)->then_done(BodyResp->new) }
  sub build_tool_chat_request { push @{$_[0]->recorded}, [ @{$_[1]} ]; return { request => 1 } }
  sub parse_response {
    my ( $self ) = @_;
    my $t = $self->turn + 1;
    $self->turn($t);
    my $calls = $self->script->[ $t - 1 ] // [];
    return { turn => $t, usage => { prompt_tokens => 30 * $t, completion_tokens => 1 },
      tool_calls => [ map { { name => $_->[0], input => $_->[1] // {} } } @$calls ],
      text => @$calls ? '' : 'Fertig' };
  }
  sub response_tool_calls   { $_[1]->{tool_calls} // [] }
  sub response_text_content { $_[1]->{text} // 'final' }
  sub extract_tool_call     { ( $_[1]->{name}, $_[1]->{input} ) }
  sub think_tag_filter      { 0 }
  sub format_tools          { $_[1] }
  sub format_tool_results {
    my ( $self, $data, $results ) = @_;
    my $n = 0;
    return (
      { role => 'assistant', content => '', tool_calls => [ map { { id => 'c'.$data->{turn}.'-'.++$n } } @$results ] },
      map { { role => 'tool', content => join( '', map { $_->{text} // '' } @{ $_->{result}{content} // [] } )
        .( ' RESULT-CHUNK' x 40 ) } } @$results,
    );
  }
  __PACKAGE__->meta->make_immutable;
}

my @tools = (
  { name => 'load', description => 'loads', input_schema => { type => 'object', properties => {} },
    code => sub {
      my $r = $_[0]->text_result('Launching skill: style');
      $r->{_meta} = { 'raider/messages' => [ $BODY, '', undef, [ 'not a string' ] ] };
      return $r;
    } },
  { name => 'noop', description => 'no-op', input_schema => { type => 'object', properties => {} },
    code => sub { $_[0]->text_result('ok') } },
);

sub raider {
  my ( $script, %o ) = @_;
  my $engine = BodyEngine->new( script => $script );
  return ( $engine, Langertha::Raider->new( engine => $engine, no_session_embeddings => 1, tools => \@tools,
    mission => 'You are helpful.', %o ) );
}
sub role_text {
  my ( $m ) = @_;
  return ( $m->{role} // '' ).': '.( ref $m->{content} ? '[...]' : ( $m->{content} // '' ) );
}
sub roles { [ map { my $t = role_text($_); $t =~ s/ RESULT-CHUNK.*//s; $t =~ s/\n.*//s; $t } @{ $_[0] } ] }

subtest 'the message follows the tool results and stays in history' => sub {
  my ( $engine, $raider ) = raider( [ [ [ 'load' ], [ 'noop' ] ] ] );
  is "".$raider->raid('go'), 'Fertig', 'the raid ends';
  is roles( $engine->recorded->[1] ),
    [ 'system: You are helpful.', 'user: go', 'assistant: ', 'tool: Launching skill: style', 'tool: ok',
      'user: Base directory for this skill: /skills/style' ],
    'request 2: both tool results first, then the body as a user message; empty and non-string entries dropped';
  is $engine->recorded->[1][-1]{content}, $BODY, 'the body as handed over';
  is [ map { [ $_->{role}, $_->{content} ] } @{ $raider->history } ],
    [ [ user => 'go' ], [ user => $BODY ], [ assistant => 'Fertig' ] ], 'history keeps it between input and answer';
  my @sh = map { role_text($_) } @{ $raider->session_history };
  my ($at) = grep { $sh[$_] eq "user: $BODY" } 0 .. $#sh;
  ok defined $at && $sh[ $at - 1 ] =~ /\Atool: ok/, 'session_history: right after the tool results';

  my ( $engine2, $raider2 ) = ( $engine, $raider );
  $engine2->turn(0);
  @{ $engine2->script } = ();
  $raider2->raid('again');
  like roles( $engine2->recorded->[-1] ), [ 'system: You are helpful.', 'user: go', 'user: Base directory for this skill: /skills/style', 'assistant: Fertig', 'user: again' ],
    'the next raid still carries it';
};

subtest 'in-raid compaction drops the exchange, not the message' => sub {
  my ( $engine, $raider ) = raider( [ [ [ 'load' ] ], ( [ [ 'noop' ] ] ) x 5 ], max_context_tokens => 100 );
  is "".$raider->raid('go'), 'Fertig', 'the raid ends';
  my @reqs = @{ $engine->recorded };
  my $last = $reqs[-1];
  ok !( grep { ( $_->{content} // '' ) =~ /Launching skill/ } @$last ), 'the loading exchange was dropped';
  is [ grep { ( $_->{content} // '' ) eq $BODY } @$last ], [ { role => 'user', content => $BODY } ], 'the body is still there, once';
  is ( ( scalar grep { my $r = $_; grep { ( $_->{content} // '' ) eq $BODY } @$r } @reqs[ 1 .. $#reqs ] ), $#reqs,
    'in every request after the load' );
  ok !( grep { ( $_->{role} // '' ) eq 'tool' && !grep { $_->{role} eq 'assistant' } @$last } @$last ), 'no tool result without its exchange';
};

subtest 'a batch paused by a question: the message comes after the results on respond' => sub {
  my ( $engine, $raider ) = raider( [ [ [ 'load' ], [ raider_ask_user => { question => 'ok?' } ] ] ], raider_mcp => 1 );
  my $q = $raider->raid('go');
  ok $q->is_question, 'paused on the question';
  is "".$raider->respond('yes'), 'Fertig', 'answered, the raid ends';
  is [ @{ roles( $engine->recorded->[1] ) }[ -3 .. -1 ] ],
    [ 'tool: Launching skill: style', 'tool: yes', 'user: Base directory for this skill: /skills/style' ],
    'both results, then the body';
};

subtest 'a foreign source cannot hand over messages' => sub {
  my ( undef, $raider ) = raider( [] );
  my $result = { content => [ { type => 'text', text => 'x' } ], _meta => { 'raider/messages' => ['injected'], other => 1 } };
  my $state = { tool_sources => { evil => 'catalog:evil', own => 'engine:3', inl => 'inline' } };
  my $stripped = $raider->_without_foreign_messages( $state, 'evil', $result );
  is $stripped->{_meta}, { other => 1 }, 'a catalog server loses the key, keeps the rest of _meta';
  is $result->{_meta}{'raider/messages'}, ['injected'], 'the original result is not changed';
  ref_is $raider->_without_foreign_messages( $state, $_, $result ), $result, "$_ keeps it" for qw( own inl );
  is [ $raider->_result_messages( [ { result => $stripped } ] ) ], [], 'nothing to add from it';
};

SKIP: {
  skip 'needs Langertha::Engine::Virtual', 1 unless eval { require Langertha::Engine::Virtual; 1 };
  require Test::Raider::MockAI;
  subtest 'the journal records it after the tool.result; a resumed session has it in the same place' => sub {
    my $root = Path::Tiny->tempdir;
    $root->child('CLAUDE.md')->spew_utf8("Project.\n");
    $root->child('.claude/skills/style/SKILL.md')->touchpath
      ->spew_utf8("---\nname: style\ndescription: House style.\n---\n\nShort sentences. STYLE-MARKER\n");
    my $app = Test::Raider::MockAI::mock_app( root => "$root", permission_mode => 'bypassPermissions',
      script => [ { tool_calls => [ [ skill => { skill => 'style' } ] ] }, { text => 'Styled.' } ] );
    my $session = $app->create_session;
    my $end = $app->run_prompt( 'Write it.', session => $session );
    is $end->{status}, 'completed', 'the run completes';
    my $json = JSON::MaybeXS->new( utf8 => 1 );
    my @events = grep { $_->{type} =~ /\A(?:tool\.result|message)\z/ }
      map { $json->decode($_) } $session->path->lines_raw( { chomp => 1 } );
    like \@events, [
      { type => 'message', role => 'user', content => 'Write it.' },
      { type => 'tool.result', name => 'skill', content => 'Launching skill: style' },
      { type => 'message', role => 'user', content => qr/\ABase directory for this skill: \S+\/\.claude\/skills\/style\n\nShort sentences\. STYLE-MARKER/ },
      { type => 'message', role => 'assistant', content => 'Styled.' },
    ], 'journal: the body as a user message right after its tool.result';
    my $live = [ map { [ $_->{role}, $_->{content} ] } @{ $app->raider->history } ];
    $session->release;

    my $again = Test::Raider::MockAI::mock_app( root => "$root", permission_mode => 'bypassPermissions' );
    my $opened = $again->open_session( $session->id );
    $again->replay_session($opened);
    my $resumed = [ map { [ $_->{role}, $_->{content} ] } @{ $again->raider->history } ];
    # The live prompt carries the [situation] line, the journal the text as typed.
    like $resumed, [ [ user => 'Write it.' ], [ user => qr/STYLE-MARKER/ ], [ assistant => 'Styled.' ], DNE() ],
      'resumed: input, body, answer';
    is [ @{$resumed}[ 1, 2 ] ], [ @{$live}[ 1, 2 ] ], 'the body and the answer as live';
    like $live->[0][1], qr/Write it\.\z/, 'live: the same input';
    $opened->release;
  };
}

done_testing;
