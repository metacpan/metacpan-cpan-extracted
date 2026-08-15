use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;

use Langertha::Knarr::Request;
use Langertha::Knarr::Response;
use Langertha::Knarr::Protocol::OpenAI;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;
use Langertha::Response;
use Langertha::Usage;

my $json = JSON::MaybeXS->new( utf8 => 1 );

# Format one response through all three protocols and hand back the decoded
# bodies, so every usage shape below gets checked against the same wire
# expectations.
sub formatted {
  my ($resp) = @_;
  my %out;
  my @protos = (
    [ openai    => 'Langertha::Knarr::Protocol::OpenAI',    'gpt-test' ],
    [ anthropic => 'Langertha::Knarr::Protocol::Anthropic', 'claude-test' ],
    [ ollama    => 'Langertha::Knarr::Protocol::Ollama',    'llama-test' ],
  );
  for my $p (@protos) {
    my ($name, $class, $model) = @$p;
    my $req = Langertha::Knarr::Request->new( protocol => $name, model => $model );
    my (undef, undef, $body) = $class->new->format_chat_response($resp, $req);
    $out{$name} = $json->decode($body);
  }
  return \%out;
}

sub check_tokens {
  my ($d, $in, $out, $total) = @_;
  is $d->{openai}{usage}{prompt_tokens},        $in,    'openai prompt_tokens';
  is $d->{openai}{usage}{completion_tokens},    $out,   'openai completion_tokens';
  is $d->{openai}{usage}{total_tokens},         $total, 'openai total_tokens';
  is $d->{anthropic}{usage}{input_tokens},      $in,    'anthropic input_tokens';
  is $d->{anthropic}{usage}{output_tokens},     $out,   'anthropic output_tokens';
  is $d->{ollama}{prompt_eval_count},           $in,    'ollama prompt_eval_count';
  is $d->{ollama}{eval_count},                  $out,   'ollama eval_count';
}

# The shape every real engine produces: Langertha::Response declares usage as
# Maybe[HashRef] and Role::OpenAICompatible writes the provider's raw JSON
# hash straight through. Before the coercion in Knarr::Response this died in
# the constructor, so no routed response with token counts ever survived.
subtest 'Langertha::Response with raw usage hashref (the engine shape)' => sub {
  my $lr = Langertha::Response->new(
    content => 'hi',
    model   => 'gpt-test',
    usage   => { prompt_tokens => 42, completion_tokens => 17, total_tokens => 59 },
  );
  my $resp = Langertha::Knarr::Response->coerce($lr);
  isa_ok $resp->usage, ['Langertha::Usage'], 'raw hashref upgraded to value object';
  check_tokens( formatted($resp), 42, 17, 59 );
};

subtest 'engine shape handed to the formatters unwrapped' => sub {
  my $lr = Langertha::Response->new(
    content => 'hi',
    model   => 'gpt-test',
    usage   => { prompt_tokens => 8, completion_tokens => 4 },
  );
  # The protocol modules coerce internally; a handler that returns the
  # Langertha response as-is must reach the wire with the same numbers.
  check_tokens( formatted($lr), 8, 4, 12 );
};

subtest 'anthropic-spelled usage hashref' => sub {
  my $lr = Langertha::Response->new(
    content => 'hi',
    usage   => { input_tokens => 5, output_tokens => 6 },
  );
  check_tokens( formatted( Langertha::Knarr::Response->coerce($lr) ), 5, 6, 11 );
};

subtest 'ollama-spelled usage hashref' => sub {
  my $lr = Langertha::Response->new(
    content => 'hi',
    usage   => { prompt_eval_count => 3, eval_count => 9 },
  );
  check_tokens( formatted( Langertha::Knarr::Response->coerce($lr) ), 3, 9, 12 );
};

# The legacy handler shape coerce() also accepts — same hashref usage, same
# type constraint, same crash before the fix.
subtest 'legacy { content => ..., usage => {...} } hashref' => sub {
  my $resp = Langertha::Knarr::Response->coerce({
    content => 'hi',
    model   => 'gpt-test',
    usage   => { prompt_tokens => 11, completion_tokens => 2 },
  });
  isa_ok $resp->usage, ['Langertha::Usage'], 'raw hashref upgraded to value object';
  check_tokens( formatted($resp), 11, 2, 13 );
};

subtest 'hand-built Langertha::Usage object passes through untouched' => sub {
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
  is $resp->usage, exact_ref($usage), 'same instance, not re-built';
  check_tokens( formatted($resp), 42, 17, 59 );
};

subtest 'usage survives clone_with' => sub {
  my $resp = Langertha::Knarr::Response->coerce(
    Langertha::Response->new( content => 'hi', usage => { prompt_tokens => 1, completion_tokens => 2 } )
  )->clone_with( model => 'override' );
  is $resp->model, 'override';
  check_tokens( formatted($resp), 1, 2, 3 );
};

subtest 'usage absent → fallback zeros (regression: clients expect the field)' => sub {
  my $proto = Langertha::Knarr::Protocol::OpenAI->new;
  my $r = Langertha::Knarr::Response->new( content => 'no usage' );
  is $r->usage, undef, 'no usage object invented';
  my $req = Langertha::Knarr::Request->new( protocol => 'openai' );
  my (undef, undef, $body) = $proto->format_chat_response($r, $req);
  my $d = $json->decode($body);
  is $d->{usage}{prompt_tokens}, 0;
};

done_testing;
