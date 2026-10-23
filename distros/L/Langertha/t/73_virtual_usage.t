#!/usr/bin/env perl
# ABSTRACT: Langertha::Engine::Virtual replies carry token usage only when a reaction or default_usage gives it

use strict;
use warnings;

use Test2::Bundle::More;
use Path::Tiny;
use JSON::MaybeXS;
use LWP::Protocol;

use Langertha::Engine::Virtual;
use Langertha::Usage;
use Langertha::Virtual::Rules qw( answer tool tools error );

# A test that counts tokens (a cost meter, a context budget, a Langfuse trace)
# needs replies with usage, and one that checks the "server reported nothing"
# path needs replies without. So usage is opt-in per reaction or per engine
# (default_usage), the default stays without a usage block, and the block is
# OpenAI's wire usage, read by the real OpenAI-dialect parser into
# Response->usage as a Langertha::Usage (ADR 0031) and by Usage->from_raw from
# the completion body (ADR 0028), exactly as from a provider's.

my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );

sub engine {
  return Langertha::Engine::Virtual->new( langfuse_enabled => 0, @_ );
}

# The completion body the engine answers a chat request with.
sub completion {
  my ( $engine, $text ) = @_;
  my $body = $json->encode( { model => 'virtual', messages => [ { role => 'user', content => $text } ] } );
  return $engine->virtual_reply( POST => '/v1/chat/completions', $body )->{content};
}

subtest 'in process: no usage unless a reaction or default_usage gives one' => sub {
  no warnings 'redefine';
  local *LWP::Protocol::create = sub { die "Langertha::Engine::Virtual opened a network protocol\n" };

  my $engine = engine(
    rules => [
      'Plain'   => answer('No count.'),
      'Counted' => answer( 'Counted.', usage => { prompt_tokens => 7, completion_tokens => 3 } ),
      'Call'    => tool( add => { a => 1 }, usage => { prompt_tokens => 20, completion_tokens => 11 } ),
      'Both'    => tools( [ [ add => { a => 1 } ], [ add => { a => 2 } ] ],
        usage => { prompt_tokens => 30, completion_tokens => 18, total_tokens => 50 } ),
      'Cached'  => answer( 'Cached.', usage => {
        prompt_tokens => 100, completion_tokens => 5, prompt_tokens_details => { cached_tokens => 64 } } ),
    ],
  );

  my $plain = $engine->simple_chat('Plain');
  ok( !$plain->has_usage, 'a reaction without usage gives a Response without usage' );
  ok( !exists completion( $engine, 'Plain' )->{usage}, '... and a completion without a usage block' );

  my $counted = $engine->simple_chat('Counted');
  ok( $counted->has_usage, 'a reaction with usage gives a Response with usage' );
  isa_ok( $counted->usage, ['Langertha::Usage'], '... as a Langertha::Usage' );
  is( $counted->usage->input_tokens, 7, 'prompt_tokens are the input tokens' );
  is( $counted->usage->output_tokens, 3, 'completion_tokens are the output tokens' );
  is( $counted->usage->total_tokens, 10, 'the total' );
  is_deeply( completion( $engine, 'Counted' )->{usage},
    { prompt_tokens => 7, completion_tokens => 3, total_tokens => 10 },
    'the wire block gets total_tokens when it was left out' );

  my $call = $engine->chat_f( messages => [ { role => 'user', content => 'Call' } ] )->get;
  is( $call->tool_call('add')->arguments->{a}, 1, 'a tool reaction still calls its tool' );
  is( $call->usage->total_tokens, 31, '... and carries its usage' );

  my $both = $engine->simple_chat_f('Both')->get;
  is( scalar @{ $both->tool_calls }, 2, 'tools(...) calls both tools' );
  is( $both->usage->total_tokens, 50, '... and a given total_tokens is kept as it is' );

  my $cached = $engine->simple_chat('Cached');
  is( $cached->cached_tokens, 64, 'further keys of the block pass through (prompt_tokens_details.cached_tokens)' );

  my $raw = Langertha::Usage->from_raw( completion( $engine, 'Counted' ) );
  is( $raw->input_tokens, 7, 'Usage->from_raw reads the completion body like a provider\'s' );
  is( Langertha::Usage->from_raw( completion( $engine, 'Plain' ) ), undef, '... and finds none without a block' );
};

subtest 'default_usage: a HashRef or a sub, the reaction\'s own usage wins' => sub {
  my $fixed = engine(
    rules => [
      'Hello' => answer('Hi'),
      'Own'   => answer( 'Mine', usage => { prompt_tokens => 1, completion_tokens => 1 } ),
    ],
    default_usage => { prompt_tokens => 10, completion_tokens => 5 },
  );
  is( $fixed->simple_chat('Hello')->usage->total_tokens, 15, 'a HashRef default_usage counts every reply' );
  is( $fixed->simple_chat('Own')->usage->total_tokens, 2, 'a reaction\'s own usage replaces the default' );

  my @seen;
  my $counting = engine(
    rules => [
      'Hello there' => answer('Hi!'),
      'Silent'      => answer('ok'),
      'Bad'         => answer('x'),
      'Call'        => tool( ls => {} ),
    ],
    default_usage => sub {
      my ( $request, $reaction ) = @_;
      push @seen, [ $request->{text}, $reaction ];
      return if $request->{text} eq 'Silent';
      return 'not a hash' if $request->{text} eq 'Bad';
      return { prompt_tokens => length $request->{text}, completion_tokens => length( $reaction->{answer} // '' ) };
    },
  );
  my $response = $counting->simple_chat('Hello there');
  is( $response->usage->input_tokens, 11, 'the sub gets the request' );
  is( $response->usage->output_tokens, 3, '... and the reaction as data' );
  is_deeply( $seen[0][1], { answer => 'Hi!', tool_calls => [] }, 'the reaction is { answer, tool_calls }' );
  $counting->simple_chat('Call');
  is_deeply( $seen[-1][1], { answer => undef, tool_calls => [ [ 'ls', {} ] ] }, '... with the tool calls of a tool reaction' );
  ok( !$counting->simple_chat('Silent')->has_usage, 'a sub returning nothing gives no usage' );
  ok( !eval { $counting->simple_chat('Bad'); 1 }, 'a sub returning something else fails the request' );
  like( $@, qr/500 Reaction Failed.*default_usage returned a non-reference/s, '... as a 500 Reaction Failed naming default_usage' );
};

subtest 'usage in rules files' => sub {
  my $file = Path::Tiny->tempfile( SUFFIX => '.yml' );
  $file->spew_utf8(<<'YAML');
rules:
  Hello: { answer: Hi, usage: { prompt_tokens: 2, completion_tokens: 1 } }
YAML
  my $engine = engine( rules_file => "$file" );
  is( $engine->simple_chat('Hello')->usage->total_tokens, 3, 'a YAML reaction takes usage too' );
};

subtest 'malformed usage croaks when the engine is built' => sub {
  ok( !eval { engine( rules => [ 'x' => { answer => 'y', usage => [1] } ] ); 1 }, 'usage must be a HashRef' );
  like( $@, qr/the usage of rule 1 must be a HashRef/, '... saying where' );
  ok( !eval { engine( rules => [ 'x' => { error => { status => 429, message => 'm' }, usage => {} } ] ); 1 },
    'an error reaction cannot carry usage' );
  like( $@, qr/error together with an answer, tool calls or usage/, '... saying so' );
  ok( !eval { engine( default_usage => [ 1 ] ); 1 }, 'default_usage must be a HashRef or a sub' );
  ok( !eval { answer( 'x', usage => 'many' ); 1 }, 'answer(..., usage => ...) needs a HashRef' );
  ok( !eval { answer( 'x', tokens => {} ); 1 }, 'answer takes no other options' );
  like( $@, qr/unknown options: tokens \(known: usage\)/, '... naming them' );
  ok( !eval { tools( [ tool( a => {}, usage => {} ) ] ); 1 }, 'usage on a tool(...) inside tools(...) croaks' );
  like( $@, qr/give it to tools/, '... pointing to tools(...)' );
  ok( !eval { tools( [ [ a => {}, usage => {} ] ] ); 1 }, 'a call pair with extra elements croaks instead of dropping them' );
};

subtest 'Langertha::Virtual::Server serves the usage block' => sub {
  plan skip_all => 'fork-based server test not supported on Windows' if $^O eq 'MSWin32';
  plan skip_all => 'Requires IO::Async and Net::Async::HTTP'
    unless eval { require IO::Async::Loop; require Net::Async::HTTP; 1 };
  require Langertha::Engine::OpenAI;
  require Langertha::Virtual::Server;
  my $loop   = IO::Async::Loop->new;
  my $engine = engine(
    rules => [
      'Counted' => answer( 'Counted.', usage => { prompt_tokens => 7, completion_tokens => 3 } ),
      'Plain'   => answer('No count.'),
    ],
  );
  my $server = Langertha::Virtual::Server->new( engine => $engine, loop => $loop )->start;
  my $client = Langertha::Engine::OpenAI->new( url => $server->url, api_key => 'unused', langfuse_enabled => 0 );
  my $counted = $client->simple_chat_f('Counted')->get;
  is( "$counted", 'Counted.', 'the reply over HTTP' );
  is( $counted->usage->total_tokens, 10, '... carries the usage, read by the OpenAI engine' );
  ok( !$client->simple_chat_f('Plain')->get->has_usage, 'a reply without usage has none over HTTP either' );
  $server->stop;
};

done_testing;
