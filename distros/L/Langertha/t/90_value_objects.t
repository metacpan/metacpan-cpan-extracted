use strict;
use warnings;
use Test2::V0;

use Langertha::Usage;
use Langertha::Cost;
use Langertha::Pricing;
use Langertha::UsageRecord;

# --- Usage ---
{
  my $u = Langertha::Usage->new( input_tokens => 100, output_tokens => 50 );
  is( $u->total_tokens, 150, 'lazy total_tokens' );
  is( $u->to_openai_format->{prompt_tokens}, 100, 'openai mapping' );
  is( $u->to_anthropic_format->{output_tokens}, 50, 'anthropic mapping' );
  is( $u->to_ollama_format->{prompt_eval_count}, 100, 'ollama mapping' );
}

# from_hash tolerates many shapes
{
  my $u = Langertha::Usage->from_hash({ prompt_tokens => 30, completion_tokens => 70 });
  is( $u->input_tokens, 30, 'openai shape input' );
  is( $u->output_tokens, 70, 'openai shape output' );

  my $u2 = Langertha::Usage->from_hash({ prompt_eval_count => 11, eval_count => 22 });
  is( $u2->input_tokens, 11, 'ollama shape input' );

  my $u3 = Langertha::Usage->from_hash({});
  is( $u3->total_tokens, 0, 'empty hash' );

  my $u4 = Langertha::Usage->from_hash(undef);
  is( $u4->total_tokens, 0, 'undef hash' );
}

# from_response with bare hashref
{
  my $u = Langertha::Usage->from_response({ usage => { prompt_tokens => 5, completion_tokens => 7 } });
  is( $u->total_tokens, 12, 'from_response hash' );
}

# merge is immutable
{
  my $a = Langertha::Usage->new( input_tokens => 10, output_tokens => 20 );
  my $b = Langertha::Usage->new( input_tokens => 100, output_tokens => 200 );
  my $c = $a->merge($b);
  is( $a->input_tokens, 10, 'a unchanged' );
  is( $b->input_tokens, 100, 'b unchanged' );
  is( $c->input_tokens, 110, 'merged input' );
  is( $c->output_tokens, 220, 'merged output' );
  is( $c->total_tokens, 330, 'merged total' );
}

# --- Pricing + Cost ---
{
  my $p = Langertha::Pricing->new(
    rules => {
      'gpt-4o-mini' => { input_per_million => 0.15, output_per_million => 0.60 },
    },
  );
  my $u = Langertha::Usage->new( input_tokens => 1_000_000, output_tokens => 500_000 );
  my $c = $p->cost_for( $u, 'gpt-4o-mini' );
  isa_ok( $c, ['Langertha::Cost'] );
  is( $c->input_usd  + 0, 0.15, 'input cost' );
  is( $c->output_usd + 0, 0.30, 'output cost' );
  is( $c->total_usd  + 0, 0.45, 'total cost' );
  is( $c->currency, 'USD', 'currency' );
}

# Unknown model with default_rule
{
  my $p = Langertha::Pricing->new(
    default_rule => { input_per_million => 1, output_per_million => 2 },
  );
  my $u = Langertha::Usage->new( input_tokens => 1_000_000, output_tokens => 1_000_000 );
  my $c = $p->cost_for( $u, 'unknown' );
  is( $c->total_usd + 0, 3, 'fallback rule applied' );
}

# Unknown model without default_rule → zero cost
{
  my $p = Langertha::Pricing->new;
  my $c = $p->cost_for( Langertha::Usage->new( input_tokens => 1_000_000 ), 'mystery' );
  is( $c->total_usd + 0, 0, 'no rule = zero' );
}

# --- UsageRecord ---
{
  my $u = Langertha::Usage->new( input_tokens => 100, output_tokens => 50 );
  my $c = Langertha::Cost->new( input_usd => 0.001, output_usd => 0.002 );
  my $rec = Langertha::UsageRecord->new(
    usage      => $u,
    cost       => $c,
    model      => 'gpt-4o-mini',
    provider   => 'openai',
    api_key_id => 'tenant-1',
    tool_calls => 2,
    tool_names => [ 'list_files', 'read_file' ],
  );
  my $h = $rec->to_hash;
  is( $h->{model}, 'gpt-4o-mini', 'model' );
  is( $h->{input_tokens}, 100, 'tokens flattened' );
  is( $h->{total_cost_usd} + 0, 0.003, 'cost flattened' );
  is( $h->{tool_calls}, 2, 'tool calls' );
  is( $h->{tool_names}->[1], 'read_file', 'tool names' );
  is( $h->{api_key_id}, 'tenant-1', 'api_key_id' );
}

# --- Backwards-compat facade ---
{
  local $SIG{__WARN__} = sub { return if $_[0] =~ /backwards-compatibility facade/; warn @_ };
  require Langertha::Metrics;
}
{
  my $u = Langertha::Metrics->normalize_usage({ prompt_tokens => 7, completion_tokens => 3 });
  is( $u->{input_tokens}, 7, 'facade normalize_usage' );
  is( $u->{total_tokens}, 10, 'facade total' );

  my $rec = Langertha::Metrics->build_record(
    usage   => { prompt_tokens => 1000, completion_tokens => 500 },
    pricing => { input_per_million => 0.10, output_per_million => 0.30 },
    model   => 'test',
    provider => 'openai',
  );
  is( $rec->{input_tokens}, 1000, 'facade record input' );
  ok( $rec->{total_cost_usd} > 0, 'facade record has cost' );
  is( $rec->{model}, 'test', 'facade record model' );
}

done_testing;
