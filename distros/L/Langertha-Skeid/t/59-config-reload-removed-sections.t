use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Langertha::Skeid;

# skeid k65: a reload makes the running config equal to the file. A section the file declared
# and no longer does goes back to what a restart with that file would give -- it used to stay
# loaded until restart, and pricing entries were merged, so a removed price was never removed.
# A section the file never declared is left alone: nodes pushed through the admin API, prices
# set through pricing.set. The one exception is the usage store: removing it keeps the running
# store (usage events are billing data, ADR 0004) and says so.

sub _skeid {
  my ($cfg_ref, %args) = @_;
  return Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader          => sub { return { %{ $$cfg_ref } } },
    %args,
  );
}

sub _records {
  my ($skeid) = @_;
  return $skeid->call_function('usage.record', {
    api_key_id => 'k_test', model => 'm', status_code => 200, ok => 1,
    metrics    => { usage => { input => 1, output => 1, total => 2 } },
  })->{ok};
}

my @nodes = ({ id => 'n1', url => 'http://127.0.0.1:1/v1', model => 'm' });
my $price = { input_per_million => 1, output_per_million => 2 };

# --- pricing: the section replaces the prices, removing it clears them ---
{
  my $cfg = { nodes => [@nodes], pricing => { a => $price, b => $price } };
  my $skeid = _skeid(\$cfg);
  is $skeid->pricing_for_model('b')->{input_per_million}, 1, 'pricing: loaded';

  $cfg = { nodes => [@nodes], pricing => { a => $price } };
  $skeid->call_function('nodes.list', {});
  is $skeid->pricing_for_model('b')->{input_per_million}, 0,
    'pricing: a model removed from the section loses its price';
  is $skeid->pricing_for_model('a')->{input_per_million}, 1, 'pricing: the one left keeps it';

  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  is_deeply $skeid->model_pricing, {}, 'pricing: the section removed clears every price';
}

# --- pricing never in the file: a price set through the API survives a reload ---
{
  my $cfg = { nodes => [@nodes] };
  my $skeid = _skeid(\$cfg);
  $skeid->call_function('pricing.set', { model => 'api', pricing => $price });
  $cfg = { nodes => [@nodes, { id => 'n2', url => 'http://127.0.0.1:2/v1', model => 'm' }] };
  $skeid->call_function('nodes.list', {});
  is $skeid->pricing_for_model('api')->{input_per_million}, 1,
    'pricing: a price the file never declared is not the file\'s to remove';
}

# --- aliases ---
{
  my $cfg = {
    nodes   => [@nodes],
    aliases => { house => { tiers => [ { model => 'm' } ] } },
  };
  my $skeid = _skeid(\$cfg);
  ok $skeid->model_aliases->{house}, 'aliases: loaded';
  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  is_deeply $skeid->model_aliases, {}, 'aliases: the section removed clears them';
}

# --- the policy sections ---
{
  my $id = 'k_' . ('a' x 40);
  my $cfg = {
    nodes          => [@nodes],
    policies       => { standard => { deny_tags => ['cloud'] } },
    default_policy => 'standard',
    names          => { alice => $id },
    keys           => { alice => 'standard' },
  };
  my $skeid = _skeid(\$cfg);
  ok $skeid->default_policy, 'policies: loaded';
  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  is_deeply $skeid->policies, {}, 'policies: removed';
  is $skeid->default_policy, undef, 'policies: default_policy removed';
  is_deeply $skeid->key_policies, {}, 'policies: keys removed';
  is_deeply $skeid->key_names, {}, 'policies: names removed';
  is $skeid->policy_for_key($id), undef, 'policies: the key is unrestricted again';
}

# --- nodes ---
{
  my $cfg = { nodes => [@nodes], aliases => {} };
  my $skeid = _skeid(\$cfg);
  is scalar @{ $skeid->list_nodes }, 1, 'nodes: loaded';
  $cfg = { aliases => {} };
  $cfg->{routing} = { wait_poll_ms => 30 };
  $skeid->call_function('nodes.list', {});
  is_deeply $skeid->list_nodes, [], 'nodes: the section removed empties the inventory';
}

# --- nodes never in the file: nodes added through the API survive a reload ---
{
  my $cfg = { aliases => {} };
  my $skeid = _skeid(\$cfg);
  $skeid->call_function('nodes.add', { id => 'api-1', url => 'http://127.0.0.1:3/v1' });
  $cfg = { aliases => { x => { tiers => [ { model => 'm' } ] } } };
  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{id}, 'api-1', 'nodes: an inventory the file never declared is kept';
}

# --- routing: a removed key goes back to its default ---
{
  local $ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS} = '';
  local $ENV{SKEID_FRONTEND_COUNT} = '';
  my $cfg = { nodes => [@nodes], routing => { wait_timeout_ms => 50, frontend_count => 3 } };
  my $skeid = _skeid(\$cfg);
  is $skeid->route_wait_timeout_ms, 50, 'routing: loaded';
  $cfg = { nodes => [@nodes], routing => { frontend_count => 3 } };
  $skeid->call_function('nodes.list', {});
  is $skeid->route_wait_timeout_ms, 2000, 'routing: a removed key goes back to its default';
  is $skeid->frontend_count, 3, 'routing: the key left keeps its value';
  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  is $skeid->frontend_count, 1, 'routing: the section removed resets every key it set';
}

# --- routing never in the file: a constructor value survives a reload ---
{
  my $cfg = { nodes => [@nodes] };
  my $skeid = _skeid(\$cfg, route_wait_timeout_ms => 77);
  $cfg = { nodes => [@nodes], aliases => {} };
  $skeid->call_function('nodes.list', {});
  is $skeid->route_wait_timeout_ms, 77, 'routing: a value the file never set is kept';
  $cfg = { nodes => [@nodes], routing => { wait_timeout_ms => 50 } };
  $skeid->call_function('nodes.list', {});
  is $skeid->route_wait_timeout_ms, 50, 'routing: the file sets it';
  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  is $skeid->route_wait_timeout_ms, 77, 'routing: removed again, it is the constructor value once more';
}

# --- a failed reload does not lose track of what the file declared ---
{
  local $SIG{__WARN__} = sub { };
  my $cfg = { nodes => [@nodes], aliases => { house => { tiers => [ { model => 'm' } ] } } };
  my $skeid = _skeid(\$cfg);
  $cfg = { nodes => [@nodes], default_policy => 'missing' };
  $skeid->call_function('nodes.list', {});
  is $skeid->reload_status->{ok}, 0, 'rollback: the broken config fails';
  ok $skeid->model_aliases->{house}, 'rollback: the aliases stay in force';
  $cfg = { nodes => [@nodes], routing => { wait_poll_ms => 30 } };
  $skeid->reload_config;   # explicit: the failed loader is otherwise backed off for a second
  is_deeply $skeid->model_aliases, {}, 'rollback: the next good config still clears them';
}

# --- the usage store: removing it keeps the running store, and says so once ---
{
  my $dir = tempdir(CLEANUP => 1);
  my $cfg = { nodes => [@nodes], usage_store => { backend => 'jsonlog', path => $dir } };
  my $skeid = _skeid(\$cfg);
  ok _records($skeid), 'usage_store: loaded';

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $cfg = { nodes => [@nodes] };
  $skeid->call_function('nodes.list', {});
  ok _records($skeid), 'usage_store: removed from the file, the running store stays';
  is $skeid->usage_store->{path}, $dir, 'usage_store: the same store';
  is scalar(grep { /usage_store.*restart/ } @warnings), 1, 'usage_store: the reload warns once'
    or diag explain \@warnings;

  $cfg = { nodes => [@nodes], aliases => {} };
  $skeid->call_function('nodes.list', {});
  is scalar(grep { /usage_store/ } @warnings), 1, 'usage_store: and not again on the next reload';

  my $other = tempdir(CLEANUP => 1);
  $cfg = { nodes => [@nodes], usage_store => { backend => 'jsonlog', path => $other } };
  $skeid->call_function('nodes.list', {});
  is $skeid->usage_store->{path}, $other, 'usage_store: a changed store still swaps on reload';
}

done_testing;
