#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP qw(decode_json encode_json);
use Test::More;
use HTTP::Tiny;
use LLM::API;
use LLM::API::Bedrock;

my $messages = [
  { role => 'user', content => [ { type => 'text', text => 'What is JSON?' } ] },
  { role => 'assistant', content => [ { type => 'text', text => 'A data format.' } ] },
  { role => 'user', content => [ { type => 'text', text => 'Who created it?' } ] },
];

{
  package Local::ConversationHTTP;
  our $LAST_REQUEST;
  sub post {
    my ( $self, $url, $request ) = @_;
    $LAST_REQUEST = $request;
    return {
      success => 1, status => 200, code => 200,
      content => JSON::PP::encode_json({
        type => 'message', role => 'assistant', stop_reason => 'end_turn',
        content => [ { type => 'text', text => 'Douglas Crockford.' } ],
        usage => { input_tokens => 28, output_tokens => 6 },
      }),
    };
  }
}
{
  package Local::ConversationBedrock;
  our $LAST_REQUEST;
  sub Converse {
    my ( $self, $request ) = @_;
    $LAST_REQUEST = $request;
    return {
      output => { message => { content => [ { text => 'Douglas Crockford.' } ] } },
      stopReason => 'end_turn',
      usage => { inputTokens => 28, outputTokens => 6 },
    };
  }
}

subtest 'Anthropic conversation and normalized output' => sub {
  no warnings 'redefine';
  local *HTTP::Tiny::new = sub { return bless {}, 'Local::ConversationHTTP' };
  my $llm = LLM::API->new(api_key => 'fixture', max_tokens => 128);
  my $response = $llm->send_messages($messages);
  ok($response->is_success, 'response succeeded');
  is($response->content->text, 'Douglas Crockford.', 'response text');
  is($response->usage->input_tokens, 28, 'token usage');
  is_deeply(decode_json($Local::ConversationHTTP::LAST_REQUEST->{content})->{messages}, $messages,
    'Anthropic receives ordered conversation with roles');
};

subtest 'Bedrock conversation and normalized output' => sub {
  no warnings 'redefine';
  local *LLM::API::Bedrock::_runtime = sub { return bless {}, 'Local::ConversationBedrock' };
  my $llm = LLM::API->new(provider => 'bedrock', max_tokens => 128);
  my $response = $llm->send_messages($messages);
  ok($response->is_success, 'response succeeded');
  is($response->content->text, 'Douglas Crockford.', 'response text');
  is($response->usage->output_tokens, 6, 'token usage');
  is_deeply($Local::ConversationBedrock::LAST_REQUEST->{messages}, [
    { role => 'user', content => [ { text => 'What is JSON?' } ] },
    { role => 'assistant', content => [ { text => 'A data format.' } ] },
    { role => 'user', content => [ { text => 'Who created it?' } ] },
  ], 'Bedrock receives converted ordered conversation');
};

subtest 'input validation' => sub {
  my $llm = LLM::API->new(provider => 'bedrock');
  for my $invalid ([], 'string', [ { role => 'system', content => [ { type => 'text', text => 'hi' } ] } ],
    [ { role => 'assistant', content => [ { type => 'document', source => {} } ] } ],
    [ { role => 'assistant', content => [] } ]) {
    my $ok = eval { $llm->send_messages($invalid); 1 };
    ok(!$ok, 'invalid messages rejected');
  }
};

done_testing;
1;
