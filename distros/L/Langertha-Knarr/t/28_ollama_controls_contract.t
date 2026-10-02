use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Knarr::Request;
use Langertha::Engine::Ollama;

# Guards the routed-Ollama per-request generation-param contract (karr #9).
#
# Historical bug (against Langertha 0.502): Knarr passed temperature/max_tokens
# as top-level chat_f kwargs, but Engine::Ollama's chat_request built its
# 'options' hash only from engine attributes and spread the rest of %extra
# top-level -- a per-request temperature landed top-level in the Ollama body
# (where Ollama never looks), and max_tokens was never renamed to
# num_predict. Both were silently dropped.
#
# Fixed upstream in Langertha 0.503 (karr #46): chat_f now extracts canonical
# per-request "controls" and Engine::Ollama::chat_request consumes them,
# placing temperature -> options.temperature, max_tokens -> options.num_predict.
#
# This test is key-free and makes no network call: chat_request only builds
# a Langertha::Request::HTTP (isa HTTP::Request) object, it never sends it.
# Ollama's api_key_required is 0, so no credentials are needed either.

my $ollama = Langertha::Engine::Ollama->new( model => 'llama3.3', url => 'http://localhost:11434' );

subtest 'Knarr side: chat_f_args forwards temperature and max_tokens to Ollama' => sub {
  my $req = Langertha::Knarr::Request->new(
    protocol    => 'openai',
    model       => 'llama3.3',
    messages    => [ { role => 'user', content => 'hi' } ],
    temperature => 0.7,
    max_tokens  => 100,
  );

  # Proves both that Knarr passes the params through chat_f_args, and that
  # Ollama's capability gate (temperature / response_size) lets them pass --
  # a regression in either place would drop them from this list.
  my @args = $req->chat_f_args($ollama);
  my %args = @args;
  is $args{temperature}, 0.7,  'temperature present in chat_f_args';
  is $args{max_tokens},  100,  'max_tokens present in chat_f_args';
};

subtest 'Wire contract: controls land in options, not top-level' => sub {
  my $request = $ollama->chat_request(
    $ollama->chat_messages( { role => 'user', content => 'hi' } ),
    controls => { temperature => 0.7, max_tokens => 100 },
  );
  my $body = decode_json($request->content);

  is $body->{options}{temperature}, 0.7, 'temperature placed at options.temperature';
  is $body->{options}{num_predict}, 100, 'max_tokens renamed to options.num_predict';

  # This is exactly the historical bug: a top-level drop / missing rename.
  ok !exists $body->{temperature}, 'no top-level temperature key';
  ok !exists $body->{max_tokens},  'no top-level max_tokens key';
};

done_testing;
