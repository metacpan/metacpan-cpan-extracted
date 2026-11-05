#!/usr/bin/env perl

use strict;
use warnings;

use JSON::PP qw(encode_json);
use Test::More;

use LLM::API;
use LLM::API::Response;

subtest 'default provider and explicit Anthropic' => sub {
  my $default = LLM::API->new( api_key => 'fixture' );
  my $explicit = LLM::API->new( provider => 'anthropic', api_key => 'fixture' );
  is( $default->get_provider, 'anthropic', 'default is Anthropic' );
  is( $explicit->get_provider, 'anthropic', 'explicit Anthropic' );
  is( $default->text('abc')->{text}, 'abc', 'existing text block contract' );
  is_deeply( $default->text('abc'), { type => 'text', text => 'abc' }, 'canonical text input' );
};

subtest 'unsupported provider is rejected' => sub {
  my $ok = eval { LLM::API->new( provider => 'unsupported' ); 1; };
  ok( !$ok, 'unsupported provider rejected before credential validation' );
  like( $@, qr/unsupported LLM provider: unsupported/, 'specific provider error' );
};

subtest 'provider neutral success response' => sub {
  my $bedrock = { output => { message => { content => [ { text => 'Hello' } ] } } };
  my $rsp = LLM::API::Response->from_result(
    result => {
      type => 'message', role => 'assistant', model => 'demo',
      stop_reason => 'end_turn',
      content => [ { type => 'text', text => 'Hello' } ],
      usage => { input_tokens => 5, output_tokens => 3 },
    },
    provider_response => $bedrock,
  );
  ok( $rsp->is_success, 'success' );
  is( $rsp->code, 200, 'success code' );
  is( $rsp->content->text, 'Hello', 'normalized text' );
  is( $rsp->usage->input_tokens, 5, 'normalized input tokens' );
  is( $rsp->usage->output_tokens, 3, 'normalized output tokens' );
  is( $rsp->model, 'demo', 'normalized model' );
  ok( !$rsp->was_cutoff, 'not cutoff' );
  is( $rsp->provider_response, $bedrock, 'original payload accessible' );
};

subtest 'cutoff and empty content' => sub {
  my $rsp = LLM::API::Response->from_result(
    result => { stop_reason => 'max_tokens', usage => { input_tokens => 1, output_tokens => 2 } },
  );
  ok( $rsp->was_cutoff, 'cutoff reported' );
  is( $rsp->content->text, q{}, 'missing content is empty' );
  my $ok = eval { LLM::API::Response->from_result( result => [] ); 1; };
  ok( !$ok, 'invalid result rejected' );
};

subtest 'provider neutral failure response' => sub {
  my $original = { message => 'Access denied' };
  my $rsp = LLM::API::Response->from_error(
    code => 403, message => 'Access denied', provider_response => $original,
  );
  ok( !$rsp->is_success, 'failure' );
  is( $rsp->code, 403, 'error status' );
  is( $rsp->error, '403: Access denied', 'readable error' );
  is( $rsp->provider_response, $original, 'original provider error' );
};

subtest 'Anthropic HTTP response remains unchanged' => sub {
  my $raw = {
    success => 1, status => 200, code => 200,
    content => encode_json({
      type => 'message', stop_reason => 'end_turn',
      content => [ { type => 'text', text => 'Legacy' } ],
      usage => { input_tokens => 12, output_tokens => 8 },
    }),
  };
  my $rsp = LLM::API::Response->new($raw);
  is( $rsp->raw_response, $raw, 'original HTTP response unchanged' );
  is( $rsp->content->text, 'Legacy', 'legacy content still decoded' );
  is( $rsp->usage->input_tokens, 12, 'legacy usage still decoded' );
};

done_testing;
1;
