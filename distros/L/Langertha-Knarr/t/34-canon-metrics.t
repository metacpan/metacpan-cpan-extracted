use strict;
use warnings;
use Test::More;

use Langertha::Knarr::Metrics;

# normalize_usage from prompt/completion style
{
  my $u = Langertha::Knarr::Metrics->normalize_usage({
    prompt_tokens     => 120,
    completion_tokens => 30,
  });
  is $u->{input_tokens}, 120, 'input normalized from prompt_tokens';
  is $u->{output_tokens}, 30, 'output normalized from completion_tokens';
  is $u->{total_tokens}, 150, 'total derived when missing';
}

# normalize_usage from ollama counters
{
  my $u = Langertha::Knarr::Metrics->normalize_usage({
    prompt_eval_count => 9,
    eval_count        => 4,
    total_tokens      => 13,
  });
  is $u->{input_tokens}, 9, 'input normalized from prompt_eval_count';
  is $u->{output_tokens}, 4, 'output normalized from eval_count';
  is $u->{total_tokens}, 13, 'explicit total kept';
}

# normalize_tool_metrics accepts canonical and function-shaped calls
{
  my $t = Langertha::Knarr::Metrics->normalize_tool_metrics([
    { name => 'add' },
    { function => { name => 'search' } },
    { foo => 'bar' },
  ]);
  is $t->{tool_calls}, 2, 'tool call count';
  is_deeply $t->{tool_names}, ['add', 'search'], 'tool names extracted';
}

# estimate cost
{
  my $c = Langertha::Knarr::Metrics->estimate_cost_usd(
    usage => {
      input_tokens  => 1000,
      output_tokens => 500,
    },
    pricing => {
      input_per_million  => 1.5,
      output_per_million => 6.0,
    },
  );
  cmp_ok $c->{total_cost_usd}, '>', 0, 'total cost computed';
  is $c->{currency}, 'USD', 'currency';
}

# build record
{
  my $r = Langertha::Knarr::Metrics->build_record(
    provider => 'openai',
    engine   => 'Langertha::Engine::OpenAI',
    model    => 'gpt-4o-mini',
    route    => '/v1/chat/completions',
    duration_ms => 123.4,
    usage => {
      prompt_tokens     => 20,
      completion_tokens => 10,
    },
    tool_calls => [
      { name => 'add' },
    ],
    pricing => {
      input_per_million  => 1,
      output_per_million => 1,
    },
    pricing_version => '2026-03-10',
  );

  is $r->{total_tokens}, 30, 'record includes normalized usage';
  is $r->{tool_calls}, 1, 'record includes tool call count';
  is $r->{model}, 'gpt-4o-mini', 'record keeps model';
  ok defined $r->{total_cost_usd}, 'record includes cost';
}

done_testing;
