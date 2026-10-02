#!/usr/bin/env perl
# ABSTRACT: Live integration test for Hetzner Inference engine

use strict;
use warnings;

use Test2::Bundle::More;

BEGIN {
  unless ($ENV{TEST_LANGERTHA_HETZNER_API_KEY}) {
    plan skip_all => 'live skipped: set TEST_LANGERTHA_HETZNER_API_KEY to run';
  }
}

use lib 't/lib';
use Langertha::Engine::Hetzner;
# `async` is a compile-time keyword installed by Future::AsyncAwait's import.
# A runtime `require` (below) cannot register it, so it must be loaded via
# `use` at the top to make `async sub` in the tool-calling block parse.
use Future::AsyncAwait;

my $hetzner = Langertha::Engine::Hetzner->new(
  api_key => $ENV{TEST_LANGERTHA_HETZNER_API_KEY},
);

# --- list_models (static, no HTTP) ---

my $ids = $hetzner->list_models;
is(ref($ids), 'ARRAY', 'list_models returns ArrayRef (static, no HTTP)');
ok(scalar(@$ids) >= 1, 'static model list has at least one entry');
diag "Hetzner static models: @$ids";

# --- drift check: hardcoded catalog vs live /api/v1/models (karr #40) ---
# Mirrors the pattern in t/83_live_minimax.t: hit /api/v1/models with the auth
# header, collect ids, compare against _build_static_models, and diag any
# diff. Skip cleanly on missing API key, fetch failure, or unexpected shape.
# Hetzner legitimately may add models; the test passes either way and only
# WARNs (via diag) when a hardcoded model disappears from the live list.

SKIP: {
  skip 'drift check requires TEST_LANGERTHA_HETZNER_API_KEY', 2
    unless $ENV{TEST_LANGERTHA_HETZNER_API_KEY};

  require HTTP::Request;
  require LWP::UserAgent;

  my $ua  = LWP::UserAgent->new(timeout => 30);
  my $req = HTTP::Request->new(GET => 'https://inference.hetzner.com/api/v1/models');
  $req->header('Authorization' => 'Bearer '.$ENV{TEST_LANGERTHA_HETZNER_API_KEY});

  my $resp = eval { $ua->request($req) };
  if (!$resp || !$resp->is_success) {
    diag "drift check: /api/v1/models fetch failed (".
      ($resp ? $resp->status_line : 'connection error: '.$@).
      '), skipping';
    pass 'drift check: live fetch skipped (Hetzner unreachable)';
    pass 'drift check: hardcoded vs live catalog skipped';
  } else {
    my $data = eval { $hetzner->json->decode($resp->decoded_content) };
    my $models_aref = ref $data eq 'HASH' ? $data->{data}
                  : ref $data eq 'ARRAY' ? $data
                  : undef;
    if (!$models_aref) {
      diag "drift check: unexpected /api/v1/models response shape, skipping";
      pass 'drift check: live fetch skipped (unexpected response shape)';
      pass 'drift check: hardcoded vs live catalog skipped';
    } else {
      my @live = sort map { $_->{id} } @$models_aref;
      my @hard = sort map { $_->{id} } @{$hetzner->_build_static_models};
      my %live = map { $_ => 1 } @live;
      my %hard = map { $_ => 1 } @hard;
      my @missing_from_live = grep { !$live{$_} } @hard;
      my @added_in_live     = grep { !$hard{$_} } @live;

      diag "Hetzner /api/v1/models returned ".scalar(@live)." model(s): @live";
      diag "Hardcoded catalog has ".scalar(@hard)." model(s): @hard";
      diag "added in live (not in hardcoded): @added_in_live"
        if @added_in_live;
      diag "WARNING: hardcoded models missing from live: @missing_from_live"
        if @missing_from_live;

      ok(scalar(@live) > 0, 'live /api/v1/models returned at least one model');
      pass 'hardcoded vs live catalog drift check complete (see diag)';
    }
  }
}

# --- simple_chat against the default model (Qwen/Qwen3.6-35B-A3B-FP8) ---

my $chat_model = $ENV{TEST_LANGERTHA_HETZNER_MODEL} || 'Qwen/Qwen3.6-35B-A3B-FP8';
my $chat_hetzner = Langertha::Engine::Hetzner->new(
  api_key => $ENV{TEST_LANGERTHA_HETZNER_API_KEY},
  model   => $chat_model,
);

my $response = eval { $chat_hetzner->simple_chat('Say exactly: Hello Langertha') };
if ($@) {
  if ($@ =~ /429/) {
    diag "Hetzner chat: rate limited (429), skipping";
    pass "skipped due to rate limit";
  } else {
    fail "simple_chat failed: $@";
  }
} else {
  ok(defined $response, 'simple_chat returns a response');
  ok(length($response) > 0, 'simple_chat response is non-empty');
  diag "Hetzner chat response: $response";
}

# --- image understanding (Qwen3.6-35B-A3B-FP8 supports image_url inputs) ---

SKIP: {
  skip 'image understanding: set TEST_LANGERTHA_HETZNER_IMAGE_URL to a public image to run', 1
    unless $ENV{TEST_LANGERTHA_HETZNER_IMAGE_URL};

  require Langertha::Content::Image;
  my $img = Langertha::Content::Image->from_url($ENV{TEST_LANGERTHA_HETZNER_IMAGE_URL});
  my $resp = eval {
    $chat_hetzner->simple_chat({
      role    => 'user',
      content => [ 'Describe this image in one short sentence.', $img ],
    });
  };
  if ($@) {
    if ($@ =~ /429/) {
      diag "Hetzner image: rate limited (429), skipping";
      pass "skipped due to rate limit";
    } else {
      fail "image understanding failed: $@";
    }
  } else {
    ok(defined $resp && length($resp) > 0, 'image understanding returns a non-empty response');
    diag "Hetzner image response: $resp";
  }
}

# --- tool calling (advertised but docs do not explicitly confirm; verify live) ---

SKIP: {
  skip 'tool calling: set TEST_LANGERTHA_HETZNER_TEST_TOOLS=1 to exercise native tools', 1
    unless $ENV{TEST_LANGERTHA_HETZNER_TEST_TOOLS};

  require Test::MockMCP;

  my $mcp = Test::MockMCP->new(
    tools => [
      {
        name        => 'echo',
        description => 'Echo back the input text',
        input_schema => {
          type       => 'object',
          properties => { message => { type => 'string' } },
          required   => ['message'],
        },
        code => sub {
          my ($self, $args) = @_;
          return $self->text_result($args->{message} // '');
        },
      },
    ],
  );

  async sub test_tools {
    await $mcp->initialize;

    my $engine = Langertha::Engine::Hetzner->new(
      api_key     => $ENV{TEST_LANGERTHA_HETZNER_API_KEY},
      model       => $chat_model,
      mcp_servers => [$mcp],
    );

    my $r = eval {
      await $engine->chat_with_tools_f('Use the echo tool to say "ping".');
    };
    if ($@) {
      if ($@ =~ /429/) {
        diag "Hetzner tools: rate limited (429), skipping";
        pass "skipped due to rate limit";
      } else {
        fail "chat_with_tools_f failed: $@";
      }
    } else {
      ok(defined $r && length($r) > 0, 'chat_with_tools_f returned a non-empty response');
      diag "Hetzner tools response: $r";
    }
  }

  test_tools()->get;
}

done_testing;
