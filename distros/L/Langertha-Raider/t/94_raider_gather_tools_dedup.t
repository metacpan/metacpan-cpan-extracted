#!/usr/bin/env perl
# ABSTRACT: _gather_tools_f dedups tool names first-wins and warns (karr k90)

use strict;
use warnings;

use Test2::Bundle::More;

use Future;
use Langertha::Raider;

# --- Minimal mock engine composing Role::Tools (so it has mcp_servers) ---

{
  package MockEngine;
  use Moose;
  with 'Langertha::Role::Tools';

  has chat_model     => (is => 'ro', default => 'mock-model');
  has '+mcp_servers' => (default => sub { [] });

  sub format_tools          { return $_[1] }
  sub response_tool_calls   { return [] }
  sub extract_tool_call     { return ($_[1]->{name}, $_[1]->{input}) }
  sub format_tool_results   { return () }
  sub response_text_content { return 'mock response' }
  sub think_tag_filter      { 0 }

  __PACKAGE__->meta->make_immutable;
}

# --- Fake MCP server: returns a fixed, already-done tool list ---

{
  package FakeMCP;
  use Moose;
  use Future;

  has tools => (is => 'ro', required => 1);   # ArrayRef of tool-def HashRefs

  sub list_tools { return Future->done($_[0]->tools) }
  sub call_tool  { return Future->done({ content => [] }) }

  __PACKAGE__->meta->make_immutable;
}

# Collect the tool names in gather order.
sub names_of { [ map { $_->{name} } @{ $_[0] } ] }

# --- A name offered by two sources is sent once, first source wins, warns ---

subtest 'duplicate tool name across two sources: first-wins + carp' => sub {
  my $mcp_a = FakeMCP->new(tools => [
    { name => 'shared', src => 'A' },
    { name => 'only_a', src => 'A' },
  ]);
  my $mcp_b = FakeMCP->new(tools => [
    { name => 'shared', src => 'B' },
    { name => 'only_b', src => 'B' },
  ]);

  my $raider = Langertha::Raider->new(
    engine => MockEngine->new(mcp_servers => [ $mcp_a ]),
  );
  # $mcp_b is a second, later source (an active catalog MCP).
  $raider->_active_catalog_mcps->{cat} = $mcp_b;

  my @warnings;
  my ( $all_tools, $map );
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ( $all_tools, $map ) = $raider->_gather_tools_f->get;
  }

  is_deeply(names_of($all_tools), [ 'shared', 'only_a', 'only_b' ],
    'shared appears once; the tool set sent to the provider has no duplicate name');

  my ($shared) = grep { $_->{name} eq 'shared' } @$all_tools;
  is($shared->{src}, 'A',
    'first source (engine mcp_servers) wins the shared name');

  is($map->{shared}, $mcp_a, 'shared routes to the first source');
  is($map->{only_a}, $mcp_a, 'only_a routes to the engine mcp server');
  is($map->{only_b}, $mcp_b, 'only_b routes to the catalog mcp');

  is(scalar(@warnings), 1, 'exactly one warning for the one collision');
  like($warnings[0],
    qr/Langertha::Raider: tool 'shared' is offered by .+ and .+; using the first/,
    'warning names the tool and both sources, mirroring the core carp text');
};

# --- Control: disjoint names produce no warning and no drops ---

subtest 'no duplicate names: nothing dropped, nothing warned' => sub {
  my $mcp_a = FakeMCP->new(tools => [ { name => 'a1' }, { name => 'a2' } ]);
  my $mcp_b = FakeMCP->new(tools => [ { name => 'b1' } ]);

  my $raider = Langertha::Raider->new(
    engine => MockEngine->new(mcp_servers => [ $mcp_a ]),
  );
  $raider->_active_catalog_mcps->{cat} = $mcp_b;

  my @warnings;
  my ( $all_tools, $map );
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ( $all_tools, $map ) = $raider->_gather_tools_f->get;
  }

  is_deeply(names_of($all_tools), [ 'a1', 'a2', 'b1' ], 'all tools kept');
  is(scalar(@warnings), 0, 'no warning without a collision');
};

# --- Self-tools participate in the dedup against earlier sources ---

subtest 'self-tool name colliding with an earlier MCP source is deduped' => sub {
  # A catalog MCP that (contrived) offers a name in the raider_ self-tool space.
  my $mcp = FakeMCP->new(tools => [ { name => 'raider_ask_user', src => 'mcp' } ]);

  my $raider = Langertha::Raider->new(
    engine     => MockEngine->new(mcp_servers => []),
    raider_mcp => 1,   # enables the raider_ask_user self-tool
  );
  $raider->_active_catalog_mcps->{cat} = $mcp;

  my @warnings;
  my ( $all_tools ) = do {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $raider->_gather_tools_f->get;
  };

  my @ask = grep { $_->{name} eq 'raider_ask_user' } @$all_tools;
  is(scalar(@ask), 1, 'raider_ask_user sent to the provider only once');
  is($ask[0]->{src}, 'mcp', 'the earlier (catalog MCP) source wins over the self-tool');
  is(scalar(grep { /raider_ask_user/ } @warnings), 1,
    'the dropped self-tool duplicate is warned about');
};

done_testing;
