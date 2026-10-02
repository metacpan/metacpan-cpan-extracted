#!/usr/bin/env perl
# ABSTRACT: LM Studio native /api/v1/chat input: text parts, trailing user turn(s), stateful passthrough
use strict;
use warnings;
use Test2::Bundle::More;
use lib 't/lib';

use JSON::MaybeXS;
use Test::MockAsyncHTTP;
use Langertha::Content::Image;
use Langertha::Engine::LMStudio;

# karr k268: the native input array is the content parts of ONE user turn,
# spelled { type => 'text', content } / { type => 'image', data_url }
# (lmstudio-ai/docs 9b8bc20 fixed the doc table that said "message"). The wire
# takes no roles and no assistant messages, so flattening a history put the
# model's own earlier replies in as user text. A history with assistant turns
# is cut to what follows the last one, with a warning; multi-turn on this wire
# is store + previous_response_id, which must reach the body untouched.

my $json = JSON::MaybeXS->new( canonical => 1, utf8 => 1 );
sub body_of { $json->decode( $_[0]->content ) }

sub engine { Langertha::Engine::LMStudio->new( url => 'http://h:1234', model => 'm', @_ ) }

sub warnings_of (&) {
  my ( $code ) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };
  my $result = $code->();
  return ( $result, \@warnings );
}

my $TRIM_WARNING = qr/\ALangertha::Engine::LMStudio: LM Studio native has no multi-turn history; sending only the trailing user turn\(s\); use ->openai\/->anthropic or previous_response_id at \Q${\ __FILE__ }\E line \d+/;

# --- One user turn: a string stays a string input ---
{
  my ( $req, $w ) = warnings_of { engine()->chat('hello') };
  is $json->encode( body_of($req) ),
    '{"input":"hello","max_output_tokens":1024,"model":"m"}',
    'single user message: plain string input';
  is scalar @$w, 0, '... and no warning';
}

# --- Several user turns, no assistant: text parts, in order, no warning ---
{
  my ( $req, $w ) = warnings_of { engine( system_prompt => 'sys' )->chat(
    'first',
    { role => 'user', content => [ { type => 'text', text => 'second' } ] },
  ) };
  is $json->encode( body_of($req) ),
    '{"input":[{"content":"first","type":"text"},{"content":"second","type":"text"}],"max_output_tokens":1024,"model":"m","system_prompt":"sys"}',
    'user turns become type:text parts (not type:message)';
  is scalar @$w, 0, '... and no warning without assistant turns';
}

# --- History with assistant turns: only what follows the last one is sent ---
{
  my @history = (
    { role => 'system',    content => 'sys' },
    { role => 'user',      content => 'old question' },
    { role => 'assistant', content => 'old answer' },
    { role => 'user',      content => 'second question' },
    { role => 'assistant', content => 'second answer' },
    { role => 'user',      content => 'now this' },
    { role => 'user',      content => 'and that' },
  );
  my ( $req, $w ) = warnings_of { engine()->chat(@history) };
  is $json->encode( body_of($req) ),
    '{"input":[{"content":"now this","type":"text"},{"content":"and that","type":"text"}],"max_output_tokens":1024,"model":"m","system_prompt":"sys"}',
    'only the user turns after the last assistant turn; system prompt kept';
  is scalar @$w, 1, 'exactly one warning per request';
  like $w->[0], $TRIM_WARNING, '... naming the fallback, reported at the caller';

  my ( $one, $w1 ) = warnings_of { engine()->chat( @history[ 1 .. 5 ] ) };
  is body_of($one)->{input}, 'now this', 'a single trailing turn collapses to a string';
  is scalar @$w1, 1, '... still warned';

  my ( $again, $w2 ) = warnings_of { engine()->chat(@history) };
  is scalar @$w2, 1, 'the warning repeats on the next request (per request, not once per process)';

  my ( $stream, $ws ) = warnings_of { engine()->chat_stream(@history) };
  is $json->encode( body_of($stream) ),
    '{"input":[{"content":"now this","type":"text"},{"content":"and that","type":"text"}],"max_output_tokens":1024,"model":"m","stream":true,"system_prompt":"sys"}',
    'streaming request trims the same way';
  is scalar @$ws, 1, '... with one warning';
}

# --- Images after the last assistant turn are unchanged from k267 ---
{
  my $img = Langertha::Content::Image->from_base64( 'Zm9v', media_type => 'image/png' );
  my ( $req, $w ) = warnings_of { engine()->chat(
    { role => 'user',      content => 'earlier' },
    { role => 'assistant', content => 'reply' },
    { role => 'user',      content => [ 'look', $img ] },
  ) };
  is_deeply body_of($req)->{input}, [
    { type => 'text',  content => 'look' },
    { type => 'image', data_url => 'data:image/png;base64,Zm9v' },
  ], 'image part keeps { type => image, data_url }, text part is type:text';
  is scalar @$w, 1, '... history trimmed with a warning';
}

# --- previous_response_id and store pass through to the body ---
{
  my $req = engine()->chat_request( [ { role => 'user', content => 'next' } ],
    previous_response_id => 'resp_abc', store => JSON::MaybeXS::false );
  is $json->encode( body_of($req) ),
    '{"input":"next","max_output_tokens":1024,"model":"m","previous_response_id":"resp_abc","store":false}',
    'chat_request: previous_response_id and store reach the body';

  my $stream = engine()->chat_stream_request( [ { role => 'user', content => 'next' } ],
    previous_response_id => 'resp_abc', store => JSON::MaybeXS::true );
  my $body = body_of($stream);
  is $body->{previous_response_id}, 'resp_abc', 'chat_stream_request: previous_response_id passed';
  ok $body->{store}, '... store passed';

  ok !exists body_of( engine()->chat('x') )->{store}, 'store is not sent by default (server default applies)';

  my $mock = Test::MockAsyncHTTP->new( responses => [
    Test::MockAsyncHTTP->mock_json_response({
      model_instance_id => 'm',
      output => [ { type => 'message', content => 'Ada.' } ],
      response_id => 'resp_def',
      stats => { input_tokens => 3, total_output_tokens => 2 },
    }),
  ] );
  my $e = Langertha::Engine::LMStudio->new( url => 'http://h:1234', model => 'm', _async_http => $mock );
  my $resp = $e->chat_f( messages => [ 'What is my name?' ], previous_response_id => 'resp_abc' )->get;
  is $json->encode( body_of( ( $mock->requests )[0] ) ),
    '{"input":"What is my name?","max_output_tokens":1024,"model":"m","previous_response_id":"resp_abc"}',
    'chat_f: previous_response_id passes through to the wire';
  is $resp->id, 'resp_def', '... and the new response_id is Response->id for the next turn';
}

# --- Streaming finish_reason still derives from result.response_id ---
{
  my $e = engine();
  my $end = $e->parse_stream_chunk( { type => 'chat.end', result => {
    response_id => 'resp_x', model_instance_id => 'm',
    stats => { input_tokens => 1, total_output_tokens => 1 } } } );
  is $end->finish_reason, 'end', 'chat.end with response_id: finish_reason end';
  ok $end->is_final, '... final chunk';

  my $unstored = $e->parse_stream_chunk( { type => 'chat.end', result => { model_instance_id => 'm' } } );
  ok !defined $unstored->finish_reason, 'chat.end without response_id (store:false): no finish_reason';
}

done_testing;
