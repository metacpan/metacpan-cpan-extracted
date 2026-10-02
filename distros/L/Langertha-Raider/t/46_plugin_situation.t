#!/usr/bin/env perl
# ABSTRACT: Unit tests for Langertha::Raider::Plugin::Situation

use strict;
use warnings;
use Test2::V0;
use Langertha::Raider;
use Langertha::Raider::Plugin::Situation;

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

sub situation_plugin {
  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new,
    raider_mcp => 1,
    plugins    => ['+Langertha::Raider::Plugin::Situation'],
  );
  return $raider->plugin_instances->[0];
}

subtest '_situation_text shape' => sub {
  my $text = Langertha::Raider::Plugin::Situation::_situation_text();
  like($text, qr/^\[situation\] \d{4}-\d\d-\d\d \d\d:\d\d /, 'date/time prefix');
  like($text, qr/\(UTC[+-]\d{4}\)/, 'utc offset');
  like($text, qr/host=\S+/, 'hostname present');
  like($text, qr/user=\S+/, 'user present');
  like($text, qr/\n\n$/, 'trailing blank line separates it from the message');
};

subtest 'plain string message: prefixed once, not again on the next raid' => sub {
  my $plugin = situation_plugin();
  my $msgs = ['hello raider'];
  my $result = $plugin->plugin_before_raid($msgs)->get;
  like($result->[0], qr/^\[situation\].*hello raider\z/s, 'prefixed on first raid');
  is($msgs->[0], 'hello raider', 'caller-owned array left untouched');

  my $second = ['second message'];
  my $result2 = $plugin->plugin_before_raid($second)->get;
  is($result2->[0], 'second message', 'no prefix on a later raid with the same plugin instance');
};

subtest 'hashref message with plain content: content gets prefixed, role preserved' => sub {
  my $plugin = situation_plugin();
  my $original = { role => 'user', content => 'hi there' };
  my $result = $plugin->plugin_before_raid([$original])->get;
  like($result->[0]{content}, qr/^\[situation\].*hi there\z/s, 'content prefixed');
  is($result->[0]{role}, 'user', 'role preserved');
  is($original->{content}, 'hi there', 'original hashref left untouched (a copy was mutated)');
};

subtest 'hashref message with structured content: a leading note is unshifted instead' => sub {
  my $plugin = situation_plugin();
  my $structured = { role => 'user', content => [ { type => 'text', text => 'hi' } ] };
  my $result = $plugin->plugin_before_raid([$structured])->get;
  is(scalar @$result, 2, 'a situation note message is unshifted in front');
  like($result->[0]{content}, qr/^\[situation\]/, 'note carries the situation text');
  is($result->[0]{role}, 'user', 'note role is user');
  is($result->[1], $structured, 'original structured message preserved intact, unmodified');
};

done_testing;
