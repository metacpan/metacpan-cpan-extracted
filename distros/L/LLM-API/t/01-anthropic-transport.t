#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use JSON::PP qw(encode_json decode_json);

use HTTP::Tiny;
use LLM::API;

{
  package Local::MockHTTP;

  sub post {
    my ( $self, $url, $req ) = @_;
    push @{ $self->{calls} }, [ POST => $url, $req ];
    return $self->{post_result};
  }

  sub get {
    my ( $self, $url, $req ) = @_;
    push @{ $self->{calls} }, [ GET => $url, $req ];
    return $self->{get_result};
  }
}

my $http = bless {
  calls => [],
  post_result => {
    success => 1,
    status  => 200,
    code    => 200,
    content => encode_json({
      type => 'message', role => 'assistant', id => 'msg_fixture',
      model => 'claude-sonnet-4-6', stop_reason => 'end_turn',
      content => [ { type => 'text', text => 'Hello from fixture' } ],
      usage => { input_tokens => 12, output_tokens => 7 },
    }),
  },
  get_result => {
    success => 1,
    code    => 200,
    content => encode_json({ data => [ { id => 'claude-sonnet-4-6' } ], has_more => 0 }),
  },
}, 'Local::MockHTTP';

{
  no warnings 'redefine';
  local *HTTP::Tiny::new = sub { return $http; };

  my $llm = LLM::API->new( api_key => 'fixture-key', max_tokens => 64 );

  subtest 'existing prompt interface' => sub {
    my $response = $llm->prompt('Hello');
    ok( $response->is_success, 'successful response' );
    is( $response->content->text, 'Hello from fixture', 'text unchanged' );
    is( $response->usage->input_tokens, 12, 'input token count unchanged' );
    is( $response->usage->output_tokens, 7, 'output token count unchanged' );
    ok( !$response->was_cutoff, 'stop reason unchanged' );

    my $call = $http->{calls}->[-1];
    is( $call->[0], 'POST', 'uses POST' );
    is( $call->[1], 'https://api.anthropic.com/v1/messages', 'same endpoint' );
    my $request = decode_json( $call->[2]->{content} );
    is( $request->{model}, 'claude-sonnet-4-6', 'model unchanged' );
    is( $request->{max_tokens}, 64, 'token limit unchanged' );
    is( $request->{messages}->[0]->{content}->[0]->{text}, 'Hello', 'prompt body unchanged' );
    is( $call->[2]->{headers}->{'x-api-key'}, 'fixture-key', 'API key header unchanged' );
    is( $call->[2]->{headers}->{'anthropic-version'}, '2023-06-01', 'version header unchanged' );
  };

  subtest 'send_prompt error is returned, not thrown' => sub {
    local $http->{post_result} = { success => 0, code => 429, content => '{"error":"rate limit"}' };
    my $response = $llm->send_prompt( [ $llm->text('Hello') ] );
    ok( !$response->is_success, 'failed response' );
    is( $response->code, 429, 'error code available' );
  };

  subtest 'count input tokens' => sub {
    local $http->{post_result} = { success => 1, code => 200, content => '{"input_tokens":100}' };
    my ( $count, $cost ) = $llm->count_input_tokens( [ $llm->text('Hello') ] );
    is( $count, 100, 'token count' );
    cmp_ok( abs( $cost - 0.0003 ), '<', 0.000000001, 'same estimated input cost' );
    is( $http->{calls}->[-1]->[1], 'https://api.anthropic.com/v1/messages/count_tokens', 'same token endpoint' );
  };

  subtest 'administrative transport and model listing' => sub {
    my $models = $llm->models;
    ok( exists $models->{'claude-sonnet-4-6'}, 'models returned as keyed hash' );
    is( $http->{calls}->[-1]->[0], 'GET', 'uses GET' );
    is( $http->{calls}->[-1]->[1], 'https://api.anthropic.com/v1/models', 'models endpoint unchanged' );
  };

  subtest 'input validation' => sub {
    my $ok = eval { $llm->send_prompt('not an array'); 1; };
    ok( !$ok, 'invalid content rejected' );
    like( $@, qr/send_prompt\(array-ref\)/, 'existing error text retained' );
  };
}

done_testing;
1;
