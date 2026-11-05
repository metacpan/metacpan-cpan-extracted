#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use LLM::API;

sub approx_rate {
  my ( $got, $expected, $description ) = @_;
  cmp_ok( abs( $got - $expected ), '<', 0.000000000001, $description );
  return;
}

subtest 'Anthropic uses its own pricing' => sub {
  my $llm = LLM::API->new( provider => q{anthropic}, api_key => q{fixture}, model => q{claude-sonnet-4-6} );
  my ( $input, $output ) = $llm->pricing;
  approx_rate( $input, 3 / 1_000_000, q{Sonnet input} );
  approx_rate( $output, 15 / 1_000_000, q{Sonnet output} );
};

subtest 'Bedrock prices the full inference profile ID' => sub {
  my $llm = LLM::API->new( provider => q{bedrock}, model => q{us.anthropic.claude-sonnet-4-6} );
  my ( $input, $output ) = $llm->pricing;
  approx_rate( $input, 3.3 / 1_000_000, q{US geographic Sonnet input} );
  approx_rate( $output, 16.5 / 1_000_000, q{US geographic Sonnet output} );
  my ($global_input) = $llm->pricing(q{global.anthropic.claude-sonnet-4-6});
  approx_rate( $global_input, 3 / 1_000_000, q{global Sonnet is separately priced} );
};

subtest 'Nova catalog entries' => sub {
  my $llm = LLM::API->new( provider => q{bedrock}, model => q{amazon.nova-micro-v1:0} );
  for my $case (
    [ q{amazon.nova-micro-v1:0}, 0.035, 0.14 ],
    [ q{amazon.nova-lite-v1:0},  0.06,  0.24 ],
    [ q{amazon.nova-pro-v1:0},   0.80,  3.20 ],
    [ q{amazon.nova-2-lite-v1:0}, 0.30, 2.50 ],
  ) {
    my ( $input, $output ) = $llm->pricing( $case->[0] );
    approx_rate( $input, $case->[1] / 1_000_000, sprintf(q{%s input}, $case->[0]) );
    approx_rate( $output, $case->[2] / 1_000_000, sprintf(q{%s output}, $case->[0]) );
  }
};

subtest 'Unknown prices and providers fail clearly' => sub {
  my $llm = LLM::API->new( provider => q{bedrock}, model => q{unknown-model} );
  my $ok = eval { $llm->pricing; 1; };
  ok( !$ok, q{unknown model is rejected only when pricing is requested} );
  like( $@, qr/no pricing for provider bedrock, model unknown-model/, q{diagnostic includes both dimensions} );

  $ok = eval { LLM::API->new( provider => q{unsupported} ); 1; };
  ok( !$ok, q{unknown provider rejected} );
  like( $@, qr/unsupported LLM provider/, q{unsupported provider diagnostic} );
};

done_testing;
1;
