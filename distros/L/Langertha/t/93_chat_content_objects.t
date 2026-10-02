#!/usr/bin/env perl
# ABSTRACT: Langertha::Chat serializes Content objects per the engine's content_format
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use Future;
use JSON::MaybeXS;
use HTTP::Response;
use LWP::UserAgent;
use MIME::Base64 qw( encode_base64 );
use Test::MockAsyncHTTP;
use Test::MockMCP;
use Langertha::Chat;
use Langertha::Content::Image;
use Langertha::Engine::OpenAI;
use Langertha::Engine::Anthropic;
use Langertha::Engine::Gemini;

# karr k275: the Langertha::Chat wrapper built its conversation itself and
# never ran the engine's per-message normalization (Role::Chat chat_messages),
# so a Langertha::Content::Image in a message reached chat_request as a blessed
# object instead of the engine's native image block (OpenAI image_url,
# Anthropic image/source, Gemini inline_data parts) -- the request could not
# even be JSON-encoded. The _f paths also skipped the k274 async prefetch, so
# an inline-only engine (Gemini) fetched a URL image with a blocking LWP GET
# inside the event loop. The wrapper's own system prompt and plugin hooks must
# keep working around the normalized messages.

my $json  = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
my $bytes = "\x89PNG-k275";
my $b64   = encode_base64( $bytes, '' );
sub image { Langertha::Content::Image->from_base64( $b64, media_type => 'image/png' ) }

sub http_json {
  my ($body) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    $json->encode($body) );
}

my %REPLY = (
  openai => { id => 'c1', object => 'chat.completion', created => 1, model => 'gpt-x',
    choices => [ { index => 0, finish_reason => 'stop',
      message => { role => 'assistant', content => 'a png' } } ] },
  anthropic => { id => 'msg_1', type => 'message', role => 'assistant', model => 'claude-x',
    stop_reason => 'end_turn', content => [ { type => 'text', text => 'a png' } ] },
  gemini => { candidates => [ { content => { role => 'model',
    parts => [ { text => 'a png' } ] }, finishReason => 'STOP' } ] },
);

# Where the user message's image lands on each wire, and what it must be.
my %CASE = (
  openai => {
    engine => sub { Langertha::Engine::OpenAI->new( api_key => 'k', model => 'gpt-x', @_ ) },
    user   => sub { ( grep { $_->{role} eq 'user' } @{ $_[0]{messages} } )[-1]{content} },
    want   => [ { type => 'text', text => 'What is this?' },
      { type => 'image_url', image_url => { url => "data:image/png;base64,$b64" } } ],
  },
  anthropic => {
    engine => sub { Langertha::Engine::Anthropic->new( api_key => 'k', model => 'claude-x',
      response_size => 64, @_ ) },
    user   => sub { ( grep { $_->{role} eq 'user' } @{ $_[0]{messages} } )[-1]{content} },
    want   => [ { type => 'text', text => 'What is this?' },
      { type => 'image', source => { type => 'base64', media_type => 'image/png', data => $b64 } } ],
  },
  gemini => {
    engine => sub { Langertha::Engine::Gemini->new( api_key => 'k', model => 'gemini-x', @_ ) },
    user   => sub { ( grep { $_->{role} eq 'user' } @{ $_[0]{contents} } )[-1]{parts} },
    want   => [ { text => 'What is this?' },
      { inline_data => { mime_type => 'image/png', data => $b64 } } ],
  },
);

# Records what plugin_before_llm_call saw, so the hooks are proven to fire and
# to see the normalized (JSON-encodable) conversation.
{
  package ChatContentSpy;
  use Moose;
  use Future::AsyncAwait;
  extends 'Langertha::Plugin';
  has before_seen => ( is => 'ro', default => sub { [] } );
  has after_count => ( is => 'ro', default => sub { 0 }, writer => '_set_after_count' );
  async sub plugin_before_llm_call {
    my ( $self, $conversation, $iteration ) = @_;
    push @{ $self->before_seen }, [@$conversation];
    return $conversation;
  }
  async sub plugin_after_llm_response {
    my ( $self, $data, $iteration ) = @_;
    $self->_set_after_count( $self->after_count + 1 );
    return $data;
  }
  __PACKAGE__->meta->make_immutable;
}

# A real LWP::UserAgent (the attribute is typed) serving canned responses.
{
  package ChatContentUA;
  our @ISA = ('LWP::UserAgent');
  sub new { my ( $class, @r ) = @_; my $self = $class->SUPER::new; $self->{queue} = [@r]; $self->{sent} = []; $self }
  sub sent { $_[0]->{sent} }
  sub request {
    my ( $self, $req ) = @_;
    push @{ $self->{sent} }, $req;
    return shift @{ $self->{queue} } // die "ChatContentUA: no canned response left\n";
  }
}

sub user_message { { role => 'user', content => [ 'What is this?', image() ] } }

sub check_wire {
  my ( $name, $req, $label ) = @_;
  my $body = eval { $json->decode( $req->content ) };
  ok $body, "$label: request body is JSON" or return;
  is_deeply $CASE{$name}{user}->($body), $CASE{$name}{want},
    "$label: the image went on the wire in the $name native shape";
}

sub check_plugin {
  my ( $chat, $label ) = @_;
  my $spy = $chat->plugin_instances->[0];
  is scalar @{ $spy->before_seen }, 1, "$label: plugin_before_llm_call fired";
  is $spy->after_count, 1, "$label: plugin_after_llm_response fired";
  my $conv = $spy->before_seen->[0];
  is $conv->[0]{role}, 'system', "$label: the wrapper's system prompt leads the conversation";
  is $conv->[0]{content}, 'Look closely.', "$label: ... with its own text";
  ok eval { $json->encode($conv); 1 },
    "$label: the plugin saw a serialized conversation, no Content objects";
}

for my $name (qw( openai anthropic gemini )) {
  subtest "simple_chat_f: $name" => sub {
    my $http = Test::MockAsyncHTTP->new( responses => [ http_json( $REPLY{$name} ) ] );
    my $chat = Langertha::Chat->new(
      engine        => $CASE{$name}{engine}->( _async_http => $http ),
      system_prompt => 'Look closely.',
      plugins       => ['+ChatContentSpy'],
    );
    my $r = $chat->simple_chat_f( user_message() )->get;
    is "$r", 'a png', 'reply read';
    check_wire( $name, ( $http->requests )[0], 'simple_chat_f' );
    check_plugin( $chat, 'simple_chat_f' );
  };

  subtest "simple_chat (sync): $name" => sub {
    my $ua = ChatContentUA->new( http_json( $REPLY{$name} ) );
    my $chat = Langertha::Chat->new(
      engine        => $CASE{$name}{engine}->( user_agent => $ua ),
      system_prompt => 'Look closely.',
      plugins       => ['+ChatContentSpy'],
    );
    my $r = $chat->simple_chat( user_message() );
    is "$r", 'a png', 'reply read';
    check_wire( $name, $ua->sent->[0], 'simple_chat' );
    check_plugin( $chat, 'simple_chat' );
  };

  subtest "simple_chat_with_tools_f: $name" => sub {
    my $mcp  = Test::MockMCP->new( tools => [ { name => 'noop', description => 'n',
      input_schema => { type => 'object', properties => {} }, code => sub { $_[0]->text_result('x') } } ] );
    my $http = Test::MockAsyncHTTP->new( responses => [ http_json( $REPLY{$name} ) ] );
    my $chat = Langertha::Chat->new(
      engine        => $CASE{$name}{engine}->( _async_http => $http ),
      system_prompt => 'Look closely.',
      mcp_servers   => [$mcp],
      plugins       => ['+ChatContentSpy'],
    );
    my $text = $chat->simple_chat_with_tools_f( user_message() )->get;
    is $text, 'a png', 'final text read';
    check_wire( $name, ( $http->requests )[0], 'simple_chat_with_tools_f' );
    check_plugin( $chat, 'simple_chat_with_tools_f' );
  };

  subtest "simple_chat_with_tools (sync): $name" => sub {
    my $mcp  = Test::MockMCP->new( tools => [ { name => 'noop', description => 'n',
      input_schema => { type => 'object', properties => {} }, code => sub { $_[0]->text_result('x') } } ] );
    my $ua = ChatContentUA->new( http_json( $REPLY{$name} ) );
    my $chat = Langertha::Chat->new(
      engine        => $CASE{$name}{engine}->( user_agent => $ua ),
      system_prompt => 'Look closely.',
      mcp_servers   => [$mcp],
      plugins       => ['+ChatContentSpy'],
    );
    my $text = $chat->simple_chat_with_tools( user_message() );
    is $text, 'a png', 'final text read';
    check_wire( $name, $ua->sent->[0], 'simple_chat_with_tools' );
    check_plugin( $chat, 'simple_chat_with_tools' );
  };
}

# k274 through the wrapper: Gemini inlines every image, so a URL image on the
# _f path is fetched through the engine's async backend before the build --
# the GET is the first request the injected client sees, and LWP never runs.
subtest 'simple_chat_f prefetches a URL image through the async backend (gemini)' => sub {
  my $lwp_calls = 0;
  no warnings 'redefine';
  my $orig = \&LWP::UserAgent::send_request;
  local *LWP::UserAgent::send_request = sub { $lwp_calls++; goto &$orig };

  my $http = Test::MockAsyncHTTP->new( responses => [
    HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'image/png' ], $bytes ),
    http_json( $REPLY{gemini} ),
  ] );
  my $chat = Langertha::Chat->new( engine => $CASE{gemini}{engine}->( _async_http => $http ) );
  my $r = $chat->simple_chat_f( { role => 'user', content => [ 'What is this?',
    Langertha::Content::Image->from_url('http://img.test/a.png') ] } )->get;
  is "$r", 'a png', 'reply read';
  my @req = $http->requests;
  is scalar @req, 2, 'image GET + chat POST, both through the injected client';
  is $req[0]->method, 'GET', 'the image was fetched first';
  is $req[0]->uri, 'http://img.test/a.png', '... from its URL';
  is $lwp_calls, 0, '... without a blocking LWP request';
  check_wire( 'gemini', $req[1], 'prefetched' );
};

done_testing;
