#!/usr/bin/env perl
# ABSTRACT: Plugin::Events reports a model.usage event for every model call (ADR 0026, addendum)
use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Future;
use Langertha::Raider::Plugin::Events;

my @events;
my $host = bless {}, q(Fake::Host);
my $plugin = Langertha::Raider::Plugin::Events->new(
  host     => $host,
  on_event => sub { my ( $type, %p ) = @_; push @events, { type => $type, %p } },
);
sub after { my ($data) = @_; @events = (); my $r = $plugin->plugin_after_llm_response( $data, 1 )->get; return $r }

subtest 'openai-shaped usage, the model from the response' => sub {
  my $data = { content => 'x', model => 'gpt-4o', usage => { prompt_tokens => 12, completion_tokens => 3 } };
  is after($data), $data, 'the response passes through unchanged';
  is \@events, [ { type => 'model.usage', purpose => 'chat', model => 'gpt-4o', input_tokens => 12, output_tokens => 3 } ],
    'one event; no cache keys when the provider reported none';
};

subtest 'anthropic cache counts are reported' => sub {
  after({ model => 'claude-haiku-4-5', usage => { input_tokens => 5, output_tokens => 2,
    cache_read_input_tokens => 900, cache_creation_input_tokens => 40 } });
  is $events[0]{cache_read_tokens}, 900, 'cache read';
  is $events[0]{cache_write_tokens}, 40, 'cache write';
  is $events[0]{input_tokens}, 5, 'input as reported';
};

subtest 'no usage, no event' => sub {
  after({ content => 'x' });
  is \@events, [], 'nothing reported';
};

done_testing;
