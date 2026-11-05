#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use LLM::API;
use LLM::API::Bedrock;

{
  package Local::MockBedrock;
  our @CALLS;
  our $RESPONSE;
  our $ERROR;
  our $COUNT_RESULT;
  our $COUNT_ERROR;
  our @COUNT_CALLS;

  sub CountTokens {
    my ( $self, $args ) = @_;
    push @COUNT_CALLS, $args;
    die $COUNT_ERROR if defined $COUNT_ERROR;
    return $COUNT_RESULT;
  }

  sub Converse {
    my ( $self, $args ) = @_;
    push @CALLS, $args;
    die $ERROR if defined $ERROR;
    return $RESPONSE;
  }
}

{
  no warnings 'redefine';
  local *LLM::API::Bedrock::_runtime = sub { return bless {}, 'Local::MockBedrock' };

  subtest 'Bedrock construction without Anthropic key' => sub {
    my $llm = LLM::API->new(provider => 'bedrock', region => 'us-east-1');
    is($llm->get_provider, 'bedrock', 'provider');
    is($llm->get_model, 'amazon.nova-micro-v1:0', 'default model');
    is($llm->get_region, 'us-east-1', 'region');
  };

  my $llm = LLM::API->new(provider => 'bedrock', model => 'amazon.nova-micro-v1:0', region => 'us-east-1', max_tokens => 128);

  subtest 'text response and usage' => sub {
    local $Local::MockBedrock::RESPONSE = {
      output => { message => { content => [ { text => 'Hello ' }, { text => 'learner!' } ] } },
      stopReason => 'end_turn',
      usage => { inputTokens => 13, outputTokens => 7 },
    };
    my $rsp = $llm->prompt('Explain JSON');
    ok($rsp->is_success, 'success');
    is($rsp->content->text, 'Hello learner!', 'joined text blocks');
    is($rsp->usage->input_tokens, 13, 'input usage');
    is($rsp->usage->output_tokens, 7, 'output usage');
    ok(!$rsp->was_cutoff, 'not truncated');
    is($rsp->provider_response, $Local::MockBedrock::RESPONSE, 'raw result');
    my $req = $Local::MockBedrock::CALLS[-1];
    is($req->{modelId}, 'amazon.nova-micro-v1:0', 'model');
    is($req->{inferenceConfig}->{maxTokens}, 128, 'max tokens');
    is_deeply($req->{messages}, [ { role => 'user', content => [ { text => 'Explain JSON' } ] } ], 'Converse messages');
  };

  subtest 'cutoff response' => sub {
    local $Local::MockBedrock::RESPONSE = {
      output => { message => { content => [ { text => 'Partial' } ] } },
      stopReason => 'max_tokens', usage => { inputTokens => 10, outputTokens => 128 },
    };
    my $rsp = $llm->prompt('Long task');
    ok($rsp->was_cutoff, 'max_tokens normalized');
  };

  subtest 'errors return response objects' => sub {
    local $Local::MockBedrock::ERROR = 'AccessDenied: fixture';
    my $rsp = $llm->prompt('Hello');
    ok(!$rsp->is_success, 'failure');
    like($rsp->error, qr/AccessDenied/, 'error is readable');
  };

  subtest 'unsupported APIs' => sub {
    my $ok;
    $ok = eval { $llm->models; 1 };
    ok(!$ok, 'Anthropic model listing not called');
    $ok = eval { $llm->count_input_tokens('invalid'); 1 };
    ok(!$ok, 'invalid token count argument rejected');
  };
}

done_testing;
1;
