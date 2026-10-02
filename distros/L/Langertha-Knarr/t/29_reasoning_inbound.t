use strict;
use warnings;
use Test2::V0;
use JSON::MaybeXS;
use HTTP::Request;

use Langertha::Knarr::Reasoning;
use Langertha::Knarr::Protocol::Anthropic;
use Langertha::Knarr::Protocol::Ollama;

# Guards the inbound reasoning mapping (karr k13): the Anthropic face's
# thinking / output_config.effort and the Ollama face's think become the
# normalized Request reasoning_effort, which chat_f_args then gates on the
# reasoning_effort capability exactly as for the OpenAI face (t/29).
#
# budget_tokens maps through Langertha::Reasoning::BudgetPolicy, which only a
# core newer than 0.503 has; those assertions skip on an older core, and the
# older-core behavior is pinned separately through a subclass that reports
# the policy absent. Key-free, no network.

my $HAS_POLICY = Langertha::Knarr::Reasoning->new->budget_available;

# A core without BudgetPolicy, on any installed core.
{
  package NoPolicyReasoning;
  use Moose;
  extends 'Langertha::Knarr::Reasoning';
  sub _build_budget_available { 0 }
  __PACKAGE__->meta->make_immutable;
}

# Records chat_f args and reports capabilities (t/25 pattern).
{
  package CaptureEngine;
  use Moose;
  has caps => ( is => 'ro', default => sub { { reasoning_effort => 1 } } );
  sub supports { $_[0]->caps->{ $_[1] } ? 1 : 0 }
  __PACKAGE__->meta->make_immutable;
}

sub anthropic {
  my ( $body, %proto ) = @_;
  my $json = encode_json({
    model      => 'claude-sonnet-4-6',
    max_tokens => 1024,
    messages   => [ { role => 'user', content => 'hi' } ],
    %$body,
  });
  return Langertha::Knarr::Protocol::Anthropic->new(%proto)
    ->parse_chat_request( HTTP::Request->new( POST => '/v1/messages' ), \$json );
}

sub ollama {
  my ( $body, %proto ) = @_;
  my $json = encode_json({
    model    => 'qwen3',
    messages => [ { role => 'user', content => 'hi' } ],
    %$body,
  });
  return Langertha::Knarr::Protocol::Ollama->new(%proto)
    ->parse_chat_request( HTTP::Request->new( POST => '/api/chat' ), \$json );
}

subtest 'Anthropic thinking without a budget' => sub {
  is anthropic({ thinking => { type => 'disabled' } })->reasoning_effort, 'none',
    'disabled maps to none';
  is anthropic({ thinking => { type => 'adaptive' } })->reasoning_effort, 'medium',
    'adaptive maps to the default level';
  is anthropic({ thinking => { type => 'enabled' } })->reasoning_effort, 'medium',
    'enabled without budget_tokens maps to the default level';
  is anthropic({})->reasoning_effort, undef, 'no thinking, no reasoning_effort';
  is anthropic({ thinking => { type => 'sideways' } })->reasoning_effort, undef,
    'an unknown thinking type maps to nothing';
  is anthropic({ thinking => 'on' })->reasoning_effort, undef,
    'a non-object thinking maps to nothing';
};

subtest 'Anthropic explicit effort wins over thinking' => sub {
  is anthropic({
    thinking      => { type => 'adaptive' },
    output_config => { effort => 'high' },
  })->reasoning_effort, 'high', 'output_config.effort wins over adaptive';
  is anthropic({
    thinking      => { type => 'enabled', budget_tokens => 2048 },
    output_config => { effort => 'max' },
  })->reasoning_effort, 'max', 'output_config.effort wins over budget_tokens';
  is anthropic({
    thinking         => { type => 'disabled' },
    reasoning_effort => 'low',
  })->reasoning_effort, 'low', 'a top-level reasoning_effort wins over thinking';
};

subtest 'Anthropic budget_tokens through BudgetPolicy' => sub {
  skip_all 'core has no Langertha::Reasoning::BudgetPolicy' unless $HAS_POLICY;
  my %cases = ( 1024 => 'low', 4000 => 'low', 8192 => 'medium', 16000 => 'medium',
    24576 => 'high', 64000 => 'high' );
  for my $budget ( sort { $a <=> $b } keys %cases ) {
    is anthropic({ thinking => { type => 'enabled', budget_tokens => $budget } })
      ->reasoning_effort, $cases{$budget}, "claude budget $budget -> $cases{$budget}";
  }
  is anthropic({ model => 'gemini-2.5-pro',
    thinking => { type => 'enabled', budget_tokens => 32768 } })->reasoning_effort,
    'high', 'a model with profile bounds maps across its range (ceiling -> high)';
  is anthropic({ model => 'gemini-2.5-pro',
    thinking => { type => 'enabled', budget_tokens => 128 } })->reasoning_effort,
    'low', '... and its floor -> low';
  is anthropic({ thinking => { type => 'enabled', budget_tokens => 'lots' } })
    ->reasoning_effort, undef, 'a non-integer budget maps to nothing';
};

subtest 'Anthropic budget_tokens on a core without BudgetPolicy' => sub {
  my $r = NoPolicyReasoning->new;
  is anthropic({ thinking => { type => 'enabled', budget_tokens => 8192 } }, reasoning => $r)
    ->reasoning_effort, undef, 'budget_tokens stays unmapped, no croak';
  is anthropic({ thinking => { type => 'disabled' } }, reasoning => $r)->reasoning_effort,
    'none', 'disabled still maps';
  is anthropic({ thinking => { type => 'adaptive' } }, reasoning => $r)->reasoning_effort,
    'medium', 'adaptive still maps to the default level';
};

subtest 'Ollama think' => sub {
  is ollama({ think => JSON::MaybeXS::true() })->reasoning_effort, 'medium',
    'think true maps to the default level';
  is ollama({ think => JSON::MaybeXS::false() })->reasoning_effort, 'none',
    'think false maps to none';
  is ollama({ think => $_ })->reasoning_effort, $_, "think '$_' is kept"
    for qw( low medium high max );
  is ollama({ think => 'turbo' })->reasoning_effort, undef, 'an unknown level string maps to nothing';
  is ollama({ think => 1 })->reasoning_effort, undef, 'a number is not a boolean';
  is ollama({})->reasoning_effort, undef, 'no think, no reasoning_effort';
  is ollama({ think => JSON::MaybeXS::true(), reasoning_effort => 'low' })->reasoning_effort,
    'low', 'an explicit reasoning_effort wins over think';
  is ollama({ think => JSON::MaybeXS::true() }, reasoning => NoPolicyReasoning->new)
    ->reasoning_effort, 'medium', 'booleans map without BudgetPolicy too';
};

subtest 'exact overrides' => sub {
  my $high = Langertha::Knarr::Reasoning->new( default_level => 'high' );
  is ollama({ think => JSON::MaybeXS::true() }, reasoning => $high)->reasoning_effort, 'high',
    'default_level overrides think true';
  is anthropic({ thinking => { type => 'adaptive' } }, reasoning => $high)->reasoning_effort,
    'high', '... and adaptive';
  is ollama({ think => JSON::MaybeXS::false() }, reasoning => $high)->reasoning_effort, 'none',
    'off stays none';

  like dies { Langertha::Knarr::Reasoning->new( default_level => 'loud' ) },
    qr/unknown default_level 'loud'/, 'an unknown default_level croaks';
  like dies { Langertha::Knarr::Reasoning->new( budget_points => { loud => 1 } ) },
    qr/unknown level 'loud' in budget_points/, 'an unknown budget_points level croaks';

  SKIP: {
    skip 'core has no Langertha::Reasoning::BudgetPolicy', 2 unless $HAS_POLICY;
    my $points = Langertha::Knarr::Reasoning->new(
      budget_points => { low => 1024, medium => 4096, high => 16384 } );
    is anthropic({ thinking => { type => 'enabled', budget_tokens => 4000 } }, reasoning => $points)
      ->reasoning_effort, 'medium', 'budget_points override the fallback anchors';
    is anthropic({ model => 'gemini-2.5-pro', thinking => { type => 'enabled', budget_tokens => 32768 } },
      reasoning => $points)->reasoning_effort, 'high',
      '... and a profile range, still clamped to its bounds';
  }
};

subtest 'derived level is capability-gated like an explicit one' => sub {
  my $req = anthropic({ thinking => { type => 'adaptive' } });
  my %on  = $req->chat_f_args( CaptureEngine->new );
  is $on{reasoning_effort}, 'medium', 'forwarded to an engine with the capability';
  my %off = $req->chat_f_args( CaptureEngine->new( caps => {} ) );
  ok !exists $off{reasoning_effort}, 'dropped for an engine without it';
};

done_testing;
