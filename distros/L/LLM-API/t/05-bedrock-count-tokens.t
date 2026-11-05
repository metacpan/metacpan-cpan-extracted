#!/usr/bin/env perl

use strict;
use warnings;

use LLM::API;
use LLM::API::Bedrock;
use Test::More;

{
  package Local::BedrockCounter;

  our $RESULT;
  our $ERROR;
  our $REQUEST;

  sub CountTokens {
    my ( $self, $args ) = @_;
    $REQUEST = $args;
    die $ERROR if defined $ERROR;
    return $RESULT;
  }
}

{
  no warnings 'redefine';
  local *LLM::API::Bedrock::_runtime = sub { return bless {}, q{Local::BedrockCounter} };

  my $llm = LLM::API->new( provider => q{bedrock}, model => q{amazon.nova-micro-v1:0} );

  subtest 'count tokens using Converse request' => sub {
    local $Local::BedrockCounter::RESULT = { inputTokens => 120 };
    my ( $tokens, $cost ) = $llm->count_input_tokens( [ $llm->text(q{Explain JSON}) ] );

    is( $tokens, 120, q{input token count} );
    cmp_ok( abs( $cost - 0.0000042 ), q{<}, 0.0000000001, q{estimated input cost} );
    is_deeply(
      $Local::BedrockCounter::REQUEST,
      {
        modelId => q{amazon.nova-micro-v1:0},
        input   => {
          converse => {
            messages => [ { role => q{user}, content => [ { text => q{Explain JSON} } ] } ],
          },
        },
      },
      q{CountTokens receives Converse input},
    );
  };

  subtest 'zero token response is valid' => sub {
    local $Local::BedrockCounter::RESULT = { inputTokens => 0 };
    my ( $tokens, $cost ) = $llm->count_input_tokens( [ $llm->text(q{}) ] );
    is( $tokens, 0, q{zero tokens} );
    is( $cost, 0, q{zero cost} );
  };

  subtest 'invalid input is rejected before the runtime call' => sub {
    for my $content (q{hello}, [ { type => q{document}, source => {} } ]) {
      my $ok = eval { $llm->count_input_tokens($content); 1; };
      ok( !$ok, q{invalid argument rejected} );
    }
  };

  subtest 'invalid response is rejected' => sub {
    for my $result (undef, {}, { inputTokens => q{n/a} }) {
      local $Local::BedrockCounter::RESULT = $result;
      my $ok = eval { $llm->count_input_tokens( [ $llm->text(q{hello}) ] ); 1; };
      ok( !$ok, q{invalid response rejected} );
      like( $@, qr/invalid Bedrock CountTokens response/, q{meaningful error} );
    }
  };

  subtest 'service errors propagate' => sub {
    local $Local::BedrockCounter::ERROR = q{AccessDeniedException: CountTokens unsupported};
    my $ok = eval { $llm->count_input_tokens( [ $llm->text(q{hello}) ] ); 1; };
    ok( !$ok, q{Bedrock error returned to caller} );
    like( $@, qr/AccessDeniedException/, q{original error retained} );
  };

  subtest 'unpriced models do not silently return zero cost' => sub {
    my $other = LLM::API->new( provider => q{bedrock}, model => q{unpriced-model} );
    local $Local::BedrockCounter::RESULT = { inputTokens => 17 };
    my $ok = eval { $other->count_input_tokens( [ $other->text(q{hello}) ] ); 1; };
    ok( !$ok, q{unsupported price rejected} );
    like( $@, qr/no pricing/, q{missing price reported} );
  };
}

done_testing;
1;
