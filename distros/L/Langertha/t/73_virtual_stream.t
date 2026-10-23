#!/usr/bin/env perl
# ABSTRACT: Langertha::Engine::Virtual streams like an OpenAI server: text in pieces, tool calls as delta fragments, usage on request

use strict;
use warnings;
use utf8;

use Test2::Bundle::More;
use JSON::MaybeXS;
use LWP::Protocol;

use Langertha::Engine::Virtual;
use Langertha::Virtual::Rules qw( answer tool tools error );

# Code that consumes a stream (a chat UI, a proxy, a tool loop that streams)
# has to be tested against a stream that looks like a provider's: text in
# many small chunks, a tool call assembled from fragments (karr k221), the
# finish_reason on its own event and, with stream_options.include_usage, a
# trailing usage event with no choice (karr k298). The virtual engine produces
# exactly that, and the real OpenAI-dialect stream parser reads it, so a
# streamed reply must give the same text and the same ToolCalls as the
# non-streamed reply of the same reaction.

sub engine {
  return Langertha::Engine::Virtual->new(
    rules => [
      'Hello'   => answer( 'Hi there, how are you?', usage => { prompt_tokens => 4, completion_tokens => 6 } ),
      'Umlaut'  => answer('Grüße aus Köln'),
      'Add'     => tool( add => { a => 2, b => 3 } ),
      'Two'     => tools( [ [ add => { a => 1, b => 1 } ], [ mul => { a => 20, b => 30 } ] ] ),
      'Both'    => { answer => 'Let me add.', tool_calls => [ [ add => { a => 4, b => 5 } ] ] },
      'Limit'   => error( 429, 'Rate limit reached' ),
    ],
    langfuse_enabled => 0,
    @_,
  );
}

sub stream {
  my ( $engine, $text, %opts ) = @_;
  my @seen;
  my ( $content, $chunks ) = $engine->chat_stream_realtime_f(
    messages       => [ { role => 'user', content => $text } ],
    chunk_callback => sub { push @seen, $_[0] },
    %opts,
  )->get;
  return ( $content, $chunks, \@seen );
}

sub texts { return [ grep { length } map { $_->content } @{ $_[0] } ] }

subtest 'in process: text in pieces of stream_chunk_size characters' => sub {
  no warnings 'redefine';
  local *LWP::Protocol::create = sub { die "Langertha::Engine::Virtual opened a network protocol\n" };

  my $engine = engine();
  ok( $engine->supports('streaming'), 'the engine claims streaming' );
  is( $engine->stream_format, 'sse', 'as server-sent events' );

  # The engine asks for the usage itself (stream_usage, ADR 0038); turned off
  # here, the stream ends with the finish chunk.
  my ( $content, $chunks, $seen ) = stream( $engine, 'Hello',
    stream_options => { include_usage => JSON::MaybeXS::false } );
  is( $content, 'Hi there, how are you?', 'the streamed text is the answer' );
  is_deeply( texts($seen), [ 'Hi there', ', how ar', 'e you?' ], 'the callback gets it in pieces of 8 characters' );
  is( scalar @$seen, scalar @$chunks, 'the callback sees every chunk' );
  ok( $chunks->[-1]->is_final, 'the last chunk is final' );
  is( $chunks->[-1]->finish_reason, 'stop', '... with finish_reason stop' );
  ok( !( grep { $_->has_usage } @$chunks ), 'no usage with stream_options.include_usage false' );
  ok( $engine->requests->[-1]{body}{stream}, 'the request was a stream request' );

  my $small = engine( stream_chunk_size => 3 );
  my ( $umlaut, undef, $pieces ) = stream( $small, 'Umlaut' );
  is( $umlaut, 'Grüße aus Köln', 'non-ASCII text survives' );
  is_deeply( texts($pieces), [ 'Grü', 'ße ', 'aus', ' Kö', 'ln' ], 'pieces count characters, not bytes' );

  my ( undef, undef, $single ) = stream( engine( stream_chunk_size => 1 ), 'Hello' );
  is( scalar @{ texts($single) }, length 'Hi there, how are you?', 'stream_chunk_size 1 streams character by character' );

  ok( !eval { engine( stream_chunk_size => 0 ); 1 }, 'stream_chunk_size 0 croaks' );
  like( $@, qr/stream_chunk_size must be at least 1/, '... saying so' );
};

subtest 'in process: usage as the last event with stream_options.include_usage' => sub {
  my $engine = engine();
  my ( $content, $chunks ) = stream( $engine, 'Hello', stream_options => { include_usage => 1 } );
  is( $content, 'Hi there, how are you?', 'the text is unchanged' );
  my $last = $chunks->[-1];
  ok( !$last->is_final, 'the usage chunk comes after the final chunk and is not final itself' );
  is( $last->content, '', '... and has no text' );
  is_deeply( $engine->aggregate_usage($chunks), { prompt_tokens => 4, completion_tokens => 6, total_tokens => 10 },
    'aggregate_usage finds the usage' );
  ok( $chunks->[-2]->is_final, 'the final chunk is the one before' );

  my ( undef, $none ) = stream( engine(), 'Umlaut', stream_options => { include_usage => 1 } );
  is( $engine->aggregate_usage($none), undef, 'a reaction without usage adds no usage event' );

  my ( undef, $defaulted ) = stream( engine( default_usage => { prompt_tokens => 1, completion_tokens => 2 } ),
    'Umlaut', stream_options => { include_usage => 1 } );
  is( $engine->aggregate_usage($defaulted)->{total_tokens}, 3, 'default_usage streams too' );
};

subtest 'in process: tool calls stream as delta fragments and match the non-streamed calls' => sub {
  my $engine = engine();
  my $chunks = $engine->virtual_stream_chunks(
    $engine->virtual_reply( POST => '/v1/chat/completions', JSON::MaybeXS->new( utf8 => 1 )->encode(
      { model => 'virtual', messages => [ { role => 'user', content => 'Add' } ] } ) )->{content} );
  my @fragments = map { @{ $_->{choices}[0]{delta}{tool_calls} // [] } } @$chunks;
  is_deeply( [ map { $_->{function}{arguments} } @fragments ], [ '', '{"a":2,"', 'b":3}' ],
    'the opening fragment has empty arguments, the arguments follow in pieces' );
  is( $fragments[0]{function}{name}, 'add', 'the opening fragment names the function' );
  like( $fragments[0]{id}, qr/\Acall_virtual_\d+\z/, '... and carries the id' );
  ok( !exists $fragments[1]{id} && !exists $fragments[1]{function}{name}, 'the following fragments carry only arguments' );
  is( $chunks->[0]{choices}[0]{delta}{role}, 'assistant', 'the first event carries the role' );
  is( $chunks->[-1]{choices}[0]{finish_reason}, 'tool_calls', 'the last event the finish_reason' );

  for my $prompt (qw( Add Two Both )) {
    my $plain = $engine->chat_f( messages => [ { role => 'user', content => $prompt } ] )->get;
    my ( $content, $streamed ) = stream( $engine, $prompt );
    my $calls = $engine->aggregate_tool_calls($streamed);
    is_deeply( [ map { [ $_->name, $_->arguments ] } @$calls ],
      [ map { [ $_->name, $_->arguments ] } @{ $plain->tool_calls } ],
      "'$prompt': the streamed tool calls are the non-streamed ones" );
    is( $content, $plain->content // '', "'$prompt': the same text" );
    is( $streamed->[-1]->finish_reason, 'tool_calls', "'$prompt': finishes with tool_calls" );
  }
};

subtest 'in process: the synchronous stream methods and failures' => sub {
  my $engine = engine();
  my @pieces;
  my $content = $engine->simple_chat_stream( sub { push @pieces, $_[0]->content }, 'Hello' );
  is( $content, 'Hi there, how are you?', 'simple_chat_stream' );
  is_deeply( [ grep { length } @pieces ], [ 'Hi there', ', how ar', 'e you?' ], '... calls back per piece' );
  my $iterator = $engine->simple_chat_stream_iterator('Hello');
  my $text = '';
  while ( my $chunk = $iterator->next ) { $text .= $chunk->content }
  is( $text, 'Hi there, how are you?', 'simple_chat_stream_iterator' );

  my $failure = $engine->simple_chat_stream_realtime_f( undef, 'Limit' )->failure;
  like( $failure, qr/429.*Rate limit reached/s, 'an error reaction fails the stream with its status' );
  my $strict = Langertha::Engine::Virtual->new( rules => [ 'Hello' => 'Hi' ], langfuse_enabled => 0 );
  like( $strict->simple_chat_stream_realtime_f( undef, 'Unknown' )->failure, qr/500 No Reaction/,
    'a request no rule answers fails the stream' );
  ok( !eval { $engine->simple_chat_stream( sub {}, 'Limit' ); 1 }, 'the synchronous stream croaks' );
};

subtest 'Langertha::Virtual::Server streams server-sent events, the usage last' => sub {
  plan skip_all => 'fork-based server test not supported on Windows' if $^O eq 'MSWin32';
  plan skip_all => 'Requires IO::Async and Net::Async::HTTP'
    unless eval { require IO::Async::Loop; require Net::Async::HTTP; 1 };
  require HTTP::Request;
  require Langertha::Engine::OpenAI;
  require Langertha::Virtual::Server;
  my $json   = JSON::MaybeXS->new( utf8 => 1, canonical => 1 );
  my $loop   = IO::Async::Loop->new;
  my $http   = Net::Async::HTTP->new( pipeline => 0 );
  $loop->add($http);
  my $engine = engine( stream_chunk_size => 5 );
  my $server = Langertha::Virtual::Server->new( engine => $engine, loop => $loop )->start;

  my $post = sub {
    my (%body) = @_;
    my $request = HTTP::Request->new( POST => $server->url.'/chat/completions',
      [ 'Content-Type' => 'application/json' ], $json->encode( { model => 'virtual', stream => JSON::MaybeXS::true, %body } ) );
    my $response = $http->do_request( request => $request )->get;
    my @events = $response->content =~ /^data: (.*)$/mg;
    return ( $response, \@events );
  };

  my ( $response, $events ) = $post->( messages => [ { role => 'user', content => 'Hello' } ],
    stream_options => { include_usage => JSON::MaybeXS::true } );
  like( $response->content_type, qr{\Atext/event-stream}, 'an event stream' );
  is( $events->[-1], '[DONE]', 'it ends with [DONE]' );
  my $usage_event = $json->decode( $events->[-2] );
  is_deeply( $usage_event->{choices}, [], 'the last event before [DONE] has no choice' );
  is_deeply( $usage_event->{usage}, { prompt_tokens => 4, completion_tokens => 6, total_tokens => 10 },
    '... and carries the usage' );
  is( $json->decode( $events->[-3] )->{choices}[0]{finish_reason}, 'stop', 'the finish_reason comes before it' );
  my @texts = map { $_->{choices}[0]{delta}{content} // () } map { $json->decode($_) } @{$events}[ 0 .. $#$events - 1 ];
  is_deeply( \@texts, [ 'Hi th', 'ere, ', 'how a', 're yo', 'u?' ], 'the text in pieces of the engine\'s stream_chunk_size' );

  my ( undef, $plain ) = $post->( messages => [ { role => 'user', content => 'Hello' } ] );
  ok( !( grep { /"usage"/ } @$plain ), 'without include_usage no event carries usage' );

  my $client = Langertha::Engine::OpenAI->new( url => $server->url, api_key => 'unused', langfuse_enabled => 0 );
  my @pieces;
  my ( $content, $chunks ) = $client->chat_stream_realtime_f(
    messages       => [ { role => 'user', content => 'Hello' } ],
    stream_options => { include_usage => 1 },
    chunk_callback => sub { push @pieces, $_[0]->content },
  )->get;
  is( $content, 'Hi there, how are you?', 'the OpenAI engine reads the stream' );
  is( scalar( grep { length } @pieces ), 5, '... in its pieces' );
  is( $client->aggregate_usage($chunks)->{total_tokens}, 10, '... and finds the usage' );

  my ( undef, $tooled ) = $client->chat_stream_realtime_f(
    messages => [ { role => 'user', content => 'Two' } ] )->get;
  is_deeply( [ map { [ $_->name, $_->arguments ] } @{ $client->aggregate_tool_calls($tooled) } ],
    [ [ add => { a => 1, b => 1 } ], [ mul => { a => 20, b => 30 } ] ],
    'tool calls assembled from the fragments over HTTP' );
  $server->stop;
};

done_testing;
