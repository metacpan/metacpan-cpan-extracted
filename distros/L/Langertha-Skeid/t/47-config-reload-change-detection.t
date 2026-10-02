use strict;
use warnings;
use Test::More;
use Test::Mojo;
use File::Temp qw(tempfile);
use Langertha::Skeid;

# These probes use a ten-minute interval so the timer never fires during the test; the warning
# about an interval longer than capacity_max_age_ms (ADR 0017) is expected here and only noise.
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /must be below capacity_max_age_ms/ };
use Langertha::Skeid::Proxy;

# A config_loader is re-read from call_function, which every request passes through several
# times (skeid #38). Rebuilding the node list on each read bumps the inventory generation, which
# restarts every capacity probe and forgets the health an admin set -- for a config that did not
# change. So a loader runs at most once per config_reload_interval, and a load that reads what
# was already applied changes nothing.

# A controllable clock for the throttle.
my $NOW = 1_000_000;
{
  no warnings 'redefine';
  *Langertha::Skeid::_now = sub { $NOW };
}

sub nodes_cfg {
  return [
    { id => 'n1', url => 'http://n1/v1', model => 'm', healthy => 1 },
    { id => 'n2', url => 'http://n2/v1', model => 'm', healthy => 1 },
  ];
}

# --- the throttle: one loader run per interval, however many dispatches ---
{
  my $calls = 0;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 1,
    config_loader => sub { $calls++; return { nodes => nodes_cfg() } },
  );
  is $calls, 1, 'the loader runs once at construction';

  $skeid->call_function('nodes.list', {}) for 1 .. 50;
  is $calls, 1, '50 dispatches inside the interval do not rerun the loader';

  $NOW += 1.5;
  $skeid->call_function('nodes.list', {}) for 1 .. 50;
  is $calls, 2, 'past the interval it runs once more, not once per dispatch';

  $NOW += 0.5;
  $skeid->call_function('nodes.list', {});
  is $calls, 2, 'and not again until another interval has passed';
}

# --- an unchanged load is a no-op ---
{
  my $calls = 0;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    # A fresh structure on every call: the digest has to be of the content, not of the Perl
    # objects that carry it.
    config_loader => sub {
      $calls++;
      return {
        nodes   => nodes_cfg(),
        pricing => { m => { input_per_million => 1, output_per_million => 2 } },
      };
    },
  );
  my $nodes      = $skeid->nodes;
  my $generation = $skeid->_inventory_generation;

  ok $skeid->set_node_health('n2', 0), 'an admin takes n2 out of rotation';
  $generation = $skeid->_inventory_generation;

  $skeid->call_function('nodes.list', {}) for 1 .. 20;
  is $calls, 21, 'with interval 0 the loader runs on every dispatch';
  is $skeid->nodes, $nodes, 'but the node list is the same array';
  is $skeid->_inventory_generation, $generation, 'the inventory generation does not move';
  is $skeid->list_nodes->[1]{healthy}, 0, 'and the health the admin set survives';
  is $skeid->maybe_reload_config, 0, 'maybe_reload_config reports that nothing was applied';
}

# --- only the nodes section decides whether the node list is rebuilt ---
{
  my $cfg = { nodes => nodes_cfg(), pricing => { m => { input_per_million => 1 } } };
  my $skeid = Langertha::Skeid->new(config_reload_interval => 0, config_loader => sub { $cfg });
  $skeid->set_node_health('n2', 0);
  my $generation = $skeid->_inventory_generation;

  $cfg = { nodes => nodes_cfg(), pricing => { m => { input_per_million => 7 } } };
  is $skeid->maybe_reload_config, 1, 'a changed pricing section is applied';
  is $skeid->pricing_for_model('m')->{input_per_million}, 7, 'the new price is in force';
  is $skeid->_inventory_generation, $generation, 'but identical nodes keep their generation';
  is $skeid->list_nodes->[1]{healthy}, 0, 'and their admin-set health';

  $cfg = { nodes => [ @{nodes_cfg()}, { id => 'n3', url => 'http://n3/v1', model => 'm' } ],
           pricing => { m => { input_per_million => 7 } } };
  is $skeid->maybe_reload_config, 1, 'a changed nodes section is applied';
  isnt $skeid->_inventory_generation, $generation, 'and that does move the generation';
  is scalar(@{$skeid->nodes}), 3, 'to the new list';
  is $skeid->list_nodes->[1]{healthy}, 1, 'which is the declared state again';
}

# --- a loader version is the change detector when it gives one ---
{
  my ($version, $port) = ('v1', 1);
  my $calls = 0;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader => sub {
      $calls++;
      return ({ nodes => [ { id => 'n1', url => "http://n1:$port/v1", model => 'm' } ] }, $version);
    },
  );
  $port = 2;
  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{url}, 'http://n1:1/v1',
    'an unchanged version means unchanged: the loader vouches for it, the structure is not digested';
  $version = 'v2';
  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{url}, 'http://n1:2/v1', 'a new version is applied';
}

# --- a config file touched without a change ---
{
  my ($fh, $path) = tempfile();
  print $fh "nodes:\n  - id: f1\n    url: http://f1/v1\n";
  close $fh;
  my $skeid = Langertha::Skeid->new(config_file => $path);
  $skeid->set_node_health('f1', 0);
  my $generation = $skeid->_inventory_generation;

  utime(time + 10, time + 10, $path) or die "utime: $!";
  is $skeid->maybe_reload_config, 0, 'a touched but unchanged file applies nothing';
  is $skeid->_inventory_generation, $generation, 'the generation stays';
  is $skeid->list_nodes->[0]{healthy}, 0, 'and so does the admin-set health';
}

# --- through the proxy: probes are not restarted by requests ---
{
  my $polls = 0;
  my $probe_code = sub { $polls++; return };    # one callback, so the config digests alike
  my $loads = 0;
  my $nodes_version = 1;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,
    config_loader => sub {
      $loads++;
      return {
        admin => { api_key => 'adm' },
        nodes => [
          { id => 'p1', url => "http://p1:$nodes_version/v1", model => 'm',
            capacity => { probe => 'custom', interval_ms => 600_000, code => $probe_code } },
        ],
      };
    },
  );
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
  is $polls, 1, 'the probe starts once with the app (a start polls immediately)';

  $t->post_ok('/skeid/nodes/p1/health' => { Authorization => 'Bearer adm' } => json => { healthy => 0 })
    ->status_is(200);
  # Counted from the flip itself: health drops the route cache, not the probes (skeid #40).
  my $starts_after_admin = $polls;

  for (1 .. 25) {
    $t->get_ok('/skeid/nodes' => { Authorization => 'Bearer adm' })->status_is(200);
  }
  ok $loads >= 25, 'every admin request ran the loader (interval 0)';
  is $polls, $starts_after_admin, 'but 25 requests over an unchanged config restart no probe';
  is $t->tx->res->json->{nodes}[0]{healthy}, 0, 'and the health set through the admin API holds';

  $nodes_version = 2;
  $t->get_ok('/skeid/nodes' => { Authorization => 'Bearer adm' })->status_is(200);
  $t->get_ok('/skeid/nodes' => { Authorization => 'Bearer adm' })->status_is(200);
  is $polls, $starts_after_admin + 1, 'a changed node list restarts the probes exactly once';
}

done_testing;
