use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;
use Langertha::Usage;

my $json = JSON::MaybeXS->new( utf8 => 1 );

my $usage = Langertha::Usage->new(
  input_tokens  => 42,
  output_tokens => 17,
  total_tokens  => 59,
);

my $resp = Langertha::Knarr::Response->new(
  content => 'hi',
  model   => 'gpt-test',
  usage   => $usage,
);

subtest 'OpenAI usage' => sub {
  my $proto = Langertha::Knarr::Protocol::OpenAI->new;
  my $req = Langertha::Knarr::Request->new( protocol => 'openai', model => 'gpt-test' );
  my (undef, undef, $body) = $proto->format_chat_response($resp, $req);
  my $d = $json->decode($body);
  is $d->{usage}{prompt_tokens},     42;
  is $d->{usage}{completion_tokens}, 17;
  is $d->{usage}{total_tokens},      59;
};

subtest 'Anthropic usage' => sub {
  my $proto = Langertha::Knarr::Protocol::Anthropic->new;
  my $req = Langertha::Knarr::Request->new( protocol => 'anthropic', model => 'claude-test' );
  my (undef, undef, $body) = $proto->format_chat_response($resp, $req);
  my $d = $json->decode($body);
  is $d->{usage}{input_tokens},  42;
  is $d->{usage}{output_tokens}, 17;
};

subtest 'usage absent → fallback zeros (regression: clients expect the field)' => sub {
  my $proto = Langertha::Knarr::Protocol::OpenAI->new;
  my $r = Langertha::Knarr::Response->new( content => 'no usage' );
  my $req = Langertha::Knarr::Request->new( protocol => 'openai' );
  my (undef, undef, $body) = $proto->format_chat_response($r, $req);
  my $d = $json->decode($body);
  is $d->{usage}{prompt_tokens}, 0;
};

done_testing;
