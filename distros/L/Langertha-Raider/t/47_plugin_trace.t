#!/usr/bin/env perl
# ABSTRACT: Unit tests for Langertha::Raider::Plugin::Trace

use strict;
use warnings;
use Test2::V0;
use Encode qw( decode_utf8 );
use Langertha::Raider;
use Langertha::Raider::Plugin::Trace;

# --- Helper: minimal mock engine (same shape as t/87_raider_plugins.t) ---

{
  package MockEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model => (is => 'ro', default => 'mock-model');
  has '+mcp_servers' => (default => sub { [] });

  sub format_tools { return $_[1] }
  sub response_tool_calls { return [] }
  sub extract_tool_call { return ($_[1]->{name}, $_[1]->{input}) }
  sub format_tool_results { return () }
  sub response_text_content { return 'mock response' }
  sub think_tag_filter { 0 }

  __PACKAGE__->meta->make_immutable;
}

# color defaults off unless a test asks for it, so output is plain text
# by default and comparable without stripping ANSI codes.
sub trace_plugin {
  my (%args) = @_;
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => [ '+Langertha::Raider::Plugin::Trace' => { color => 0, %args } ],
  );
  return $raider->plugin_instances->[0];
}

sub capture_stdout {
  my ($code) = @_;
  my $out = '';
  local *STDOUT;
  open STDOUT, '>', \$out or die $!;
  $code->();
  return $out;
}

subtest '_truncate collapses whitespace and truncates long values' => sub {
  my $plugin = trace_plugin(max_value_length => 10);
  is($plugin->_truncate('short'), 'short', 'short string unchanged');
  is($plugin->_truncate("a\nb   c"), 'a b c', 'whitespace runs collapsed to a single space');
  # Trace.pm's own source has no `use utf8;` (its ellipsis is a raw UTF-8
  # byte literal, which is exactly right for printing straight to a
  # terminal) — decode it here so the comparison is by character, not byte.
  is(decode_utf8($plugin->_truncate('a' x 20)), ('a' x 9).'…',
    'truncated to max_value_length - 1 plus ellipsis');
  is($plugin->_truncate(undef), '', 'undef becomes empty string');
};

subtest '_summarize_args formats sorted key=value pairs' => sub {
  my $plugin = trace_plugin();
  is($plugin->_summarize_args({ b => 2, a => 1 }), 'a=1 b=2', 'sorted by key, space-joined');
  is($plugin->_summarize_args('not a hashref'), '', 'non-hashref input yields empty string');
  like($plugin->_summarize_args({ nested => { x => 1 } }), qr/^nested=\{.*\}$/, 'nested values JSON-encoded');
};

subtest 'plugin_before_tool_call prints the call line and passes through unchanged' => sub {
  my $plugin = trace_plugin();
  my @passthrough;
  my $out = capture_stdout(sub {
    @passthrough = $plugin->plugin_before_tool_call('search_files', { pattern => '*.pm' })->get;
  });
  is(\@passthrough, ['search_files', { pattern => '*.pm' }], 'name/input unchanged');
  like($out, qr/^> search_files pattern=\*\.pm$/m, 'tool call line printed');
};

subtest 'plugin_after_tool_call reports byte count and first line of a text result' => sub {
  my $plugin = trace_plugin();
  my $text   = "line one\nline two";
  my $result = { content => [ { type => 'text', text => $text } ] };
  my $got;
  my $out = capture_stdout(sub { $got = $plugin->plugin_after_tool_call('search_files', {}, $result)->get });
  is($got, $result, 'result returned unchanged');
  my $bytes = length $text;
  like($out, qr/^\. ${bytes}b line one$/m, 'ok marker, byte count, first line only');
};

subtest 'plugin_after_tool_call flags an isError result' => sub {
  my $plugin = trace_plugin();
  my $result = { isError => 1, content => [ { type => 'text', text => 'boom' } ] };
  my $out = capture_stdout(sub { $plugin->plugin_after_tool_call('t', {}, $result)->get });
  like($out, qr/^! 4b boom$/m, 'error marker used instead of ok');
};

subtest 'plugin_after_tool_call handles a plain scalar result' => sub {
  my $plugin = trace_plugin();
  my $out = capture_stdout(sub { $plugin->plugin_after_tool_call('t', {}, 'plain text')->get });
  like($out, qr/^\. 10b plain text$/m, 'plain scalar result summarised too');
};

subtest 'plugin_after_llm_response accumulates token_stats across shapes' => sub {
  my $plugin = trace_plugin();
  is($plugin->token_stats, { prompt => 0, completion => 0, total => 0, calls => 0 }, 'starts at zero');

  $plugin->plugin_after_llm_response({ usage => { prompt_tokens => 10, completion_tokens => 5 } }, 1)->get;
  is($plugin->token_stats, { prompt => 10, completion => 5, total => 15, calls => 1 }, 'openai-shaped usage counted');

  $plugin->plugin_after_llm_response({ usage => { input_tokens => 3, output_tokens => 2 } }, 2)->get;
  is($plugin->token_stats, { prompt => 13, completion => 7, total => 20, calls => 2 }, 'anthropic-shaped usage accumulates');

  $plugin->plugin_after_llm_response({ response => { usage => { prompt_tokens => 1, completion_tokens => 1 } } }, 3)->get;
  is($plugin->token_stats, { prompt => 14, completion => 8, total => 22, calls => 3 }, 'nested response.usage fallback');

  $plugin->plugin_after_llm_response({ no_usage_here => 1 }, 4)->get;
  is($plugin->token_stats->{calls}, 3, 'a response without usage does not bump calls');

  # Langertha::Usage->from_raw (k195) also reads Gemini and Ollama-native
  # bodies, which the hand-written parser counted as "no usage".
  $plugin->plugin_after_llm_response({ usageMetadata => { promptTokenCount => 4, candidatesTokenCount => 2, totalTokenCount => 6 } }, 5)->get;
  is($plugin->token_stats, { prompt => 18, completion => 10, total => 28, calls => 4 }, 'gemini usageMetadata counted');

  $plugin->plugin_after_llm_response({ prompt_eval_count => 7, eval_count => 3 }, 6)->get;
  is($plugin->token_stats, { prompt => 25, completion => 13, total => 38, calls => 5 }, 'ollama-native top-level counts counted');
};

subtest 'plugin_before_llm_call passes the conversation through unchanged' => sub {
  my $plugin = trace_plugin();
  my $conv = [ { role => 'user', content => 'hi' } ];
  my $result = $plugin->plugin_before_llm_call($conv, 1)->get;
  is($result, $conv, 'conversation returned as-is');
};

subtest 'spinner stays disabled without a loop attribute' => sub {
  my $plugin = trace_plugin();
  ok(!$plugin->has_loop, 'no loop given');
  is($plugin->_spinner_enabled, 0, 'spinner disabled without a loop, regardless of color/tty');
};

subtest 'color rendering can be switched on, and ANSI_COLORS_DISABLED overrides it' => sub {
  local $ENV{ANSI_COLORS_DISABLED};

  my $colored = trace_plugin(color => 1);
  my $out = capture_stdout(sub { $colored->plugin_before_tool_call('search_files', {})->get });
  like($out, qr/\e\[/, 'ANSI escape present when color is enabled');

  local $ENV{ANSI_COLORS_DISABLED} = 1;
  my $out2 = capture_stdout(sub { $colored->plugin_before_tool_call('search_files', {})->get });
  unlike($out2, qr/\e\[/, 'ANSI_COLORS_DISABLED env overrides an enabled color attribute');
};

done_testing;
