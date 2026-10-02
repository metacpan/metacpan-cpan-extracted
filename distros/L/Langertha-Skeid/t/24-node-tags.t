use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Langertha::Skeid;

# Tags group nodes for routing without naming machines (ADR 0008). Routing derives its node
# lists from the inventory and caches them, so most of this file is about the cache being
# dropped when the inventory changes -- a stale list keeps sending traffic to a node that was
# drained or removed, and it does so silently.

sub _skeid_with_nodes {
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'local-a', url => 'http://l1/v1', model => 'm1', tags => ['local', 'gb10']);
  $skeid->add_node(id => 'local-b', url => 'http://l2/v1', model => 'm1', tags => ['local', 'gb10']);
  $skeid->add_node(id => 'cloud-a', url => 'http://c1/v1', model => 'm1', tags => ['cloud', 'groq']);
  return $skeid;
}

# --- normalization ---
{
  is_deeply(Langertha::Skeid->normalize_tags(['Local', ' GB10 ', 'local']), ['local', 'gb10'],
    'tags are lowercased, trimmed, de-duplicated, order preserved');
  is_deeply(Langertha::Skeid->normalize_tags('local, gb10'), ['local', 'gb10'],
    'a comma-separated string is accepted, because configs are written by hand');
  is_deeply(Langertha::Skeid->normalize_tags(undef), [], 'no tags is an empty list, never undef');

  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://n1/v1');
  is_deeply($skeid->list_nodes->[0]{tags}, [], 'a node without tags still carries an empty list');
}

# --- selection ---
{
  my $skeid = _skeid_with_nodes();

  is_deeply([sort map { $_->{id} } @{$skeid->select_nodes(tags => ['local'])}],
    ['local-a', 'local-b'], 'selection by one tag');

  # AND, not OR: a selector names every property a node must have.
  is_deeply([map { $_->{id} } @{$skeid->select_nodes(tags => ['local', 'groq'])}],
    [], 'a node must carry every tag in the selector');

  is(scalar(@{$skeid->select_nodes}), 3, 'no selector selects everything');

  my $selected = $skeid->select_nodes(tags => ['local']);
  $selected->[0]{model} = 'mutated';
  is($skeid->list_nodes->[0]{model}, 'm1', 'selection returns copies, not the live inventory');
}

# --- routing honours tags ---
{
  my $skeid = _skeid_with_nodes();

  my %seen;
  $seen{ $skeid->pick_node(model => 'm1', tags => ['local'])->{id} }++ for 1 .. 6;
  is_deeply([sort keys %seen], ['local-a', 'local-b'],
    'a tagged selection never routes outside its tags');

  is($skeid->pick_node(model => 'm1', tags => ['cloud'])->{id}, 'cloud-a', 'cloud selection routes to cloud');
  ok(!defined $skeid->pick_node(model => 'm1', tags => ['nonesuch']), 'an unmatched tag routes nowhere');

  my $state = $skeid->route_state(model => 'm1', tags => ['local']);
  is($state->{eligible_count}, 2, 'route state counts only the selected nodes');
  is_deeply($state->{tags}, ['local'], 'route state reports the selection it answered for');
}

# --- round-robin cursors do not bleed between selections ---
{
  my $skeid = _skeid_with_nodes();
  # Different selections over the same model address different node sets. Sharing one cursor
  # across sets of different size picks the wrong node.
  my $local = $skeid->pick_node(model => 'm1', tags => ['local']);
  my $cloud = $skeid->pick_node(model => 'm1', tags => ['cloud']);
  isnt($local->{route_key}, $cloud->{route_key}, 'each selection gets its own round-robin cursor');
  is($cloud->{id}, 'cloud-a', 'the cloud selection is unaffected by the local one');
}

# --- cache invalidation: this is where a bug would be silent ---
{
  my $skeid = _skeid_with_nodes();
  ok($skeid->pick_node(model => 'm1', tags => ['local']), 'warm the cache');

  $skeid->set_node_health('local-a', 0);
  $skeid->set_node_health('local-b', 0);
  ok(!defined $skeid->pick_node(model => 'm1', tags => ['local']),
    'draining nodes takes effect immediately, not after the next unrelated change');

  # pick_node alone does not prove the cache was dropped: admission re-reads healthy from the
  # live node, so it would refuse a drained node either way. route_state is the one that
  # answers from the cached list -- and its has_eligible is what makes the proxy choose
  # "no such model" (503) over "everything is busy, wait" (429). A stale list there turns an
  # outage into a retry loop.
  my $drained = $skeid->route_state(model => 'm1', tags => ['local']);
  is($drained->{eligible_count}, 0, 'a drained node leaves the eligible set, not just the available one');
  ok(!$drained->{has_eligible}, 'so the proxy reports no eligible node rather than waiting for capacity');

  $skeid->set_node_health('local-a', 1);
  is($skeid->pick_node(model => 'm1', tags => ['local'])->{id}, 'local-a', 'and bringing one back works too');
  is($skeid->route_state(model => 'm1', tags => ['local'])->{eligible_count}, 1, 'and it is eligible again');
}

{
  my $skeid = _skeid_with_nodes();
  ok($skeid->pick_node(model => 'm1', tags => ['local']), 'warm the cache');

  $skeid->remove_node('local-a');
  $skeid->remove_node('local-b');
  ok(!defined $skeid->pick_node(model => 'm1', tags => ['local']), 'removed nodes stop receiving traffic');

  $skeid->add_node(id => 'local-c', url => 'http://l3/v1', model => 'm1', tags => ['local']);
  is($skeid->pick_node(model => 'm1', tags => ['local'])->{id}, 'local-c', 'a new node is picked up immediately');
}

{
  my $skeid = _skeid_with_nodes();
  ok($skeid->pick_node(model => 'm1'), 'warm the cache');

  # The public accessor can replace the whole inventory without going through add_node.
  $skeid->nodes([{ id => 'raw-1', url => 'http://r1/v1', model => 'm1', engine => 'openaibase', healthy => 1 }]);
  is($skeid->pick_node(model => 'm1')->{id}, 'raw-1', 'assigning the node list directly invalidates the cache');
}

# --- tags survive a config file, including a reload ---
{
  my $dir  = tempdir(CLEANUP => 1);
  my $file = "$dir/skeid.yaml";

  open my $fh, '>', $file or die $!;
  print $fh <<'YAML';
nodes:
  - id: cfg-local
    url: http://l/v1
    model: m1
    tags: [Local, GB10]
  - id: cfg-cloud
    url: http://c/v1
    model: m1
    tags: cloud, groq
YAML
  close $fh;

  my $skeid = Langertha::Skeid->new(config_file => $file);
  my %tags = map { $_->{id} => $_->{tags} } @{$skeid->list_nodes};
  is_deeply($tags{'cfg-local'}, ['local', 'gb10'], 'YAML list form is normalized');
  is_deeply($tags{'cfg-cloud'}, ['cloud', 'groq'], 'YAML string form is normalized');
  is($skeid->pick_node(model => 'm1', tags => ['gb10'])->{id}, 'cfg-local', 'config tags are routable');

  sleep 1;    # mtime resolution
  open $fh, '>', $file or die $!;
  print $fh <<'YAML';
nodes:
  - id: cfg-local
    url: http://l/v1
    model: m1
    tags: [cloud]
YAML
  close $fh;

  $skeid->maybe_reload_config;
  ok(!defined $skeid->pick_node(model => 'm1', tags => ['gb10']),
    'a reload that retags a node stops the old selection matching it');
  is($skeid->pick_node(model => 'm1', tags => ['cloud'])->{id}, 'cfg-local', 'and the new selection matches');
}

done_testing;
