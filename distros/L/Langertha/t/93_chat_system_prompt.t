#!/usr/bin/env perl
# ABSTRACT: Langertha::Chat sends the engine's system prompt unless it has its own
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use HTTP::Response;
use LWP::UserAgent;
use Test::MockAsyncHTTP;
use Langertha::Chat;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;
use Langertha::Engine::NousResearch;

# karr k277: the Langertha::Chat wrapper built its conversation itself and only
# prepended its own system_prompt, so an engine configured with a system_prompt
# silently lost it behind the wrapper (and NousResearch lost its reasoning
# prompt, which switches the model into <think> mode). The wrapper must send
# the system messages the engine's own chat_messages would send; a wrapper
# system_prompt replaces the engine's persona text only, while an
# engine-mandated prefix (the Nous reasoning prompt) still leads. Plugins see
# the same conversation that goes on the wire.

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );

sub http_json {
  my ($body) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode($body) );
}

my $openai_reply = { id => 'c1', object => 'chat.completion', created => 1, model => 'm',
  choices => [ { index => 0, finish_reason => 'stop',
    message => { role => 'assistant', content => 'ok' } } ] };

my %CASE = (
  openai => {
    engine => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x', @_ ) },
    reply  => $openai_reply,
    system => sub { [ map { $_->{content} } grep { $_->{role} eq 'system' } @{ $_[0]{messages} } ] },
  },
  anthropic => {
    engine => sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x',
      response_size => 64, @_ ) },
    reply  => { id => 'msg_1', type => 'message', role => 'assistant', model => 'claude-x',
      stop_reason => 'end_turn', content => [ { type => 'text', text => 'ok' } ] },
    # Anthropic: top-level system, no system role in messages.
    system => sub {
      ok !( grep { $_->{role} eq 'system' } @{ $_[0]{messages} } ), 'anthropic: no system role in messages';
      [ defined $_[0]{system} ? $_[0]{system} : () ];
    },
  },
  gemini => {
    engine => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x', @_ ) },
    reply  => { candidates => [ { content => { role => 'model', parts => [ { text => 'ok' } ] },
      finishReason => 'STOP' } ] },
    system => sub { [ $_[0]{systemInstruction} ? map { $_->{text} } @{ $_[0]{systemInstruction}{parts} } : () ] },
  },
);

{
  package ChatSystemSpy;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  has seen => ( is => 'ro', default => sub { [] } );
  async sub plugin_before_llm_call {
    my ( $self, $conversation, $iteration ) = @_;
    push @{ $self->seen }, [@$conversation];
    return $conversation;
  }
  __PACKAGE__->meta->make_immutable;
}

{
  package ChatSystemUA;
  our @ISA = ('LWP::UserAgent');
  sub new { my ( $class, @r ) = @_; my $self = $class->SUPER::new; $self->{queue} = [@r]; $self->{sent} = []; $self }
  sub sent { $_[0]->{sent} }
  sub request {
    my ( $self, $req ) = @_;
    push @{ $self->{sent} }, $req;
    return shift @{ $self->{queue} } // die "ChatSystemUA: no canned response left\n";
  }
}

sub plugin_system {
  my ($chat) = @_;
  my $conv = $chat->plugin_instances->[0]->seen->[0];
  return [ map { $_->{content} } grep { $_->{role} eq 'system' } @$conv ];
}

for my $name (qw( openai anthropic gemini )) {
  my $case = $CASE{$name};

  subtest "$name: wrapper without system_prompt sends the engine's (async)" => sub {
    my $http = Test::MockAsyncHTTP->new( responses => [ http_json( $case->{reply} ) ] );
    my $chat = Langertha::Chat->new(
      engine  => $case->{engine}->( _async_http => $http, system_prompt => 'Engine persona.' ),
      plugins => ['+ChatSystemSpy'],
    );
    is "" . $chat->simple_chat_f('Hi')->get, 'ok', 'reply read';
    my $body = $json->decode( ( $http->requests )[0]->content );
    is_deeply $case->{system}->($body), ['Engine persona.'], "the engine's system prompt went on the wire";
    is_deeply plugin_system($chat), ['Engine persona.'], 'the plugin saw it too';
  };

  subtest "$name: wrapper without system_prompt sends the engine's (sync)" => sub {
    my $ua = ChatSystemUA->new( http_json( $case->{reply} ) );
    my $chat = Langertha::Chat->new(
      engine => $case->{engine}->( user_agent => $ua, system_prompt => 'Engine persona.' ),
    );
    is "" . $chat->simple_chat('Hi'), 'ok', 'reply read';
    my $body = $json->decode( $ua->sent->[0]->content );
    is_deeply $case->{system}->($body), ['Engine persona.'], "the engine's system prompt went on the wire";
  };

  subtest "$name: the wrapper's system_prompt wins over the engine's" => sub {
    my $http = Test::MockAsyncHTTP->new( responses => [ http_json( $case->{reply} ) ] );
    my $chat = Langertha::Chat->new(
      engine        => $case->{engine}->( _async_http => $http, system_prompt => 'Engine persona.' ),
      system_prompt => 'Wrapper persona.',
      plugins       => ['+ChatSystemSpy'],
    );
    $chat->simple_chat_f('Hi')->get;
    my $body = $json->decode( ( $http->requests )[0]->content );
    is_deeply $case->{system}->($body), ['Wrapper persona.'], 'only the wrapper system prompt went on the wire';
    is_deeply plugin_system($chat), ['Wrapper persona.'], 'the plugin saw the same';
  };

  subtest "$name: neither has a system_prompt" => sub {
    my $http = Test::MockAsyncHTTP->new( responses => [ http_json( $case->{reply} ) ] );
    my $chat = Langertha::Chat->new( engine => $case->{engine}->( _async_http => $http ) );
    $chat->simple_chat_f('Hi')->get;
    my $body = $json->decode( ( $http->requests )[0]->content );
    is_deeply $case->{system}->($body), [], 'no system prompt on the wire';
  };
}

# NousResearch: the reasoning prompt is engine-mandated -- it leads whether the
# system text comes from the engine or the wrapper, as in chat_messages.
sub nous { Langertha::Engine::NousResearch->new( api_key => 'k', reasoning => 1, @_ ) }
sub nous_system { [ map { $_->{content} } grep { $_->{role} eq 'system' } @{ $_[0]{messages} } ] }

subtest 'NousResearch: reasoning prompt + engine system prompt through the wrapper' => sub {
  my $http   = Test::MockAsyncHTTP->new( responses => [ http_json($openai_reply) ] );
  my $engine = nous( _async_http => $http, system_prompt => 'Engine persona.' );
  my $chat   = Langertha::Chat->new( engine => $engine, plugins => ['+ChatSystemSpy'] );
  $chat->simple_chat_f('Hi')->get;
  my $want = [ $engine->reasoning_prompt, 'Engine persona.' ];
  is_deeply nous_system( $json->decode( ( $http->requests )[0]->content ) ), $want,
    'reasoning prompt first, then the engine system prompt';
  is_deeply [ map { $_->{content} } grep { $_->{role} eq 'system' } @{ $engine->chat_messages('Hi') } ],
    $want, '... exactly what the engine itself sends';
  is_deeply plugin_system($chat), $want, 'the plugin saw the same';
};

subtest 'NousResearch: reasoning prompt stays with a wrapper system prompt' => sub {
  my $http   = Test::MockAsyncHTTP->new( responses => [ http_json($openai_reply) ] );
  my $engine = nous( _async_http => $http, system_prompt => 'Engine persona.' );
  my $chat   = Langertha::Chat->new( engine => $engine, system_prompt => 'Wrapper persona.' );
  $chat->simple_chat_f('Hi')->get;
  is_deeply nous_system( $json->decode( ( $http->requests )[0]->content ) ),
    [ $engine->reasoning_prompt, 'Wrapper persona.' ],
    'reasoning prompt first, the wrapper persona replaces the engine one';
};

subtest 'NousResearch: reasoning off sends no reasoning prompt' => sub {
  my $http = Test::MockAsyncHTTP->new( responses => [ http_json($openai_reply) ] );
  my $chat = Langertha::Chat->new(
    engine => nous( _async_http => $http, reasoning => 0 ),
    system_prompt => 'Wrapper persona.',
  );
  $chat->simple_chat_f('Hi')->get;
  is_deeply nous_system( $json->decode( ( $http->requests )[0]->content ) ),
    ['Wrapper persona.'], 'only the wrapper persona';
};

done_testing;
