#!/usr/bin/env perl
# ABSTRACT: /compact [INSTRUCTIONS] summarises the history now, the instructions reach the summary request (ADR 0030 §5, k165)
use strict;
use warnings;
use utf8;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Encode qw( decode_utf8 );
use File::Temp qw( tempdir );
use IO::Async::Loop;
use JSON::MaybeXS ();
use Langertha::Engine::OpenAI;
use Langertha::Raider;
use Langertha::Raider::CLI;
use Langertha::Raider::CLI::Commands;
use Langertha::Raider::CLI::Output;

delete @ENV{ grep { /_API_KEY\z/ } keys %ENV };

{
  # A duck-typed engine: records the messages of every summary request and
  # answers with a canned summary (the legacy reader path, no network).
  package RecordingEngine;
  use Moose;
  has _loop    => ( is => 'ro', default => sub { IO::Async::Loop->new } );
  has requests => ( is => 'ro', default => sub { [] } );
  sub async_loop { $_[0]->_loop }
  sub chat_request { my ( $self, $messages ) = @_; push @{ $self->requests }, $messages; return { request => 1 } }
  sub async_request_f { $_[0]->_loop->delay_future( after => 0 )->then_done({ text => 'the summary' }) }
  sub parse_response        { $_[1] }
  sub response_text_content { $_[1]->{text} }
  __PACKAGE__->meta->make_immutable;
}

{
  # A real OpenAI engine whose only override is the HTTP round trip: answers
  # with a canned 200 body and keeps the decoded request bodies.
  package FakeOpenAI;
  use Moose;
  use HTTP::Response;
  extends 'Langertha::Engine::OpenAI';
  has _loop  => ( is => 'ro', default => sub { IO::Async::Loop->new } );
  has body   => ( is => 'rw', required => 1 );
  has bodies => ( is => 'ro', default => sub { [] } );
  sub async_loop { $_[0]->_loop }
  sub async_request_f {
    my ( $self, $request ) = @_;
    push @{ $self->bodies }, $self->json->decode($request->content);
    my $http = HTTP::Response->new(200, 'OK', [ 'Content-Type' => 'application/json' ], $self->json->encode($self->body));
    return $self->_loop->delay_future( after => 0 )->then_done($http);
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package FakeEngineCLI;
  use Moose;
  extends 'Langertha::Raider::CLI';
  has fake => ( is => 'ro', required => 1 );
  sub _build_engine { $_[0]->fake }
  __PACKAGE__->meta->make_immutable;
}

sub reply { { id => 'c1', model => 'gpt-test', choices => [ { index => 0, finish_reason => 'stop',
  message => { role => 'assistant', content => $_[0] } } ] } }

# Fails instead of hanging when a future never completes.
sub in_time {
  my ( $code ) = @_;
  local $SIG{ALRM} = sub { die "TIMEOUT\n" };
  alarm 10;
  my @r = $code->();
  alarm 0;
  return @r;
}

my @turns = ( { role => 'user', content => 'build the API' }, { role => 'assistant', content => 'done, with v2 routes' } );

subtest 'compress_history: instructions follow the summary request' => sub {
  my $engine = RecordingEngine->new;
  my $raider = Langertha::Raider->new( engine => $engine, no_session_embeddings => 1, history => [ @turns ] );
  my ($summary) = in_time(sub { $raider->compress_history( instructions => 'Keep the route names.' ) });
  is($summary, 'the summary', 'the summary');
  is(scalar @{ $engine->requests }, 1, 'one request');
  my $messages = $engine->requests->[0];
  is($messages->[0]{role}, 'system', 'the compression prompt first');
  is([ @$messages[1, 2] ], \@turns, 'then the history');
  is($messages->[-1], { role => 'user',
    content => "Provide a concise summary.\n\nAdditional instructions:\nKeep the route names." },
    'the instructions after the request');
  is($raider->history, [ { role => 'assistant', content => 'the summary' } ], 'history replaced');
};

subtest 'compress_history without instructions is unchanged' => sub {
  for my $args ([], [ instructions => undef ], [ instructions => "  \n" ]) {
    my $engine = RecordingEngine->new;
    my $raider = Langertha::Raider->new( engine => $engine, no_session_embeddings => 1, history => [ @turns ] );
    in_time(sub { $raider->compress_history(@$args) });
    is($engine->requests->[0][-1], { role => 'user', content => 'Provide a concise summary.' },
      'plain request ('.scalar(@$args).' args)');
  }
  my $engine = RecordingEngine->new;
  my $raider = Langertha::Raider->new( engine => $engine, no_session_embeddings => 1 );
  is([ in_time(sub { $raider->compress_history( instructions => "x" ) }) ], [], "empty history: nothing returned");
  is($engine->requests, [], 'and no request');
};

subtest 'compress_history_f takes the same instructions' => sub {
  my $engine = RecordingEngine->new;
  my $raider = Langertha::Raider->new( engine => $engine, no_session_embeddings => 1, history => [ @turns ] );
  my ($summary) = in_time(sub { $raider->compress_history_f( instructions => 'Only the errors.' )->get });
  is($summary, 'the summary', 'summary');
  like($engine->requests->[0][-1]{content}, qr/\nAdditional instructions:\nOnly the errors\.\z/, 'instructions sent');
};

subtest 'the next raid does not compress the summary again' => sub {
  # The last prompt size measured the history the summary replaced. Kept, it
  # is still over the threshold and the next raid compresses the one-message
  # summary once more before it starts.
  my $compressor = RecordingEngine->new;
  my $engine = FakeOpenAI->new( api_key => 'x', body => reply('next answer') );
  my $raider = Langertha::Raider->new( engine => $engine, compression_engine => $compressor,
    no_session_embeddings => 1, raider_mcp => 1, max_context_tokens => 100, context_compress_threshold => 0.5,
    history => [ @turns ] );
  $raider->_last_prompt_tokens(1000);
  in_time(sub { $raider->compress_history( instructions => 'Keep the routes.' ) });
  is(scalar @{ $compressor->requests }, 1, 'compressed once');
  ok(!$raider->has_last_prompt_tokens, 'the old prompt size is forgotten');
  my ($result) = in_time(sub { $raider->raid('and now?') });
  is("$result", 'next answer', 'the raid ran');
  is(scalar @{ $compressor->requests }, 1, 'no second compression before the raid');
  ok((grep { ( $_->{content} // '' ) eq 'the summary' } @{ $engine->bodies->[0]{messages} }),
    'the raid got the summary as its history');
};

sub commands_for {
  my ( $engine ) = @_;
  my $app = FakeEngineCLI->new( fake => $engine, root => tempdir( CLEANUP => 1 ), engine => 'openai',
    api_key => 'x', model => 'gpt-test', trace => 0 );
  my $buf = '';
  open my $fh, '>:encoding(UTF-8)', \$buf or die $!;
  my $cmds = Langertha::Raider::CLI::Commands->new(
    app => $app, output => Langertha::Raider::CLI::Output->new( out => $fh, color => 0 ) );
  my $read = sub { $fh->flush; my $t = decode_utf8($buf); $buf = ''; seek $fh, 0, 0; $t };
  return ( $app, $cmds, $read );
}

subtest '/compact INSTRUCTIONS through the app' => sub {
  my $engine = FakeOpenAI->new( api_key => 'x', body => reply('x' x 40) );
  my ( $app, $cmds, $read ) = commands_for($engine);

  is($cmds->cmd_compact(''), undef, 'returns nothing');
  is($read->(), "nothing to compact.\n", 'empty history');
  is($engine->bodies, [], 'no request');

  $app->raider->history([ @turns ]);
  in_time(sub { $cmds->cmd_compact('keep the v2 routes') });
  is($read->(), "history compacted (2 messages → summary, ~10 tokens)\n", 'the report');
  is($app->raider->history, [ { role => 'assistant', content => 'x' x 40 } ], 'history is the summary');
  my $messages = $engine->bodies->[0]{messages};
  is($messages->[-1]{content}, "Provide a concise summary.\n\nAdditional instructions:\nkeep the v2 routes",
    'the instructions reached the summary request');

  in_time(sub { $cmds->cmd_compact });
  is($read->(), "history compacted (1 message → summary, ~10 tokens)\n", 'again, without instructions');
  is($engine->bodies->[1]{messages}[-1]{content}, 'Provide a concise summary.', 'plain request');
};

subtest '/compact reports a failed summary and keeps the history' => sub {
  plan skip_all => 'this Langertha has no public chat_response hook'
    unless Langertha::Engine::OpenAI->can('chat_response');
  my $engine = FakeOpenAI->new( api_key => 'x', body => { error => { message => 'upstream exploded', type => 'server_error' } } );
  my ( $app, $cmds, $read ) = commands_for($engine);
  $app->raider->history([ @turns ]);
  in_time(sub { $cmds->cmd_compact('x') });
  like($read->(), qr/\Aerror: compact failed: .*upstream exploded/, 'the error');
  is($app->raider->history, \@turns, 'history untouched');
};

done_testing;
