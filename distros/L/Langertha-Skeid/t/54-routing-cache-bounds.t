use strict;
use warnings;
use Test::More;
use Langertha::Skeid;

sub cache_keys {
  my ($skeid) = @_;
  return [sort keys %{$skeid->_route_cache->{entries}}];
}

sub cursor_keys {
  my ($skeid) = @_;
  return [sort keys %{$skeid->_rr_cursor}];
}

# Unknown requested models are negative cache entries too. Client-chosen names must not grow the
# derived-route cache without a fixed bound even when no round-robin cursor is ever created.
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'specific', url => 'http://specific/v1', model => 'known');

  $skeid->route_state(model => "missing-$_") for 1 .. 400;

  cmp_ok scalar(@{cache_keys($skeid)}), '<=', 256,
    'negative requested-model entries stay within the fixed route-cache bound';
  is scalar(@{cursor_keys($skeid)}), 0, 'negative entries do not create round-robin cursors';
}

# A wildcard node makes every requested model eligible, so each name can create both a cache entry
# and a cursor. Eviction is coupled: no cursor may outlive the entry whose weighted range it tracks.
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'a', url => 'http://a/v1');
  $skeid->add_node(id => 'b', url => 'http://b/v1');

  is $skeid->pick_node(model => 'steady')->{id}, 'a', 'the first weighted pick starts at node a';
  my $steady_key = $skeid->_route_key(model => 'steady');
  ok exists $skeid->_rr_cursor->{$steady_key}, 'the steady route has a cursor before churn';

  $skeid->pick_node(model => "wild-$_") for 1 .. 400;
  my @entries = @{cache_keys($skeid)};
  my @cursors = @{cursor_keys($skeid)};

  cmp_ok scalar(@entries), '<=', 256, 'wildcard requested-model entries stay within the fixed bound';
  is_deeply \@cursors, \@entries, 'cache eviction removes the matching round-robin cursor';
  ok !exists($skeid->_route_cache->{entries}{$steady_key}), 'the oldest route is evicted under sustained churn';
  ok !exists($skeid->_rr_cursor->{$steady_key}), 'its fairness cursor is reset with it';
  is $skeid->pick_node(model => 'steady')->{id}, 'a',
    'an evicted route restarts weighted fairness from the first range';
  cmp_ok scalar(@{cache_keys($skeid)}), '<=', 256, 'reinserting an evicted route still respects the bound';
  is_deeply cursor_keys($skeid), cache_keys($skeid),
    'the reinserted route keeps cache entries and cursors coupled';
}

# Tags and denied tags are part of the route key and remain so across the bounded cache. A policy
# selection must not inherit a cursor or eligible set from a differently constrained selection.
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'cloud', url => 'http://cloud/v1', tags => ['cloud']);
  $skeid->add_node(id => 'local', url => 'http://local/v1', tags => ['local']);

  my $local = $skeid->pick_node(model => 'shared', tags => ['local']);
  my $policy = $skeid->pick_node(model => 'shared', deny_tags => ['cloud']);
  isnt $local->{route_key}, $policy->{route_key}, 'tag and policy selections keep separate route keys';
  is $local->{id}, 'local', 'the tag selection stays on the selected node';
  is $policy->{id}, 'local', 'the denied tag still filters node eligibility';
}

# Reasserting the health a node already has changes no eligible set. It must not restart weighted
# fairness or make the probe inventory look newer than the nodes it describes.
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'a', url => 'http://a/v1', model => 'm');
  $skeid->add_node(id => 'b', url => 'http://b/v1', model => 'm');
  $skeid->_probe_inventory_key;

  is $skeid->pick_node(model => 'm')->{id}, 'a', 'the first pick advances fairness past node a';
  my $inventory_generation = $skeid->_inventory_generation;
  my $probe_generation = $skeid->_probe_key_cache->{generation};

  ok $skeid->set_node_health('a', 1), 'the idempotent health update still finds the node';
  is $skeid->_inventory_generation, $inventory_generation,
    'an idempotent health update does not advance the inventory generation';
  $skeid->_probe_inventory_key;
  is $skeid->_probe_key_cache->{generation}, $probe_generation,
    'an idempotent health update does not rebuild the probe inventory generation';
  is $skeid->pick_node(model => 'm')->{id}, 'b',
    'an idempotent health update preserves the weighted fairness cursor';
}

# Every existing cursor describes weight ranges in one inventory generation. An inventory change
# invalidates all of them rather than retaining client-created cursor keys indefinitely.
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'a', url => 'http://a/v1', model => 'm');
  $skeid->add_node(id => 'b', url => 'http://b/v1', model => 'm');
  $skeid->pick_node(model => 'm');
  is scalar(@{cursor_keys($skeid)}), 1, 'routing creates one cursor before the inventory change';

  $skeid->set_node_health('a', 0);
  is scalar(@{cursor_keys($skeid)}), 0, 'an inventory change clears stale round-robin cursors immediately';
  is $skeid->pick_node(model => 'm')->{id}, 'b', 'routing rebuilds against the changed inventory';
}

done_testing;
