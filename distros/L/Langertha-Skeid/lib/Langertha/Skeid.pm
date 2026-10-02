package Langertha::Skeid;
our $VERSION = '0.003';
# ABSTRACT: Dynamic routing control-plane for multi-node LLM serving with normalized metrics and cost accounting
use Moo;
use strict;
use warnings;
use Carp qw(croak);
use POSIX qw(strftime);
use Digest::SHA qw(sha1_hex sha256_hex);
use Scalar::Util qw(blessed looks_like_number refaddr reftype weaken);
use Time::HiRes ();
use YAML::PP;
use Langertha ();
use Langertha::Skeid::UsageStore;
use Langertha::Skeid::Protocol;
use Langertha::Skeid::Protocol::Anthropic;
use Langertha::Skeid::Protocol::Ollama;
use Langertha::Usage;
use Langertha::Cost;
use Langertha::Pricing;
use Langertha::UsageRecord;



has nodes => (
  is      => 'rw',
  default => sub { [] },
  # Routing caches derived node lists, so every path that can change the inventory has to
  # invalidate them. The methods below bump the generation explicitly; this trigger catches
  # the remaining one -- somebody assigning the whole list through the public accessor.
  trigger => sub { $_[0]->_bump_inventory },
);


has model_pricing => (
  is      => 'rw',
  default => sub { {} },
);


has model_aliases => (
  is      => 'rw',
  default => sub { {} },
);


has policies => (
  is      => 'rw',
  default => sub { {} },
);


has default_policy => (
  is      => 'rw',
  default => sub { undef },
);


# Key id -> resolved policy. Identical resolutions share one object, and a key that takes the
# default is not listed at all, so ten thousand identical customers cost nothing here.
has key_policies => (
  is      => 'rw',
  default => sub { {} },
);


# Readable name -> customer key id, from the config `names:` section. A config-authoring
# convenience only: it lets `keys:` entries be written by name and localises key rotation to
# one line, and is resolved to key ids once at config load. It never reaches the request path
# -- a request still carries a derived key id, and policy_for_key still costs one hash lookup.
has key_names => (
  is      => 'rw',
  default => sub { {} },
);


# /.well-known/langertha.json (skeid #29, ADR 0015). Off until the config enables it.
has manifest_enabled => (
  is      => 'rw',
  default => sub { 0 },
);

# Whether this Langertha has Langertha::Manifest (core newer than 0.503). Enabled without it,
# the route answers 404 rather than failing the config.
has manifest_available => (
  is      => 'rw',
  default => sub { 0 },
);

# Key id -> the canonical JSON of that key's manifest, built at config load. This is the
# manifest cache, and it is keyed by the key id the caller's key derives to: a customer can
# only ever be served the entry built from its own keys: line, never another key's catalog.
has key_manifests => (
  is      => 'rw',
  default => sub { {} },
);


# Whether x-skeid-key-id / x-api-key-id from the client may name the customer. Off by default:
# once a policy hangs off the key id, believing that header lets any client pick its own
# permissions in one line. Turn it on only when something in front of Skeid authenticates the
# caller and sets the header itself.
has trust_key_id_header => (
  is      => 'rw',
  builder => '_build_trust_key_id_header',
);

sub _build_trust_key_id_header {
  return (defined($ENV{SKEID_TRUST_KEY_ID_HEADER}) && $ENV{SKEID_TRUST_KEY_ID_HEADER} =~ /^(1|true|yes|on)$/i)
    ? 1 : 0;
}


has route_wait_timeout_ms => (
  is      => 'rw',
  builder => '_build_route_wait_timeout_ms',
);

sub _build_route_wait_timeout_ms {
  return (defined($ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS}) && length($ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS}))
    ? 0 + $ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS}
    : 2000;
}


has route_wait_poll_ms => (
  is      => 'rw',
  builder => '_build_route_wait_poll_ms',
);

sub _build_route_wait_poll_ms {
  return (defined($ENV{SKEID_ROUTE_WAIT_POLL_MS}) && length($ENV{SKEID_ROUTE_WAIT_POLL_MS}))
    ? 0 + $ENV{SKEID_ROUTE_WAIT_POLL_MS}
    : 25;
}


has usage_db_path => (
  is        => 'rw',
  predicate => 'has_usage_db_path',
  clearer   => 'clear_usage_db_path',
  default   => sub {
    return (defined($ENV{SKEID_USAGE_DB}) && length($ENV{SKEID_USAGE_DB}))
      ? $ENV{SKEID_USAGE_DB}
      : undef;
  },
);


has usage_store => (
  is      => 'rw',
  default => sub { {} },
);


has store_usage_event => (
  is        => 'ro',
  predicate => 'has_store_usage_event',
);


has query_usage_report => (
  is        => 'ro',
  predicate => 'has_query_usage_report',
);


has on_usage_lost => (
  is        => 'rw',
  predicate => 'has_on_usage_lost',
);


has admin_api_key => (
  is      => 'rw',
  builder => '_build_admin_api_key',
);

sub _build_admin_api_key { $_[0]->_env_admin_api_key }

sub _env_admin_api_key {
  return (defined($ENV{SKEID_ADMIN_API_KEY}) && length($ENV{SKEID_ADMIN_API_KEY}))
    ? $ENV{SKEID_ADMIN_API_KEY}
    : '';
}

# The admin API key given explicitly -- to new(), to build_app, or by `skeid serve
# --admin-api-key` (skeid k64). It outranks the config, so a reload re-resolves the key under
# it instead of overwriting it; empty means none was given.
has _explicit_admin_api_key => (
  is       => 'rw',
  init_arg => undef,
  default  => sub { '' },
);

# The admin API key the config (or SKEID_ADMIN_API_KEY under it) resolved to when it was last
# applied. Kept apart from the explicit key so that clearing that one falls back to it at once.
has _config_admin_api_key => (
  is       => 'rw',
  init_arg => undef,
  builder  => '_build_admin_api_key',
);


has key_broker => (is => 'ro', predicate => 'has_key_broker');


has config_file => (
  is        => 'ro',
  predicate => 'has_config_file',
);


has config_loader => (
  is        => 'ro',
  predicate => 'has_config_loader',
);

has _config_mtime => (
  is      => 'rw',
  default => sub { undef },
);

# A file version that failed before it could update _config_mtime, and when that same version
# may be tried again. A different mtime bypasses this window, so a correction is prompt; the
# retry keeps a transient read error from freezing an otherwise unchanged file forever.
has _config_file_failed_mtime => (
  is      => 'rw',
  default => sub { undef },
);

has _config_file_retry_at => (
  is      => 'rw',
  default => sub { undef },
);

# Set while config_file is missing after a good load, so the loss is warned once.
has _config_file_missing => (
  is      => 'rw',
  default => sub { 0 },
);


has config_reload_interval => (
  is      => 'rw',
  default => sub {
    return (defined($ENV{SKEID_CONFIG_RELOAD_INTERVAL}) && length($ENV{SKEID_CONFIG_RELOAD_INTERVAL}))
      ? 0 + $ENV{SKEID_CONFIG_RELOAD_INTERVAL}
      : 1;
  },
);

# When the loader may run next (see config_reload_interval).
has _config_next_check_at => (
  is      => 'rw',
  default => sub { undef },
);

# What the last applied config was: the loader's version when it gives one, else a digest of
# the loaded structure. A reload that reads the same fingerprint changes nothing (skeid #38).
has _config_fingerprint => (
  is      => 'rw',
  default => sub { undef },
);


has last_reload_error    => (is => 'rw', default => sub { undef });
has last_reload_error_at => (is => 'rw', default => sub { undef });
has reload_failures      => (is => 'rw', default => sub { 0 });

# The fingerprint of the config that last failed to apply. Reading the same one again is not
# retried: the answer would be the same error (skeid #39).
has _failed_fingerprint => (
  is      => 'rw',
  default => sub { undef },
);

# The routing attributes as they were before any config was applied (see BUILD).
has _routing_baseline => (
  is       => 'rw',
  init_arg => undef,
  default  => sub { {} },
);

# The sections the last applied config declared (see _apply_config). A section that was declared
# and is gone from the next config goes back to its default; one never declared is left alone.
has _config_declared => (
  is      => 'rw',
  default => sub { {} },
);

# Digest of the nodes section the node list was last built from. An unchanged section keeps
# the node list -- and with it the inventory generation, the running probes and any health an
# admin set -- even when another section of the config changed.
has _nodes_fingerprint => (
  is      => 'rw',
  default => sub { undef },
);

has _rr_cursor => (
  is      => 'rw',
  default => sub { {} },
);

has _inventory_generation => (
  is      => 'rw',
  default => sub { 0 },
);

has _route_cache => (
  is      => 'rw',
  default => sub { { generation => -1, entries => {}, order => [] } },
);

# The probe key (see _probe_inventory_key) as of one inventory generation.
has _probe_key_cache => (
  is      => 'rw',
  default => sub { { generation => -1, key => undef } },
);

has _inflight => (
  is      => 'rw',
  default => sub { {} },
);

# node_id => normalized capacity reading (see set_capacity_reading). Written by probes off the
# request path, read by admission.
has _capacity => (
  is      => 'rw',
  default => sub { {} },
);


has capacity_max_age_ms => (
  is      => 'rw',
  default => sub {
    return (defined($ENV{SKEID_CAPACITY_MAX_AGE_MS}) && length($ENV{SKEID_CAPACITY_MAX_AGE_MS}))
      ? 0 + $ENV{SKEID_CAPACITY_MAX_AGE_MS}
      : 5000;
  },
);


has worker_count => (
  is      => 'rw',
  default => sub { 1 },
  trigger => sub { $_[0]->_bump_inventory },
);


has frontend_count => (
  is      => 'rw',
  builder => '_build_frontend_count',
);

sub _build_frontend_count {
  return (defined($ENV{SKEID_FRONTEND_COUNT}) && length($ENV{SKEID_FRONTEND_COUNT}))
    ? 0 + $ENV{SKEID_FRONTEND_COUNT}
    : 1;
}


has registry_enabled        => (is => 'rw', default => sub { 0 });
has registry_secret         => (is => 'rw', default => sub { '' });
has registry_read_key       => (is => 'rw', default => sub { '' });
has registry_ttl_s          => (is => 'rw', default => sub { 10 });
has registry_instance_id    => (is => 'rw', default => sub { undef });
has registry_error_window_s => (is => 'rw', default => sub { 60 });

# node_id => { last_at => epoch, buckets => { epoch_second => count } }. Failed requests, for
# the registry snapshot's errors_in_window and last_failure_at. Reported, never consulted by
# admission: health is operator state (ADR 0009, ADR 0017).
has _failures => (
  is      => 'rw',
  default => sub { {} },
);

has _stats => (
  is      => 'rw',
  default => sub { {} },
);

has _usage_store_obj => (
  is      => 'rw',
  default => sub { undef },
);

my %FALLBACK_ENGINE_IDS = map { $_ => 1 } qw(
  aki
  akiopenai
  anthropic
  anthropicbase
  cerebras
  deepseek
  gemini
  groq
  huggingface
  lmstudio
  lmstudioanthropic
  lmstudioopenai
  llamacpp
  minimax
  mistral
  nousresearch
  ollama
  ollamaopenai
  openai
  openaibase
  openrouter
  perplexity
  remote
  replicate
  sglang
  vllm
  whisper
);

# How a routing key of the config sets its attribute. A key removed from the config sets it back
# to its value before any config was applied (_routing_baseline, skeid k65).
my %ROUTING_SETTINGS = (
  wait_timeout_ms     => [ route_wait_timeout_ms => sub { 0 + $_[0] } ],
  wait_poll_ms        => [ route_wait_poll_ms    => sub { my $poll = 0 + $_[0]; $poll < 1 ? 1 : $poll } ],
  trust_key_id_header => [ trust_key_id_header   => sub { $_[0] =~ /^(1|true|yes|on)$/i ? 1 : 0 } ],
  # How many Skeid hosts share the nodes. Only the config knows it -- there is nothing to
  # detect -- and forgetting it over-admits every node by that factor (ADR 0012). Floor at one,
  # so a stray 0 falls back to today's single-frontend behaviour instead of dividing max_conns
  # to nothing.
  frontend_count      => [ frontend_count        => sub { my $n = int(0 + $_[0]); $n < 1 ? 1 : $n } ],
);

sub BUILD {
  my ($self, $args) = @_;
  # A key handed to new() is explicit: the config applied next must not replace it.
  $self->_explicit_admin_api_key("$args->{admin_api_key}")
    if defined($args->{admin_api_key}) && length($args->{admin_api_key});
  # What the routing attributes are without a config -- passed to new(), else from the
  # environment, else built in: a routing key removed from the config goes back to this.
  $self->_routing_baseline({ map { my $attr = $_->[0]; ($attr => $self->$attr) } values %ROUTING_SETTINGS });
  if ($self->has_config_loader || $self->has_config_file) {
    $self->reload_config;
  }
  if (ref($self->usage_store) eq 'HASH' && keys %{$self->usage_store}) {
    $self->_configure_usage_store($self->usage_store);
  } else {
    my $path = $self->usage_db_path;
    if (defined $path && length $path) {
      $self->_set_usage_db_path($path);
    }
  }
}


sub add_node {
  my ($self, %node) = @_;
  my $id  = $node{id}  // croak 'node id required';
  my $url = $node{url} // croak 'node url required';

  # A registry probe with no secret would forget on every poll and look like a silent
  # downstream; say so where the operator wrote it (ADR 0017).
  if (ref($node{capacity}) eq 'HASH'
      && lc($node{capacity}{probe} // $node{capacity}{type} // '') eq 'registry') {
    require Langertha::Skeid::CapacityProbe::Registry;
    Langertha::Skeid::CapacityProbe::Registry->validate_config($node{capacity}, $id);
  }

  $self->remove_node($id);
  push @{$self->nodes}, {
    id          => $id,
    url         => $url,
    model       => ($node{model} // ''),
    engine      => $self->normalize_engine_id((defined($node{engine}) && length($node{engine})) ? $node{engine} : 'OpenAIBase'),
    weight      => (defined $node{weight} ? 0 + $node{weight} : 1),
    max_conns   => (defined $node{max_conns} ? 0 + $node{max_conns} : 0),
    healthy     => (exists $node{healthy} ? ($node{healthy} ? 1 : 0) : 1),
    tags        => $self->normalize_tags($node{tags}),
    metadata    => (ref($node{metadata}) eq 'HASH' ? $node{metadata} : {}),
    (defined($node{api_key_env}) && length($node{api_key_env})
      ? (api_key_env => "$node{api_key_env}")
      : ()),
    (defined($node{api_key_ref}) && length($node{api_key_ref})
      ? (api_key_ref => "$node{api_key_ref}")
      : ()),
    # How this node's capacity is found (ADR 0009). Absent means inflight, which is every
    # deployment that existed before probes did.
    (ref($node{capacity}) eq 'HASH' ? (capacity => { %{$node{capacity}} }) : ()),
  };
  $self->_bump_inventory;
  return 1;
}


sub remove_node {
  my ($self, $id) = @_;
  return 0 unless defined $id && length $id;
  my @keep = grep { ($_->{id} // '') ne $id } @{$self->nodes};
  my $removed = @{$self->nodes} - @keep;
  $self->nodes(\@keep);
  # Or a node re-added under the same id inherits a reading -- or an error history -- about a
  # different machine.
  if ($removed) {
    $self->forget_capacity($id);
    delete $self->_failures->{$id};
  }
  return $removed ? 1 : 0;
}

# What the running capacity probes were built from: the worker count (it sets the poll interval,
# ADR 0010) and, per node with a capacity block, its id, URL and that block. The inventory
# generation is the wrong key for them -- it also moves on a health flip, which has to drop the
# route cache but changes nothing a probe polls, and restarting the probes forgets every reading
# (skeid #40). The URL is in because a Prometheus probe may derive its endpoint from it, and a
# reading about the machine a node id used to point at is not one about the new one.
# Recomputed only when the generation has moved, so the per-request check stays an integer
# compare.
sub _probe_inventory_key {
  my ($self) = @_;
  my $generation = $self->_inventory_generation;
  my $cache = $self->_probe_key_cache;
  return $cache->{key} if ($cache->{generation} // -1) == $generation;

  my $key = _config_digest([
    0 + ($self->worker_count // 1),
    map  { [ $_->{id}, $_->{url}, $_->{capacity} ] }
    sort { ($a->{id} // '') cmp ($b->{id} // '') }
    grep { ref($_->{capacity}) eq 'HASH' }
    @{$self->nodes || []},
  ]);
  $self->_probe_key_cache({ generation => $generation, key => $key });
  return $key;
}

sub _bump_inventory {
  my ($self) = @_;
  # Defensive //0: the nodes trigger can fire during construction, before this attribute's own
  # default has been assigned.
  $self->_inventory_generation(($self->_inventory_generation // 0) + 1);
  # A cursor names weighted ranges in exactly one inventory generation. Keeping it after a
  # health, node or worker-share change both retains client-created keys and resumes fairness at
  # a position that described a different set, so inventory invalidation clears all cursors.
  $self->_rr_cursor({});
  return;
}


sub normalize_tags {
  my ($self, $value) = @_;
  return [] unless defined $value;

  my @raw = ref($value) eq 'ARRAY' ? @$value : split(/[,\s]+/, "$value");
  my (@tags, %seen);
  for my $tag (@raw) {
    next unless defined $tag;
    my $clean = lc "$tag";
    $clean =~ s/\A\s+//;
    $clean =~ s/\s+\z//;
    next unless length $clean;
    next if $seen{$clean}++;
    push @tags, $clean;
  }
  return \@tags;
}


sub list_nodes {
  my ($self) = @_;
  return [ map { +{%$_} } @{$self->nodes} ];
}


sub list_models {
  my ($self, %args) = @_;
  my $policy = $self->policy_for_key($args{api_key_id});
  my $deny   = $policy ? $policy->{deny_tags} : [];
  my %entry;

  for my $n (@{$self->nodes || []}) {
    my $model = $n->{model};
    next unless defined $model && length $model;
    next if $self->_node_has_any_tag($n, $deny);
    $entry{$model} //= { model => $model, engine => ($n->{engine} // '') };
  }
  for my $name (keys %{$self->model_aliases || {}}) {
    $entry{$name} //= { model => $name, engine => '' };
  }

  return [
    map  { $entry{$_} }
    grep { $self->route_plan(model => $_, api_key_id => $args{api_key_id})->{permitted} }
    sort keys %entry
  ];
}


sub set_node_health {
  my ($self, $id, $healthy) = @_;
  return 0 unless defined $id && length $id;
  my ($found, $changed) = (0, 0);
  my $next = $healthy ? 1 : 0;
  for my $n (@{$self->nodes}) {
    next unless ($n->{id} // '') eq $id;
    if (($n->{healthy} ? 1 : 0) != $next) {
      $n->{healthy} = $next;
      $changed = 1;
    }
    $found = 1;
    last;
  }
  # Health is part of eligibility, so flipping it has to drop the derived lists -- otherwise a
  # node taken out of rotation keeps receiving traffic until something else changes. It is not
  # part of the probe key, so the capacity probes and their readings stay (skeid #40). Repeating
  # the current value changes no inventory and must not reset its round-robin cursors.
  $self->_bump_inventory if $changed;
  return $found;
}

# The prompt-cache rates a pricing rule may carry (skeid #28, ADR 0013). Optional: a rule
# without them prices every input token at input_per_million, exactly as before.
my @CACHE_RATE_KEYS = qw(cached_input_per_million cache_write_per_million);
my $cache_rates_unsupported_warned;

# True when the installed Langertha prices prompt-cache reads and writes (Langertha::Cost has
# the cache amounts, core ADR 0031). The released 0.503 does not; there the cache rates are
# dropped at config load, so a rule prices exactly as a rule without them.
sub _core_prices_cache { Langertha::Cost->can('cache_read_usd') ? 1 : 0 }


sub set_model_pricing {
  my ($self, $model, $pricing) = @_;
  croak 'model required' unless defined $model && length $model;
  croak 'pricing hash required' unless ref($pricing) eq 'HASH';
  my %rule = (
    input_per_million  => 0 + ($pricing->{input_per_million}  // 0),
    output_per_million => 0 + ($pricing->{output_per_million} // 0),
  );
  my @rates = grep { defined $pricing->{$_} } @CACHE_RATE_KEYS;
  for my $key (@rates) {
    my $rate = $pricing->{$key};
    croak "pricing for '$model': $key must be a number >= 0"
      unless !ref($rate) && looks_like_number($rate) && $rate >= 0;
  }
  if (@rates && !_core_prices_cache()) {
    warn "skeid: pricing sets cached_input_per_million / cache_write_per_million, but this "
      . "Langertha cannot price prompt-cache tokens; they are ignored and cached tokens bill "
      . "at input_per_million\n"
      unless $cache_rates_unsupported_warned++;
    @rates = ();
  }
  $rule{$_} = 0 + $pricing->{$_} for @rates;
  $self->model_pricing->{$model} = \%rule;
  return $self->model_pricing->{$model};
}


sub pricing_for_model {
  my ($self, $model) = @_;
  return $self->model_pricing->{$model}
    || $self->model_pricing->{'*'}
    || { input_per_million => 0, output_per_million => 0 };
}

# The config state a reload replaces. A reload is all or nothing (skeid #29 review): a
# config that fails anywhere -- a bad policy, alias or manifest grant -- must not leave the
# sections before it applied and the ones after it not, which served every customer a 403
# from an emptied manifest map while routing already ran on the new policies.
my @CONFIG_STATE = qw(
  model_aliases policies default_policy key_policies key_names nodes
  route_wait_timeout_ms route_wait_poll_ms trust_key_id_header frontend_count
  admin_api_key _config_admin_api_key
  manifest_enabled manifest_available key_manifests
  registry_enabled registry_secret registry_read_key registry_ttl_s registry_instance_id registry_error_window_s
);


sub reload_config {
  my ($self) = @_;
  my ($cfg, $fingerprint);
  unless (eval { ($cfg, $fingerprint) = $self->_read_config; 1 }) {
    my $err = $@ || 'config loader failed';
    $self->_record_reload_failure($err, undef);
    die $err;
  }

  # Same config as last applied: nothing to do. Rebuilding would replace the node list, which
  # bumps the inventory generation, restarts every capacity probe and forgets health an admin
  # set -- for a config that did not change (skeid #38).
  my $last = $self->_config_fingerprint;
  if (defined($last) && $last eq $fingerprint) {
    $self->_clear_reload_failure;
    return $cfg;
  }

  # The config that just failed, read again: it would fail the same way, so it is not applied
  # again -- but it still counts as a failure, which is what the retry back-off grows on.
  my $failed = $self->_failed_fingerprint;
  if (defined($failed) && $failed eq $fingerprint && defined $self->last_reload_error) {
    my $err = $self->last_reload_error;
    $self->_record_reload_failure($err, $fingerprint);
    die $err;
  }

  my %before = map { $_ => $self->$_ } @CONFIG_STATE;
  my %pricing = %{$self->model_pricing || {}};
  my ($generation, $route_cache, $probe_key_cache, $rr_cursor)
    = ($self->_inventory_generation, $self->_route_cache, $self->_probe_key_cache, $self->_rr_cursor);

  my ($nodes_print, $declared, $notices);
  if (eval { ($nodes_print, $declared, $notices) = $self->_apply_config($cfg); 1 }) {
    $self->_forget_departed_nodes;
    $self->_config_fingerprint($fingerprint);
    $self->_nodes_fingerprint($nodes_print);
    $self->_config_declared($declared);
    $self->_clear_reload_failure;
    warn 'skeid: ' . $_ . "\n" for @$notices;
    return $cfg;
  }

  my $err = $@ || 'config reload failed';
  $self->_record_reload_failure($err, $fingerprint);
  for my $attr (@CONFIG_STATE) {
    next if $attr eq 'nodes';
    $self->$attr($before{$attr});
  }
  $self->model_pricing(\%pricing);
  # Setting nodes bumps the inventory generation. The old list comes back unchanged (the failed
  # load only built a new array), so its generation, derived caches and fairness cursors come back
  # with it: an inventory that did not change must not look changed, and a cache left keyed on a
  # generation number that is about to be reused would answer for a different list.
  if ($self->nodes != $before{nodes}) {
    $self->nodes($before{nodes});
    $self->_inventory_generation($generation);
    $self->_route_cache($route_cache);
    $self->_probe_key_cache($probe_key_cache);
    $self->_rr_cursor($rr_cursor);
  }
  die $err;
}

# A reload that drops a node drops what was known about it too, as remove_node does: its
# capacity reading and its failure history. Otherwise a node re-added later under the same id
# inherits a reading -- or errors -- about whatever machine the id used to point at. Run only
# after a reload succeeded, so a failed one that restores the old list loses nothing.
sub _forget_departed_nodes {
  my ($self) = @_;
  my %present = map { (($_->{id} // '') => 1) } @{$self->nodes};
  for my $store ($self->_capacity, $self->_failures) {
    delete $store->{$_} for grep { !$present{$_} } keys %$store;
  }
  return;
}

sub _record_reload_failure {
  my ($self, $err, $fingerprint) = @_;
  $self->last_reload_error("$err");
  $self->last_reload_error_at(time);
  $self->reload_failures(($self->reload_failures // 0) + 1);
  $self->_failed_fingerprint($fingerprint);
  return;
}

sub _clear_reload_failure {
  my ($self) = @_;
  $self->last_reload_error(undef);
  $self->last_reload_error_at(undef);
  $self->reload_failures(0);
  $self->_failed_fingerprint(undef);
  $self->_config_file_failed_mtime(undef);
  $self->_config_file_retry_at(undef);
  return;
}


sub reload_status {
  my ($self) = @_;
  my $err = $self->last_reload_error;
  return { ok => 1 } unless defined $err;
  (my $message = $err) =~ s/\s+\z//;
  return {
    ok        => 0,
    error     => $message,
    failed_at => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($self->last_reload_error_at // time)),
    failures  => 0 + ($self->reload_failures // 0),
  };
}

# Reads the config source: the loader's answer or the parsed file, plus its fingerprint. A
# loader may return ($config, $version); a defined version is the fingerprint, otherwise it is
# a digest of the structure (see _config_digest).
sub _read_config {
  my ($self) = @_;
  my $cfg = {};
  my $version;

  if ($self->has_config_loader) {
    # Counted from the start of the run, so the throttle also holds for a loader that dies.
    $self->_config_next_check_at($self->_now + (0 + ($self->config_reload_interval // 0)));
    my ($loaded, $loader_version) = $self->config_loader->($self);
    $cfg = $loaded if ref($loaded) eq 'HASH';
    $version = $loader_version;
  } elsif ($self->has_config_file) {
    my $file = $self->config_file;
    # A named config that is not there is an operator error, not an empty config: starting
    # with no nodes would answer every request 503 with nothing saying why (skeid k68). A file
    # that vanishes after a good load never gets here -- maybe_reload_config keeps the config.
    croak 'config file not found: ' . $file unless -f $file;
    # Record the version observed before parsing. The file may be atomically replaced after
    # load_file has read its bytes; recording a later stat would mark that unread replacement
    # as applied and prevent the next dispatch from loading it.
    my $read_mtime = (stat($file))[9];
    my $ypp = YAML::PP->new;
    my $loaded = $ypp->load_file($file);
    $cfg = $loaded if ref($loaded) eq 'HASH';
    $self->_config_mtime($read_mtime) if defined $read_mtime;
  }

  my $fingerprint = defined($version) && !ref($version)
    ? "version:$version"
    : 'digest:' . _config_digest($cfg);
  return ($cfg, $fingerprint);
}

# A canonical digest of a loaded config structure: hash keys sorted, so two loads of the same
# data digest alike whatever order the loader built them in. A code ref or an object other
# than a boolean digests by identity -- the same callback digests alike, a fresh closure per
# load counts as a change, which reloads rather than missing one.
sub _config_digest {
  my ($data) = @_;
  my $out = '';
  my $walk;
  $walk = sub {
    my ($node) = @_;
    if (!defined $node) {
      $out .= 'u;';
    } elsif (!ref $node) {
      $out .= 's' . length($node) . ':' . $node . ';';
    } elsif (blessed($node) && reftype($node) eq 'SCALAR') {
      # JSON / YAML booleans: their value is what counts, not which object carries it.
      $out .= 'b' . (${$node} ? 1 : 0) . ';';
    } elsif (!blessed($node) && reftype($node) eq 'HASH') {
      $out .= 'h{';
      for my $key (sort keys %$node) {
        $out .= 's' . length($key) . ':' . $key . ';';
        $walk->($node->{$key});
      }
      $out .= '}';
    } elsif (!blessed($node) && reftype($node) eq 'ARRAY') {
      $out .= 'a[';
      $walk->($_) for @$node;
      $out .= ']';
    } else {
      $out .= 'r' . reftype($node) . ':' . refaddr($node) . ';';
    }
  };
  $walk->($data);
  undef $walk;
  return sha256_hex($out);
}

# Applies a config to $self, section by section; reload_config undoes it on a croak. The usage
# store goes last and swaps only once the new store is prepared, so nothing after it can fail.
#
# A section the config declares replaces what is loaded: the file is the declared state. A
# section the previously applied config declared and this one does not goes back to what a
# restart with this config would give (skeid k65) -- except the usage store, see below. A
# section no applied config ever declared is left to whoever set it: nodes pushed through the
# admin API, prices set through pricing.set.
#
# Returns the fingerprint of the nodes section the node list now stands for (undef when the
# config declares none), the sections this config declares, and notices to log once it applied.
sub _apply_config {
  my ($self, $cfg) = @_;
  my $before = $self->_config_declared;
  my (%declared, @notices);

  if (exists $cfg->{pricing}) {
    $declared{pricing} = 1;
    # Replaced wholesale, not merged: a model removed from the section loses its price.
    $self->model_pricing({});
    my $pricing = ref($cfg->{pricing}) eq 'HASH' ? $cfg->{pricing} : {};
    for my $model (keys %$pricing) {
      my $p = $pricing->{$model};
      next unless ref($p) eq 'HASH';
      $self->set_model_pricing($model, $p);
    }
  } elsif ($before->{pricing}) {
    $self->model_pricing({});
  }

  if (grep { exists $cfg->{$_} } qw( policies default_policy names keys )) {
    $declared{policies} = 1;
    $self->_load_policies($cfg);
  } elsif ($before->{policies}) {
    $self->_load_policies({});
  }

  if (exists $cfg->{aliases}) {
    $declared{aliases} = 1;
    # Replaced wholesale, like nodes: the file is the declared state.
    $self->model_aliases({});
    my $aliases = ref($cfg->{aliases}) eq 'HASH' ? $cfg->{aliases} : {};
    for my $name (keys %$aliases) {
      $self->set_model_alias($name, $aliases->{$name});
    }
  } elsif ($before->{aliases}) {
    $self->model_aliases({});
  }

  my $nodes_print = $self->_nodes_fingerprint;
  if (exists $cfg->{nodes}) {
    $declared{nodes} = 1;
    my $nodes = ref($cfg->{nodes}) eq 'ARRAY' ? $cfg->{nodes} : [];
    # An unchanged nodes section keeps the node list as it is (skeid #38).
    my $print = _config_digest($nodes);
    if (!defined($nodes_print) || $print ne $nodes_print) {
      $self->nodes([]);
      for my $n (@$nodes) {
        next unless ref($n) eq 'HASH';
        next unless defined $n->{id} && defined $n->{url};
        $self->add_node(%$n);
      }
      $nodes_print = $print;
    }
  } elsif ($before->{nodes}) {
    $self->nodes([]);
    $nodes_print = undef;
  }

  my $routing = ref($cfg->{routing}) eq 'HASH' ? $cfg->{routing} : {};
  for my $key (sort keys %ROUTING_SETTINGS) {
    my ($attr, $convert) = @{ $ROUTING_SETTINGS{$key} };
    if (defined $routing->{$key}) {
      $declared{'routing.' . $key} = 1;
      $self->$attr($convert->($routing->{$key}));
    } elsif ($before->{'routing.' . $key}) {
      $self->$attr($self->_routing_baseline->{$attr});
    }
  }

  $self->_config_admin_api_key($self->_admin_api_key_from_config($cfg));
  $self->_apply_admin_api_key;

  $self->_load_registry($cfg);

  # Last: a key's manifest is checked against its routing policy and the aliases.
  $self->_load_manifest($cfg);

  # A changed usage store is swapped here, the new one prepared before the old one goes. A
  # removed one is not: the removal names no destination, so honouring it would stop recording
  # usage events -- billing data (ADR 0004) -- on a reload, silently. The running store stays
  # until a restart, and the reload says so once (skeid k65).
  my $usage_cfg = $cfg->{usage_store};
  if (ref($usage_cfg) eq 'HASH') {
    $declared{usage_store} = 1;
    $self->_configure_usage_store($usage_cfg);
  } elsif (exists $cfg->{usage_db_path}) {
    $declared{usage_store} = 1;
    $self->_configure_usage_store({
      backend     => 'sqlite',
      sqlite_path => $cfg->{usage_db_path},
    });
  } elsif ($before->{usage_store}) {
    my $backend = (ref($self->usage_store) eq 'HASH' && $self->usage_store->{backend}) || 'no';
    push @notices, 'usage_store was removed from the config; the running ' . $backend
      . ' store stays in force until restart (usage events are billing data, ADR 0004)';
  }

  return ($nodes_print, \%declared, \@notices);
}

# The admin API key a config names (skeid k64). It may be named directly or handed over by
# environment variable, the same way usage_store takes password_env -- a deployment should not
# have to write the key into a file that gets mounted into a container. The first spelling
# present decides, even when it is empty: a config may switch the admin API off. A config that
# names none leaves the key to SKEID_ADMIN_API_KEY.
sub _admin_api_key_from_config {
  my ($self, $cfg) = @_;
  my $admin = ref($cfg->{admin}) eq 'HASH' ? $cfg->{admin} : {};
  return exists($cfg->{admin_api_key})     ? ($cfg->{admin_api_key} // '') . ''
       : defined($cfg->{admin_api_key_env}) ? $ENV{$cfg->{admin_api_key_env}} // ''
       : exists($admin->{api_key})          ? ($admin->{api_key} // '') . ''
       : defined($admin->{api_key_env})     ? $ENV{$admin->{api_key_env}} // ''
       : $self->_env_admin_api_key;
}

# The admin API key in force: the explicit one, else the config's.
sub _apply_admin_api_key {
  my ($self) = @_;
  my $explicit = $self->_explicit_admin_api_key;
  $self->admin_api_key(length($explicit) ? $explicit : $self->_config_admin_api_key);
  return $self->admin_api_key;
}


sub set_admin_api_key {
  my ($self, $key) = @_;
  $self->_explicit_admin_api_key(defined($key) ? "$key" : '');
  return $self->_apply_admin_api_key;
}


# Longest wait between two retries of a failing config_loader, in seconds.
my $RELOAD_BACKOFF_MAX = 60;

sub maybe_reload_config {
  my ($self) = @_;

  if ($self->has_config_loader && !$self->has_config_file) {
    # Loader-based configs are dynamic, but not re-read more often than
    # config_reload_interval, and a load that reads what was already applied is a no-op.
    my $now  = $self->_now;
    my $next = $self->_config_next_check_at;
    return 0 if defined($next) && $now < $next;
    return $self->_reload_on_request;
  }

  return 0 unless $self->has_config_file;
  my $file = $self->config_file;
  unless (-f $file) {
    # Gone after a good load (a botched deploy, a volume that went away): the config in force
    # stays, as it would for a file that fails to parse -- but said once, not silently.
    warn 'skeid: config file ' . $file . " is gone, keeping the previous config\n"
      unless $self->_config_file_missing;
    $self->_config_file_missing(1);
    return 0;
  }
  $self->_config_file_missing(0);

  my $mtime = (stat($file))[9] || 0;
  my $last  = $self->_config_mtime;
  if (!defined($last) || $mtime > $last) {
    my $failed = $self->_config_file_failed_mtime;
    my $retry  = $self->_config_file_retry_at;
    return 0 if defined($failed) && $mtime == $failed
      && defined($retry) && $self->_now < $retry;
    return $self->_reload_on_request($mtime);
  }
  return 0;
}

# One retry schedule for loader and file failures. A file's next version bypasses this delay in
# maybe_reload_config; the delay applies only while the observed mtime is unchanged.
sub _reload_retry_delay {
  my ($self) = @_;
  my $failures = $self->reload_failures // 0;
  my $base     = 0 + ($self->config_reload_interval // 0);
  $base = 1 if $base < 1;
  my $delay = $base * 2 ** ($failures - 1);
  $delay = $RELOAD_BACKOFF_MAX if $delay > $RELOAD_BACKOFF_MAX;
  return $delay;
}

# A reload triggered by a request (skeid #39). Its failure is not the request's: the previous
# config is still fully in force, so the request is served under it. Failing it with a 500
# would take every request down until the config is fixed -- with a loader, every one.
sub _reload_on_request {
  my ($self, $file_mtime) = @_;
  my $before       = $self->_config_fingerprint // '';
  my $error_before = $self->last_reload_error;
  if (eval { $self->reload_config; 1 }) {
    return (($self->_config_fingerprint // '') ne $before) ? 1 : 0;
  }

  my $err = $@ || 'config reload failed';
  my $failures = $self->reload_failures // 0;
  if ($self->has_config_loader && $failures > 0) {
    $self->_config_next_check_at($self->_now + $self->_reload_retry_delay);
  } elsif (defined($file_mtime) && $failures > 0) {
    $self->_config_file_failed_mtime($file_mtime);
    $self->_config_file_retry_at($self->_now + $self->_reload_retry_delay);
  }
  # Logged when the reason is new; the same failure again, retry after retry, is not.
  if (!defined($error_before) || $error_before ne $err) {
    (my $msg = $err) =~ s/\s+\z//;
    warn "skeid: config reload failed, keeping the previous config: $msg\n";
  }
  return 0;
}

sub _now { Time::HiRes::time() }

# The client-facing faces Skeid serves, as manifest endpoints. Each face's spec -- dialect,
# path under public_url, and the capability flags its translator actually carries upstream --
# lives with that face's translator (ADR 0001: format-specific facts stay in the translator).
my %MANIFEST_FACES = (
  openai    => sub { Langertha::Skeid::Protocol->openai_manifest_endpoint },
  anthropic => sub { Langertha::Skeid::Protocol::Anthropic->manifest_endpoint },
  ollama    => sub { Langertha::Skeid::Protocol::Ollama->manifest_endpoint },
);
my @MANIFEST_FACE_ORDER = qw(openai anthropic ollama);
my $manifest_unavailable_warned;

sub _is_true {
  my ($value) = @_;
  return (defined($value) && "$value" =~ /^(1|true|yes|on)$/i) ? 1 : 0;
}

my %REGISTRY_KEYS = map { $_ => 1 } qw(enabled secret_env read_key_env ttl_s instance_id error_window_s);

# The registry section (ADR 0017). Absent means off, so removing the block disables publishing
# on the next reload. Enabled without a usable secret (set, at least MIN_SECRET_BYTES) or
# without any credential to read it (admin key or read key) is a load error: the route never
# answers unsigned, is unreadable without one of the two, and a config that asked for it should
# not load as if it had not.
sub _load_registry {
  my ($self, $cfg) = @_;
  my $section = $cfg->{registry};
  my ($enabled, $secret, $read_key, $ttl, $instance, $window) = (0, '', '', 10, undef, 60);

  if (defined $section) {
    croak 'registry must be a hashref' unless ref($section) eq 'HASH';
    for my $key (sort keys %$section) {
      croak "registry: unknown key '$key' (known: " . join(' ', sort keys %REGISTRY_KEYS)
        . '; the secret is named by secret_env, never written into the config)'
        unless $REGISTRY_KEYS{$key};
    }
    $enabled = _is_true($section->{enabled});

    if (defined $section->{ttl_s}) {
      croak 'registry.ttl_s must be a positive number of seconds'
        unless looks_like_number($section->{ttl_s}) && $section->{ttl_s} > 0;
      $ttl = 0 + $section->{ttl_s};
    }
    if (defined $section->{error_window_s}) {
      croak 'registry.error_window_s must be a positive number of seconds'
        unless looks_like_number($section->{error_window_s}) && $section->{error_window_s} > 0;
      $window = 0 + $section->{error_window_s};
    }
    if (defined $section->{instance_id}) {
      croak 'registry.instance_id must be a non-empty string'
        if ref($section->{instance_id}) || !length($section->{instance_id});
      $instance = "$section->{instance_id}";
    }

    if ($enabled) {
      my $env = $section->{secret_env};
      croak 'registry.secret_env is required when the registry is enabled: snapshots are '
        . 'signed, never published unsigned'
        unless defined($env) && !ref($env) && length($env);
      $secret = $ENV{$env} // '';
      croak "registry.secret_env names '$env', which is not set: snapshots are signed, never "
        . 'published unsigned'
        unless length $secret;
      require Langertha::Skeid::Registry;
      my $min = Langertha::Skeid::Registry->MIN_SECRET_BYTES;
      croak "registry.secret_env names '$env', which holds fewer than $min bytes: use a random "
        . "secret of at least $min bytes (e.g. openssl rand -hex 32)"
        if length($secret) < $min;
      # The read key opens the snapshot route and nothing else (skeid #49), so a fronting tier
      # need not hold the admin key. Named but empty is a mistake, not "no read key".
      if (defined $section->{read_key_env}) {
        my $read_env = $section->{read_key_env};
        croak 'registry.read_key_env must name an environment variable'
          if ref($read_env) || !length($read_env);
        $read_key = $ENV{$read_env} // '';
        croak "registry.read_key_env names '$read_env', which is not set"
          unless length $read_key;
      }
      # The fronting tier reads the snapshot with the read key or this Skeid's admin key.
      # Without either nobody can, and a registry nobody can read is a config mistake, not a
      # choice -- say so at load instead of answering 404 forever.
      croak 'registry.enabled needs a credential to read the snapshot: registry.read_key_env '
        . 'or an admin API key (admin.api_key or admin.api_key_env)'
        unless length($read_key) || length($self->admin_api_key // '');
    }
  }

  $self->registry_enabled($enabled);
  $self->registry_secret($secret);
  $self->registry_read_key($read_key);
  $self->registry_ttl_s($ttl);
  $self->registry_instance_id($instance);
  $self->registry_error_window_s($window);
  return 1;
}

# Resolves the manifest section and every key's manifest: grant once, at config load (ADR
# 0015). Nothing is published that a keys: entry does not list, and what is listed has to be
# something that key's routing policy lets it reach -- a contradiction is a load error, not a
# manifest that promises a model the request path then refuses with 403. Everything is built
# into lexicals and set together at the end; reload_config restores the old state on a croak.
sub _load_manifest {
  my ($self, $cfg) = @_;
  my ($enabled, $available, %manifests) = (0, 0);
  my $commit = sub {
    $self->manifest_enabled($enabled);
    $self->manifest_available($available);
    $self->key_manifests({%manifests});
    return 1;
  };

  my %grants;
  if (ref($cfg->{keys}) eq 'HASH') {
    for my $label (sort keys %{$cfg->{keys}}) {
      my $entry = $cfg->{keys}{$label};
      next unless ref($entry) eq 'HASH' && exists $entry->{manifest};
      my $grant = $entry->{manifest};
      croak "key '$label': manifest must be a hashref with a models list"
        unless ref($grant) eq 'HASH' && ref($grant->{models}) eq 'ARRAY';
      my (%seen, @models);
      for my $model (@{$grant->{models}}) {
        croak "key '$label': manifest models must be non-empty model names"
          unless defined($model) && !ref($model) && length($model);
        push @models, "$model" unless $seen{$model}++;
      }
      my $id = $self->key_names->{$label} // $label;
      $grants{$id} = { label => $label, models => \@models };
    }
  }

  my $section = $cfg->{manifest};
  return $commit->() unless defined $section;
  croak 'manifest must be a hashref' unless ref($section) eq 'HASH';
  return $commit->() unless _is_true($section->{enabled});

  my $public_url = $section->{public_url};
  croak 'manifest.public_url is required when the manifest is enabled: the URL clients reach '
    . 'Skeid at, never a node URL'
    unless defined($public_url) && !ref($public_url) && length($public_url);
  $public_url =~ s{/+\z}{};
  my ($issuer) = $public_url =~ m{\A([A-Za-z][A-Za-z0-9+.-]*://[^/?#]+)};
  croak "manifest.public_url must be an absolute http(s) URL, got '$public_url'" unless $issuer;

  my $provider_id = $section->{provider_id} // 'skeid';

  my @faces = @MANIFEST_FACE_ORDER;
  if (defined $section->{faces}) {
    croak 'manifest.faces must be a list' unless ref($section->{faces}) eq 'ARRAY';
    my %want;
    for my $face (@{$section->{faces}}) {
      croak "manifest.faces: unknown face '" . ($face // '') . "' (known: @MANIFEST_FACE_ORDER)"
        unless defined($face) && !ref($face) && $MANIFEST_FACES{$face};
      $want{$face} = 1;
    }
    @faces = grep { $want{$_} } @MANIFEST_FACE_ORDER;
    croak 'manifest.faces must name at least one face' unless @faces;
  }
  my %spec = map { $_ => $MANIFEST_FACES{$_}->() } @MANIFEST_FACE_ORDER;

  my $declared = $section->{capabilities} // {};
  croak 'manifest.capabilities must map model names to capability hashes'
    unless ref($declared) eq 'HASH' && !grep { ref($_) ne 'HASH' } values %$declared;

  $enabled = 1;

  # Core's manifest (Langertha::Manifest, ADR 0029) is newer than the released Langertha this
  # dist requires. Without it the route answers 404; the config is still loaded.
  unless (eval { require Langertha::Manifest::Builder; 1 }) {
    warn "skeid: manifest is enabled, but this Langertha has no Langertha::Manifest; "
      . "/.well-known/langertha.json answers 404\n"
      unless $manifest_unavailable_warned++;
    return $commit->();
  }

  # A claim no face of Skeid carries could never be published; saying so beats dropping it.
  my %allowed = map { $_ => 1 } Langertha::Manifest::Builder->model_capabilities;
  my %carried = map { $_ => 1 } map { @{$spec{$_}{capabilities}} } @MANIFEST_FACE_ORDER;
  for my $model (sort keys %$declared) {
    for my $flag (sort keys %{$declared->{$model}}) {
      croak "manifest.capabilities.$model: '$flag' is not a model capability a manifest may "
        . 'claim (see Langertha::Manifest::Builder->model_capabilities)'
        unless $allowed{$flag};
      croak "manifest.capabilities.$model: '$flag' is not carried by any face Skeid serves"
        unless $carried{$flag};
    }
  }

  for my $id (sort keys %grants) {
    my $grant = $grants{$id};
    for my $model (@{$grant->{models}}) {
      croak "key '$grant->{label}': manifest lists model '$model', which its routing policy "
        . 'does not let it reach'
        unless $self->_manifest_model_reachable($model, $id);
    }
    my $json = eval {
      my $builder = Langertha::Manifest::Builder->new(
        provider_id => $provider_id,
        issuer      => $issuer,
      );
      $builder->add_auth(id => 'api', type => 'api_key');
      for my $face (@faces) {
        my $face_spec = $spec{$face};
        my %face_carries = map { $_ => 1 } @{$face_spec->{capabilities}};
        $builder->add_endpoint(
          id       => $face,
          dialect  => $face_spec->{dialect},
          base_url => $public_url . $face_spec->{path},
          auth_ref => 'api',
        );
        for my $model (@{$grant->{models}}) {
          # Declared claims over the chat + streaming default, then cut to what this face's
          # translator carries: a claim holds "at that endpoint" (core ADR 0029) or not at all.
          my %caps = (chat => 1, streaming => 1);
          my $claims = $declared->{$model} || {};
          for my $flag (keys %$claims) {
            if (_is_true($claims->{$flag})) { $caps{$flag} = 1 } else { delete $caps{$flag} }
          }
          delete $caps{$_} for grep { !$face_carries{$_} } keys %caps;
          $builder->add_model(id => $model, endpoint_ref => $face, capabilities => \%caps);
        }
      }
      $builder->manifest->to_json;
    };
    unless (defined $json) {
      (my $err = $@) =~ s/\s+at \S+ line \d+\.?\s*\z//s;
      croak "key '$grant->{label}': manifest does not validate: $err";
    }
    $manifests{$id} = $json;
  }

  $available = 1;
  return $commit->();
}

# Whether the key could be routed to the model at all: its policy grants the name, and some
# node a permitted tier selects -- deny_tags applied, health ignored (a manifest is a claim,
# not a probe) -- serves it. A raw node model behind a denied tag is as unreachable as an alias
# the policy leaves out (ADR 0008), so it is not published either.
sub _manifest_model_reachable {
  my ($self, $model, $api_key_id) = @_;
  my $plan = $self->route_plan(model => $model, api_key_id => $api_key_id);
  return 0 unless $plan->{permitted};
  for my $tier (@{$plan->{tiers}}) {
    for my $node (@{$self->select_nodes(tags => $tier->{tags}, deny_tags => $tier->{deny_tags})}) {
      my $served = $node->{model};
      return 1 if !defined($served) || !length($served) || $served eq $tier->{model};
    }
  }
  return 0;
}


sub manifest_for_key {
  my ($self, $api_key_id) = @_;
  return undef unless $self->manifest_enabled && $self->manifest_available;
  my $id = $self->_configured_key_id($self->key_manifests, $api_key_id);
  return defined($id) ? $self->key_manifests->{$id} : undef;
}


sub configure_usage_store {
  my ($self, $cfg) = @_;
  return $self->_configure_usage_store($cfg);
}


sub _configure_usage_store {
  my ($self, $cfg) = @_;
  my $normalized = Langertha::Skeid::UsageStore->normalize_config(
    $cfg,
    default_sqlite_path => ($self->has_usage_db_path ? $self->usage_db_path : undef),
  );

  my $old = $self->usage_store || {};
  my $same = ref($old) eq 'HASH'
    && (($old->{backend} // '') eq ($normalized->{backend} // ''))
    && (($old->{dsn} // '') eq ($normalized->{dsn} // ''))
    && (($old->{path} // '') eq ($normalized->{path} // ''))
    && (($old->{mode} // '') eq ($normalized->{mode} // ''))
    && (($old->{user} // '') eq ($normalized->{user} // ''))
    && (($old->{password} // '') eq ($normalized->{password} // ''))
    && (($old->{schema_file} // '') eq ($normalized->{schema_file} // ''))
    && ((($old->{auto_migrate} // 1) ? 1 : 0) == (($normalized->{auto_migrate} // 1) ? 1 : 0))
    && (($old->{flush_interval_ms} // 0) == ($normalized->{flush_interval_ms} // 0));

  # Rebuild when the config changed, and also when there simply is no store object yet:
  # BUILD hands us the caller's raw config as $old, which can compare equal to its own
  # normalized form and would otherwise leave the store unbuilt.
  my $changed = $same ? 0 : 1;
  if ($changed || !$self->_usage_store_obj) {
    # Prepare the new store before letting go of the old one: a store that fails to come up
    # fails the reload with the old store still connected (reload_config is all or nothing).
    my $store = Langertha::Skeid::UsageStore->for_config($normalized);
    $store->prepare if $store;
    if ($store && $store->can('on_lost')) {
      weaken(my $weak = $self);
      $store->on_lost(sub { $weak->_usage_lost(@_) if $weak });
    }
    # The old store flushes what it still holds on the way out: those events were recorded
    # while it was the configured destination.
    $self->_disconnect_usage_store;
    $self->usage_store($normalized);
    $self->_usage_store_obj($store);
  }

  if ($normalized->{backend} eq 'sqlite') {
    $self->usage_db_path($normalized->{path});
  } elsif ($normalized->{backend} ne 'jsonlog') {
    $self->clear_usage_db_path if $self->has_usage_db_path;
  }

  return $self->usage_store;
}
sub _set_usage_db_path {
  my ($self, $path) = @_;
  return $self->_configure_usage_store({
    backend     => 'sqlite',
    sqlite_path => $path,
  });
}


sub _num {
  my ($v) = @_;
  return 0 unless defined $v;
  return 0 + $v;
}

sub _iso8601_now {
  return strftime('%Y-%m-%dT%H:%M:%SZ', gmtime());
}

sub _discover_engine_ids {
  my %ids = %FALLBACK_ENGINE_IDS;
  if (Langertha->can('available_engine_ids')) {
    my $found = eval { Langertha->available_engine_ids };
    if (!$@ && ref($found) eq 'ARRAY') {
      for my $id (@$found) {
        next unless defined $id && length $id;
        $ids{lc $id} = 1;
      }
    }
  }

  return \%ids;
}


sub supported_engine_ids {
  my ($self) = @_;
  my $ids = _discover_engine_ids();
  return [ sort keys %$ids ];
}


sub normalize_engine_id {
  my ($self, $value) = @_;
  return '' unless defined $value;

  my $raw = "$value";
  $raw =~ s/^\s+//;
  $raw =~ s/\s+$//;
  return '' unless length $raw;

  my $id = lc($raw);
  $id =~ s/\Alangertha::engine:://;
  $id =~ s/\Alangerthax::engine:://;

  my $ids = _discover_engine_ids();
  return $id if $ids->{$id};

  my $known = join(', ', sort keys %$ids);
  croak "unknown engine '$raw' (expected one of: $known)";
}


sub record_usage {
  my ($self, %args) = @_;

  # Disabled fast path: with no sink at all, the event has nowhere to go, so
  # skip building it. record_usage runs once per forwarded request, and a
  # deployment that meters nothing should not pay for a normalized event it is
  # only going to throw away in _store_usage_event. (karr #15)
  return { ok => 0, enabled => 0, error => 'usage_store not configured' }
    unless $self->_has_usage_sink;

  my $metrics = ref($args{metrics}) eq 'HASH' ? $args{metrics} : {};
  my $usage = ref($metrics->{usage}) eq 'HASH' ? $metrics->{usage} : {};
  my $tool_calls = ref($metrics->{tool_names}) eq 'ARRAY'
    ? scalar(@{$metrics->{tool_names}})
    : _num($metrics->{tool_calls});
  my $input_tokens  = _num($usage->{input}) || _num($usage->{prompt_tokens}) || _num($metrics->{input_tokens});
  my $output_tokens = _num($usage->{output}) || _num($usage->{completion_tokens}) || _num($metrics->{output_tokens});
  my $total_tokens  = _num($usage->{total}) || _num($metrics->{total_tokens}) || ($input_tokens + $output_tokens);
  # Prompt-cache read count (k27). Read the same way as the token counts above: the normalized
  # name first, then the OpenAI wire spelling (nested under prompt_tokens_details on a real
  # OpenAI usage payload), then a flat cached_tokens some compatible servers use, then the
  # flattened metrics fallback. Pricing it is metrics.normalize's job (skeid #28): the cost
  # fields below arrive already priced.
  my $cached_tokens = _num($usage->{cached})
    || _num($usage->{cached_tokens})
    || _num(ref($usage->{prompt_tokens_details}) eq 'HASH' ? $usage->{prompt_tokens_details}{cached_tokens} : undef)
    || _num($metrics->{cached_tokens});
  # Prompt-cache write count (skeid #41), the count cost_cache_write_usd was priced from: the
  # normalized name, then the flat metrics value metrics.normalize or the proxy put there.
  my $cache_write_tokens = _num($usage->{cache_write})
    || _num($usage->{cache_write_tokens})
    || _num($metrics->{cache_write_tokens});
  my $cost_input    = _num($metrics->{cost_input_usd}) || _num($metrics->{input_cost_usd});
  my $cost_output   = _num($metrics->{cost_output_usd}) || _num($metrics->{output_cost_usd});
  my $cost_total    = _num($metrics->{cost_total_usd}) || _num($metrics->{total_cost_usd});
  # Prompt-cache amounts (skeid #28), already part of cost_total. 0 when the rule had no cache
  # rate or the installed Langertha cannot price them -- the cached tokens are then in cost_input.
  my $cost_cache_read  = _num($metrics->{cost_cache_read_usd})  || _num($metrics->{cache_read_cost_usd});
  my $cost_cache_write = _num($metrics->{cost_cache_write_usd}) || _num($metrics->{cache_write_cost_usd});

  my %event = (
    created_at    => ($args{created_at} // _iso8601_now()),
    request_id    => ($args{request_id} // ''),
    api_format    => ($args{api_format} // ''),
    endpoint      => ($args{endpoint} // ''),
    api_key_id    => ($args{api_key_id} // ''),
    provider      => ($args{provider} // ''),
    engine        => ($args{engine} // ''),
    model         => ($args{model} // ''),
    requested_model => ($args{requested_model} // $args{model} // ''),
    node_id       => ($args{node_id} // ''),
    route_url     => ($args{route_url} // ''),
    status_code   => (_num($args{status_code}) || 0),
    ok            => ($args{ok} ? 1 : 0),
    duration_ms   => (_num($args{duration_ms}) || 0),
    input_tokens  => $input_tokens,
    output_tokens => $output_tokens,
    total_tokens  => $total_tokens,
    cached_tokens => $cached_tokens,
    cache_write_tokens => $cache_write_tokens,
    tool_calls    => _num($tool_calls),
    cost_input_usd  => $cost_input,
    cost_output_usd => $cost_output,
    cost_total_usd  => $cost_total,
    cost_cache_read_usd  => $cost_cache_read,
    cost_cache_write_usd => $cost_cache_write,
    error_type    => ($args{error_type} // ''),
    error_message => ($args{error_message} // ''),
  );
  # UTF-8 bytes of the content a streamed request relayed (skeid #36). Optional and additive: a
  # non-streamed event has no such key, which a store records as "not measured". An observation
  # beside the token counts -- never used to estimate or replace them.
  $event{content_bytes} = _num($args{content_bytes}) if defined $args{content_bytes};

  return $self->_store_usage_event(\%event);
}

sub _store_usage_event {
  my ($self, $event) = @_;
  return $self->store_usage_event->($self, $event) if $self->has_store_usage_event;
  my $store = $self->_usage_store_obj;
  return { ok => 0, enabled => 0, error => 'usage_store not configured' } unless $store;
  return $store->store($event);
}

# A queued event the store could not write (skeid k78): through on_usage_lost when the
# embedding application -- the proxy -- set it, else a warning. Never the DSN, never a key.
sub _usage_lost {
  my ($self, $event, $err) = @_;
  return $self->on_usage_lost->($self, $event, $err) if $self->has_on_usage_lost;
  my $cfg = $self->usage_store;
  warn 'skeid: usage event lost: request_id=' . ($event->{request_id} // '')
    . ' store=' . ((ref($cfg) eq 'HASH' && $cfg->{backend}) || 'custom')
    . ' api_key_id=' . ($event->{api_key_id} // '')
    . ' model=' . ($event->{model} // '')
    . ' status=' . ($event->{status_code} // 0)
    . ': ' . ($err // 'unknown error') . "\n";
  return;
}


sub flush_usage {
  my ($self) = @_;
  my $store = $self->_usage_store_obj;
  return { ok => 1, written => 0 } unless $store && $store->can('flush');
  return $store->flush;
}

# True when a usage event has somewhere to go: a store_usage_event callback, a
# configured usage store object, or a subclass that overrides _store_usage_event
# (documented in README, exercised by t/14) -- the last is why this cannot be a
# plain attribute check. record_usage consults this before building an event.
sub _has_usage_sink {
  my ($self) = @_;
  return 1 if $self->has_store_usage_event;
  return 1 if $self->_usage_store_obj;
  my $impl = $self->can('_store_usage_event');
  return 1 if $impl && $impl != \&_store_usage_event;
  return 0;
}


sub usage_report {
  my ($self, %args) = @_;

  my $limit = _num($args{limit});
  $limit = 20 if $limit < 1;
  $limit = 500 if $limit > 500;

  my %filters;
  $filters{since}      = $args{since}      if defined $args{since}      && length $args{since};
  $filters{api_key_id} = $args{api_key_id} if defined $args{api_key_id} && length $args{api_key_id};
  $filters{model}      = $args{model}      if defined $args{model}      && length $args{model};
  $filters{limit}      = $limit;

  return $self->_query_usage_report(\%filters);
}

sub _query_usage_report {
  my ($self, $filters) = @_;
  return $self->query_usage_report->($self, $filters) if $self->has_query_usage_report;
  my $store = $self->_usage_store_obj;
  return { ok => 0, enabled => 0, error => 'usage_store not configured' } unless $store;
  return $store->report($filters);
}
sub _usage_object {
  my ($self, %args) = @_;
  return Langertha::Usage->from_hash($args{usage}) if ref($args{usage}) eq 'HASH';
  return $args{usage} if ref($args{usage}) && $args{usage}->isa('Langertha::Usage');
  return Langertha::Usage->from_response($args{response});
}


sub estimate_cost {
  my ($self, %args) = @_;
  my $model = $args{model} // '';
  my $usage = $self->_usage_object(%args);
  my $rule  = $args{pricing} || $self->pricing_for_model($model);
  my $pricing = Langertha::Pricing->new( default_rule => $rule );
  return $pricing->cost_for( $usage, undef )->to_hash;
}


sub normalize_metrics {
  my ($self, %args) = @_;
  my $model = $args{model} // '';
  my $usage = $self->_usage_object(%args);
  my $rule  = $args{pricing} || $self->pricing_for_model($model);
  my $pricing = Langertha::Pricing->new( default_rule => $rule );
  my $cost = $pricing->cost_for( $usage, undef );

  my @names;
  for my $tc ( @{ $args{tool_calls} || [] } ) {
    next unless ref($tc) eq 'HASH';
    my $n = $tc->{name} // ( ref( $tc->{function} ) eq 'HASH' ? $tc->{function}{name} : undef );
    push @names, $n if defined $n && length $n;
  }

  my $record = Langertha::UsageRecord->new(
    usage           => $usage,
    cost            => $cost,
    provider        => $args{provider},
    engine          => $args{engine},
    model           => $model,
    route           => $args{route},
    duration_ms     => $args{duration_ms},
    started_at      => $args{started_at},
    finished_at     => $args{finished_at},
    tool_calls      => scalar(@names),
    tool_names      => \@names,
    pricing_version => $args{pricing_version},
  );
  my $normalized = $record->to_hash;
  # The cache read count as the Usage read it, from whichever wire spelling the upstream used
  # (skeid #28) -- so the event's cached_tokens is the count its cache cost was priced from.
  # Langertha 0.503's Usage has no such count; there the caller reads it off the raw payload.
  if ($usage->can('cached_tokens') && defined(my $cached = $usage->cached_tokens)) {
    $normalized->{cached_tokens} = $cached;
  }
  # Likewise the cache write count, the one cost_cache_write_usd was priced from (skeid #41).
  if ($usage->can('cache_write_tokens') && defined(my $written = $usage->cache_write_tokens)) {
    $normalized->{cache_write_tokens} = $written;
  }
  return $normalized;
}

sub _route_key {
  my ($self, %args) = @_;
  my $model  = $args{model}  // '';
  my $engine = $self->normalize_engine_id($args{engine} // '');
  my $tags   = join(',', @{$self->normalize_tags($args{tags})});
  my $deny   = join(',', @{$self->normalize_tags($args{deny_tags})});
  # Tags belong in the key: two selections over the same model address different node sets, and
  # a shared round-robin cursor across different-sized sets picks the wrong node. Denied tags
  # too -- a key that may not use cloud addresses a smaller set than one that may.
  return join('|', $model, $engine, $tags, ($deny ? "-$deny" : ())) if length($tags) || length($deny);
  return join('|', $model, $engine);
}

sub _node_can_take {
  my ($self, $node) = @_;
  return 0 unless ref($node) eq 'HASH';
  return 0 unless ($node->{healthy} // 0);
  my $id = $node->{id} // '';
  return 0 unless length $id;

  # Both have to agree, and they are not symmetric: max_conns is this process's own guardrail
  # and always applies, while a probe may only narrow what it allows. A probe that could widen
  # it would turn a stale or broken reading into an overload -- and for a rented node,
  # max_conns is a spend limit, not a capacity estimate (ADR 0009).
  return 0 unless $self->_inflight_allows($node);
  return 0 unless $self->_capacity_allows($id);
  return 1;
}

sub _inflight_allows {
  my ($self, $node) = @_;
  my $max = $self->worker_max_conns($node);
  return 1 if $max <= 0;
  return (0 + ($self->_inflight->{$node->{id} // ''} // 0)) < $max ? 1 : 0;
}


sub worker_max_conns {
  my ($self, $node) = @_;
  my $max = 0 + ((ref($node) eq 'HASH' ? $node->{max_conns} : $node) // 0);
  return 0 if $max <= 0;

  my $divisor = $self->_admission_divisor;
  return $max if $divisor <= 1;

  my $share = int($max / $divisor);
  return $share > 0 ? $share : 1;
}

# How many processes across the whole deployment share one node's max_conns: the prefork workers
# of this process (worker_count) times the separate Skeid frontends in front of the node
# (frontend_count). max_conns is partitioned across frontends first and then across workers, but
# integer division composes -- floor(floor(max/F)/N) == floor(max/(F*N)) -- so the product is
# the only number admission needs (ADR 0012).
sub _admission_divisor {
  my ($self) = @_;
  my $workers   = 0 + ($self->worker_count   // 1);
  my $frontends = 0 + ($self->frontend_count // 1);
  $workers   = 1 if $workers   < 1;
  $frontends = 1 if $frontends < 1;
  return $workers * $frontends;
}


sub worker_share_warnings {
  my ($self) = @_;
  my $workers   = 0 + ($self->worker_count   // 1);
  my $frontends = 0 + ($self->frontend_count // 1);
  $workers   = 1 if $workers   < 1;
  $frontends = 1 if $frontends < 1;
  my $divisor = $workers * $frontends;
  return [] if $divisor <= 1;

  # Name the axes that are actually in play, and the matching fix: the operator can only shed
  # what they configured. With both dividing, "worker" alone would misname where the surplus
  # comes from.
  my ($split, $fix);
  if ($frontends > 1 && $workers > 1) {
    $split = sprintf('%d frontends x %d workers = %d processes', $frontends, $workers, $divisor);
    $fix   = 'fewer frontends or workers, or raise max_conns';
  } elsif ($frontends > 1) {
    $split = sprintf('%d frontends', $frontends);
    $fix   = 'fewer frontends or raise max_conns';
  } else {
    $split = sprintf('%d workers', $workers);
    $fix   = 'fewer workers or raise max_conns';
  }

  my @warnings;
  for my $node (@{$self->nodes}) {
    my $max = 0 + ($node->{max_conns} // 0);
    next if $max <= 0;
    next if $max >= $divisor;
    push @warnings, sprintf(
      "node '%s': max_conns %d cannot be split across %s; each process will admit 1, "
      . "so the node may see up to %d concurrent requests. Use %s.",
      ($node->{id} // '?'), $max, $split, $divisor, $fix,
    );
  }
  return \@warnings;
}

# What a probe says about a node, if anything current. Unknown is a valid answer and means
# "inflight decides" -- which is the entire behaviour of a deployment that configures no probes.
sub _capacity_allows {
  my ($self, $node_id) = @_;
  my $reading = $self->capacity_reading($node_id) or return 1;

  # A provider that told us to come back later is not busy in the inflight sense: no request of
  # ours is outstanding, and admitting one would just buy another 429.
  return 0 if $reading->{retry_after} && time < $reading->{retry_after};

  my $limit = 0 + ($reading->{limit} // 0);
  return 1 if $limit <= 0;
  return (0 + ($reading->{used} // 0)) < $limit ? 1 : 0;
}

sub _node_has_tags {
  my ($self, $node, $tags) = @_;
  return 1 unless $tags && @$tags;
  my %have = map { $_ => 1 } @{$node->{tags} || []};
  for my $tag (@$tags) {
    return 0 unless $have{$tag};
  }
  return 1;
}

# The deny side is ANY, not ALL: one forbidden tag on a node is enough to rule it out. A policy
# that denies "cloud" must exclude a node tagged [cloud, groq] without having to name groq too.
sub _node_has_any_tag {
  my ($self, $node, $tags) = @_;
  return 0 unless $tags && @$tags;
  my %have = map { $_ => 1 } @{$node->{tags} || []};
  for my $tag (@$tags) {
    return 1 if $have{$tag};
  }
  return 0;
}

# The selection cache includes negative requested models, and requested models are client input.
# Keep a small fixed working set rather than turning every spelling ever seen into process-lifetime
# state. FIFO makes eviction deterministic; an evicted route's cursor is removed with it, so that
# route restarts weighted fairness if it is requested again.
my $ROUTE_CACHE_MAX_ENTRIES = 256;

# Everything derived from the inventory -- which nodes are eligible, their round-robin order
# and their weights -- is computed once per selection and reused until the inventory changes.
# Only admission stays per request, because inflight is the one part that moves between two
# requests to the same selection.
sub _route_entry {
  my ($self, %args) = @_;
  my $cache = $self->_route_cache;
  if (($cache->{generation} // -1) != $self->_inventory_generation) {
    $cache = { generation => $self->_inventory_generation, entries => {}, order => [] };
    $self->_route_cache($cache);
  }

  my $key = $self->_route_key(%args);
  my $entry = $cache->{entries}{$key};
  return $entry if $entry;

  my $model  = $args{model};
  my $engine = $self->normalize_engine_id($args{engine} // '');
  my $tags   = $self->normalize_tags($args{tags});
  my $deny   = $self->normalize_tags($args{deny_tags});

  my @nodes = grep {
    (!defined($model) || !length($model) || !defined($_->{model}) || !length($_->{model}) || $_->{model} eq $model)
      && (!defined($engine) || !length($engine) || !defined($_->{engine}) || !length($_->{engine}) || $_->{engine} eq $engine)
      && (($_->{healthy} // 0) ? 1 : 0)
      && $self->_node_has_tags($_, $tags)
      && !$self->_node_has_any_tag($_, $deny)
  } @{$self->nodes || []};

  @nodes = sort { ($a->{id} // '') cmp ($b->{id} // '') } @nodes;
  my @weights = map {
    my $w = 0 + ($_->{weight} // 1);
    $w = 1 if $w < 1;
    int($w);
  } @nodes;
  my $total_weight = 0;
  $total_weight += $_ for @weights;

  my $new_entry = {
    nodes        => \@nodes,
    weights      => \@weights,
    total_weight => $total_weight,
  };

  my $order = $cache->{order} ||= [];
  while (@$order >= $ROUTE_CACHE_MAX_ENTRIES) {
    my $evicted = shift @$order;
    next unless exists $cache->{entries}{$evicted};
    delete $cache->{entries}{$evicted};
    # The cursor tracks ranges stored by this entry. Keeping it would defeat the bound and would
    # resume at stale fairness state if this route key later re-enters the working set.
    delete $self->_rr_cursor->{$evicted};
  }
  $cache->{entries}{$key} = $new_entry;
  push @$order, $key;
  return $new_entry;
}

# Returns the live node hashrefs, not copies. Callers read them and must not mutate them --
# pick_node builds its own hash for the node it returns.
sub _eligible_nodes {
  my ($self, %args) = @_;
  return $self->_route_entry(%args)->{nodes};
}


sub set_model_alias {
  my ($self, $name, $spec) = @_;
  croak 'alias name required' unless defined $name && length $name;

  my $tiers = ref($spec) eq 'ARRAY' ? $spec
            : ref($spec) eq 'HASH'  ? $spec->{tiers}
            : croak "alias '$name': must be a hashref with tiers, or an arrayref of tiers";
  croak "alias '$name': tiers must be an arrayref" unless ref($tiers) eq 'ARRAY';
  croak "alias '$name': needs at least one tier" unless @$tiers;

  my @normalized;
  for my $tier (@$tiers) {
    croak "alias '$name': each tier must be a hashref" unless ref($tier) eq 'HASH';
    push @normalized, {
      tags    => $self->normalize_tags($tier->{tags}),
      model   => ((defined($tier->{model}) && length($tier->{model})) ? "$tier->{model}" : $name),
      engine  => $self->normalize_engine_id($tier->{engine} // ''),
      wait_ms => (defined($tier->{wait_ms}) && $tier->{wait_ms} > 0 ? 0 + $tier->{wait_ms} : 0),
    };
  }

  $self->model_aliases->{$name} = { tiers => \@normalized };
  return 1;
}


sub set_policy {
  my ($self, $name, $spec) = @_;
  croak 'policy name required' unless defined $name && length $name;
  $self->policies->{$name} = $self->resolve_policy($spec, $name);
  return 1;
}


sub resolve_policy {
  my ($self, $spec, $name) = @_;
  $spec = {} unless ref($spec) eq 'HASH';

  my $allow = $spec->{models} // $spec->{aliases};
  my $allow_models;
  if (defined $allow) {
    my @list = ref($allow) eq 'ARRAY' ? @$allow : split(/[,\s]+/, "$allow");
    @list = grep { defined && length } @list;
    # An explicit '*' is the same as saying nothing, and saying it out loud reads better in a
    # config than an absent key.
    $allow_models = (grep { $_ eq '*' } @list) ? undef : { map { $_ => 1 } @list };
  }

  return {
    name         => ($name // $spec->{name} // ''),
    allow_models => $allow_models,
    deny_tags    => $self->normalize_tags($spec->{deny_tags}),
  };
}

# Key ids before ADR 0016 were the first 12 hex digits of the same digest, so a short id is
# the prefix of the full id of the same key.
my $LEGACY_KEY_ID_HEX = 12;
my %legacy_key_id_warned;

# Resolves the whole policy section once, at config load. Nothing here happens per request:
# a request costs one hash lookup, and identical resolutions share a single object, so a
# thousand keys on three profiles are three policy objects and a thousand pointers.
sub _load_policies {
  my ($self, $cfg) = @_;

  my %policies;
  if (ref($cfg->{policies}) eq 'HASH') {
    for my $name (keys %{$cfg->{policies}}) {
      $policies{$name} = $self->resolve_policy($cfg->{policies}{$name}, $name);
    }
  }

  my %interned = map { $self->_policy_fingerprint($_) => $_ } values %policies;
  my $intern = sub {
    my ($policy) = @_;
    my $print = $self->_policy_fingerprint($policy);
    return $interned{$print} ||= $policy;
  };

  my $default;
  if (defined $cfg->{default_policy} && length $cfg->{default_policy}) {
    $default = $policies{$cfg->{default_policy}};
    croak "default_policy '$cfg->{default_policy}' is not defined in policies" unless $default;
  }

  # names: is a readable-name -> key-id registry that lives in the config, resolved to key ids
  # here and never consulted on the request path (karr #17, ADR 0008). A value must be an id
  # from `skeid keyid`, never a customer key -- the config still holds no keys. With it, a
  # keys: entry may be written by name, and rotating a customer's key is a one-line edit here
  # rather than a rewrite of every policy line that named them by id.
  my %key_names;
  if (ref($cfg->{names}) eq 'HASH') {
    for my $name (keys %{$cfg->{names}}) {
      my $id = $cfg->{names}{$name};
      croak "name '$name' must map to a key id string, not a structure" if ref $id;
      croak "name '$name' maps to an empty key id" unless defined($id) && length($id);
      $key_names{$name} = $id;
    }
  }

  # Resolve a keys: entry's label through the names registry, if it is a known name; otherwise
  # it is taken to be a key id already. Two labels resolving to the same id is a config error,
  # not a silent last-wins -- it usually means a name and its own id were both listed.
  my %seen_id;
  my $resolve_key_id = sub {
    my ($label) = @_;
    my $id = exists $key_names{$label} ? $key_names{$label} : $label;
    croak "keys entry '$label' resolves to key id '$id', which another entry already claims"
      if $seen_id{$id}++;
    return $id;
  };

  my %key_policies;
  if (ref($cfg->{keys}) eq 'HASH') {
    for my $label (keys %{$cfg->{keys}}) {
      my $key   = $resolve_key_id->($label);
      my $entry = $cfg->{keys}{$label};

      if (!ref($entry)) {
        my $policy = $policies{$entry};
        croak "key '$label' references undefined policy '$entry'" unless $policy;
        $key_policies{$key} = $policy;
        next;
      }

      croak "key '$label' must be a policy name or a hashref" unless ref($entry) eq 'HASH';

      my $base = {};
      if (defined $entry->{policy} && length $entry->{policy}) {
        my $named = $policies{$entry->{policy}};
        croak "key '$label' references undefined policy '$entry->{policy}'" unless $named;
        $base = $named;
      } elsif ($default) {
        $base = $default;
      }

      # Overrides are sparse: an absent field keeps the profile's value, so "same as standard
      # but allowed to use cloud" is one line rather than a restated profile.
      my $overrides = ref($entry->{overrides}) eq 'HASH' ? $entry->{overrides} : $entry;
      my $merged = {
        name         => ($base->{name} // ''),
        allow_models => (exists($overrides->{models}) || exists($overrides->{aliases})
                          ? $self->resolve_policy($overrides)->{allow_models}
                          : $base->{allow_models}),
        deny_tags    => (exists($overrides->{deny_tags})
                          ? $self->normalize_tags($overrides->{deny_tags})
                          : ($base->{deny_tags} // [])),
      };
      $key_policies{$key} = $intern->($merged);
    }
  }

  # Short key ids from before ADR 0016 still name their customer: a request's full id falls
  # back to its short prefix (see _configured_key_id). Where one key would match two entries --
  # a short id and a full id it is the prefix of -- which one governs is not for Skeid to guess.
  my %legacy = map { $_ => 1 } grep { _is_legacy_key_id($_) } keys %seen_id;
  for my $id (sort keys %seen_id) {
    next unless $id =~ /\Ak_[0-9a-f]{40}\z/;
    my $short = substr($id, 0, 2 + $LEGACY_KEY_ID_HEX);
    croak "key id '$short' is the short form of '$id', and both have a keys entry: one key "
      . 'would match both; keep only the full id'
      if $legacy{$short};
  }
  _warn_legacy_key_id($_) for sort(keys %legacy), grep { _is_legacy_key_id($_) } values %key_names;

  $self->policies(\%policies);
  $self->default_policy($default);
  $self->key_policies(\%key_policies);
  $self->key_names(\%key_names);
  return 1;
}

sub _is_legacy_key_id {
  my ($id) = @_;
  return defined($id) && $id =~ /\Ak_[0-9a-f]{$LEGACY_KEY_ID_HEX}\z/ ? 1 : 0;
}

sub _warn_legacy_key_id {
  my ($id) = @_;
  return if $legacy_key_id_warned{$id}++;
  warn "skeid: key id '$id' is a short key id from before ADR 0016; it still matches the key "
    . "whose full id starts with it, but is deprecated: replace it with the full id "
    . "`skeid keyid` prints\n";
  return;
}

# The id a customer's entry in a config table is filed under: the request's own id, or -- for
# a config still written with short ids -- that id's short prefix. Exact wins, so a full id
# entry is always what a full id finds.
sub _configured_key_id {
  my ($self, $table, $api_key_id) = @_;
  return undef unless defined($api_key_id) && length($api_key_id);
  return $api_key_id if exists $table->{$api_key_id};
  return undef unless $api_key_id =~ /\Ak_[0-9a-f]{40}\z/;
  my $short = substr($api_key_id, 0, 2 + $LEGACY_KEY_ID_HEX);
  return exists $table->{$short} ? $short : undef;
}

sub _policy_fingerprint {
  my ($self, $policy) = @_;
  my $models = defined($policy->{allow_models}) ? join(',', sort keys %{$policy->{allow_models}}) : '*';
  return join("\0", $models, join(',', @{$policy->{deny_tags}}));
}


sub key_id_for_key {
  my ($self, $api_key) = @_;
  return 'anonymous' unless defined($api_key) && length($api_key);
  return 'k_' . sha1_hex($api_key);
}


sub policy_for_key {
  my ($self, $api_key_id) = @_;
  my $id = $self->_configured_key_id($self->key_policies, $api_key_id);
  return $self->key_policies->{$id} if defined($id) && $self->key_policies->{$id};
  return $self->default_policy;
}


sub key_id_for_name {
  my ($self, $name) = @_;
  return undef unless defined($name) && length($name);
  return $self->key_names->{$name};
}


sub route_plan {
  my ($self, %args) = @_;
  my $model  = $args{model} // '';
  my $policy = $self->policy_for_key($args{api_key_id});
  my $deny   = $policy ? $policy->{deny_tags} : [];

  if ($policy && $policy->{allow_models} && !$policy->{allow_models}{$model}) {
    return { tiers => [], permitted => 0, reason => 'model_not_permitted' };
  }

  my $alias = $self->model_aliases->{$model};
  my @tiers = $alias
    ? (map { +{ %$_, deny_tags => $deny } } @{$alias->{tiers}})
    : ({
        tags      => [],
        model     => $model,
        engine    => $self->normalize_engine_id($args{engine} // ''),
        wait_ms   => 0 + ($self->route_wait_timeout_ms // 0),
        deny_tags => $deny,
      });

  my $before = scalar @tiers;
  if (@$deny) {
    my %denied = map { $_ => 1 } @$deny;
    @tiers = grep {
      my $tier = $_;
      !grep { $denied{$_} } @{$tier->{tags} || []};
    } @tiers;
  }

  return { tiers => [], permitted => 0, reason => 'all_tiers_denied' }
    if $before && !@tiers;

  return { tiers => \@tiers, permitted => 1, reason => '' };
}


sub select_nodes {
  my ($self, %args) = @_;
  my $tags = $self->normalize_tags($args{tags});
  my $deny = $self->normalize_tags($args{deny_tags});
  return [
    map { +{%$_} }
    grep { $self->_node_has_tags($_, $tags) && !$self->_node_has_any_tag($_, $deny) }
    @{$self->nodes || []}
  ];
}


sub pick_node {
  my ($self, %args) = @_;
  my $entry = $self->_route_entry(%args);
  my @nodes = @{$entry->{nodes}};
  return unless @nodes;

  my @weights = @{$entry->{weights}};
  my $total_weight = $entry->{total_weight};
  return unless $total_weight > 0;

  my $key = $self->_route_key(%args);
  my $cursor = 0 + ($self->_rr_cursor->{$key} // 0);
  $cursor %= $total_weight;

  # Locate the weighted range containing the cursor without expanding weights into slots. From
  # that owner onward, the old slot walk considered nodes in inventory order and, if none admitted
  # before the end, wrapped to target zero. Admission is one per-node observation for this
  # synchronous selection pass; resampling it once per weight slot describes no new capacity.
  # Check each node once and skip the rest of every saturated weight range.
  my ($owner, $range_end) = (0, 0);
  for my $idx (0 .. $#nodes) {
    $range_end += $weights[$idx];
    if ($cursor < $range_end) {
      $owner = $idx;
      last;
    }
  }

  for my $offset (0 .. $#nodes) {
    my $idx = ($owner + $offset) % @nodes;
    my $candidate = $nodes[$idx];
    next unless $self->_node_can_take($candidate);

    # Before a wrap, the historical cursor advances one weighted slot even when a later node was
    # selected because the owning range was saturated. After a wrap, the first target examined is
    # slot zero, so its successor is slot one. Keeping both cases preserves partial-saturation
    # ordering while avoiding one admission check per skipped slot.
    $self->_rr_cursor->{$key} = $idx < $owner
      ? (1 % $total_weight)
      : (($cursor + 1) % $total_weight);
    my $id = $candidate->{id};
    my $inflight = 0 + ($self->_inflight->{$id} // 0);
    return {
      %$candidate,
      inflight => $inflight,
      route_key => $key,
    };
  }

  return;
}


sub route_state {
  my ($self, %args) = @_;
  my $engine = $self->normalize_engine_id($args{engine} // '');
  my $eligible = $self->_eligible_nodes(%args);
  my $available = [ grep { $self->_node_can_take($_) } @$eligible ];

  return {
    model          => ($args{model} // ''),
    engine         => $engine,
    tags           => $self->normalize_tags($args{tags}),
    deny_tags      => $self->normalize_tags($args{deny_tags}),
    eligible_count => scalar(@$eligible),
    available_count => scalar(@$available),
    has_eligible   => @$eligible ? 1 : 0,
    has_available  => @$available ? 1 : 0,
  };
}


sub set_capacity_reading {
  my ($self, $node_id, %reading) = @_;
  croak 'node_id required' unless defined $node_id && length $node_id;

  my $now = time;
  my $entry = {
    source => ((defined($reading{source}) && length($reading{source})) ? "$reading{source}" : 'custom'),
    used   => (defined $reading{used}  ? 0 + $reading{used}  : undef),
    limit  => (defined $reading{limit} ? 0 + $reading{limit} : undef),
    at     => (defined $reading{at}    ? 0 + $reading{at}    : $now),
    # Which of a provider's several quotas this reading is about, when it had more than one.
    # For reports only -- admission just sees used and limit.
    (defined $reading{quota} ? (quota => "$reading{quota}") : ()),
    (defined $reading{expires_at} ? (expires_at => 0 + $reading{expires_at}) : ()),
    # How often this source reports; it sets how long this reading holds a looser one off.
    ((defined($reading{interval_ms}) && $reading{interval_ms} > 0)
      ? (interval_ms => 0 + $reading{interval_ms}) : ()),
  };

  if (defined $reading{retry_after_ms} && $reading{retry_after_ms} > 0) {
    $entry->{retry_after} = $now + ($reading{retry_after_ms} / 1000);
  } elsif (defined $reading{retry_after}) {
    $entry->{retry_after} = 0 + $reading{retry_after};
  }

  # Two sources disagreeing about one node: the tighter one decides while it is current.
  # Taking the latest instead would let whichever probe polls last lift what the other just
  # said. But "tighter" alone lets a reading nobody refreshes -- a passive rate-limit reading
  # from the last response before traffic stopped -- block a probe that says the node is empty,
  # for as long as capacity_max_age_ms allows (forever with 0). So only a pending backoff, or a
  # reading younger than the longer of the two sources' poll intervals, holds the incoming one
  # off: within that window neither source has had a full poll since, and the tighter one is
  # the safer view of the same moment. Two passive readings (no interval) never hold.
  my $current = $self->capacity_reading($node_id);
  if ($current && $current->{source} ne $entry->{source}
      && _reading_tightness($current) > _reading_tightness($entry)) {
    my $backoff_pending = ($current->{retry_after} && time < $current->{retry_after}) ? 1 : 0;
    my ($cur_ms, $new_ms) = (($current->{interval_ms} // 0), ($entry->{interval_ms} // 0));
    my $hold_s = ($cur_ms > $new_ms ? $cur_ms : $new_ms) / 1000;
    my $age = Time::HiRes::time() - ($current->{at} // 0);
    return $current if $backoff_pending || $age < $hold_s;
  }

  $self->_capacity->{$node_id} = $entry;
  return $entry;
}

# How much a reading holds admission back: a pending backoff above everything, then the used
# fraction, then nothing for a reading without a limit.
sub _reading_tightness {
  my ($reading) = @_;
  return 9**9**9 if $reading->{retry_after} && time < $reading->{retry_after};
  my $limit = 0 + ($reading->{limit} // 0);
  return 0 if $limit <= 0;
  return (0 + ($reading->{used} // 0)) / $limit;
}


sub capacity_reading {
  my ($self, $node_id) = @_;
  return unless defined($node_id) && length($node_id);
  my $entry = $self->_capacity->{$node_id} or return;

  my $backoff_pending = ($entry->{retry_after} && time < $entry->{retry_after}) ? 1 : 0;
  my $max_age = 0 + ($self->capacity_max_age_ms // 0);
  if (!$backoff_pending && $max_age > 0 && (time - ($entry->{at} // 0)) > ($max_age / 1000)) {
    delete $self->_capacity->{$node_id};
    return;
  }
  # A reading that said how long it may be believed is not believed longer (ADR 0017).
  if (!$backoff_pending && defined($entry->{expires_at}) && Time::HiRes::time() > $entry->{expires_at}) {
    delete $self->_capacity->{$node_id};
    return;
  }
  return $entry;
}


sub forget_capacity {
  my ($self, $node_id, %args) = @_;
  if (defined($node_id) && length($node_id)) {
    if (defined $args{source}) {
      my $entry = $self->_capacity->{$node_id};
      return 0 unless $entry && ($entry->{source} // '') eq $args{source};
    }
    delete $self->_capacity->{$node_id};
    return 1;
  }
  %{$self->_capacity} = ();
  return 1;
}

# Rate-limit headers, in the spellings the big providers actually use. Ordered: the first one
# present wins, so a provider sending several does not get read twice.
# Providers meter more than one thing at once, and for an LLM API the token budget is usually
# what runs out first -- a node with requests to spare and no tokens left answers 429 all the
# same. Each quota is read separately and the tightest one decides.
#
# Within a quota the order is "most specific first": the first name present wins, so a provider
# sending both a specific and a generic spelling is not counted twice.
my @RATELIMIT_QUOTAS = (
  {
    name      => 'requests',
    remaining => [qw(
      x-ratelimit-remaining-requests
      anthropic-ratelimit-requests-remaining
      x-ratelimit-remaining
      ratelimit-remaining
    )],
    limit => [qw(
      x-ratelimit-limit-requests
      anthropic-ratelimit-requests-limit
      x-ratelimit-limit
      ratelimit-limit
    )],
  },
  {
    name      => 'tokens',
    remaining => [qw(
      x-ratelimit-remaining-tokens
      anthropic-ratelimit-tokens-remaining
      anthropic-ratelimit-input-tokens-remaining
    )],
    limit => [qw(
      x-ratelimit-limit-tokens
      anthropic-ratelimit-tokens-limit
      anthropic-ratelimit-input-tokens-limit
    )],
  },
);


sub capacity_header_names {
  return ((map { @{$_->{remaining}}, @{$_->{limit}} } @RATELIMIT_QUOTAS), 'retry-after');
}


sub observe_response_headers {
  my ($self, $node_id, $headers, %args) = @_;
  return unless defined($node_id) && length($node_id);
  return unless ref($headers) eq 'HASH';

  # Case-insensitive: header casing is not something a provider promises.
  my %h = map { lc($_) => $headers->{$_} } keys %$headers;
  my %reading = (source => 'ratelimit');
  my $useful = 0;

  # The tightest quota wins, compared as a fraction because requests and tokens are not the
  # same unit. Reporting the roomier one would admit a request the provider is about to refuse.
  my $tightest = -1;
  for my $quota (@RATELIMIT_QUOTAS) {
    my ($remaining) = grep { defined } map { $h{$_} } @{$quota->{remaining}};
    next unless defined($remaining) && $remaining =~ /^\s*(\d+)/;
    my $left = 0 + $1;

    my ($limit) = grep { defined } map { $h{$_} } @{$quota->{limit}};
    # The probe contract counts what is used, not what is left; a limit we were not told is
    # reconstructed as "one more than we have", which is enough to stop admitting at zero.
    my $total = (defined($limit) && $limit =~ /^\s*(\d+)/) ? 0 + $1 : $left + 1;
    next unless $total > 0;

    my $used = $total - $left;
    $used = $total if $used > $total;
    $used = 0 if $used < 0;

    my $fraction = $used / $total;
    next unless $fraction > $tightest;
    $tightest = $fraction;
    $reading{limit} = $total;
    $reading{used}  = $used;
    $reading{quota} = $quota->{name};
    $useful = 1;
  }

  my $retry = $h{'retry-after'};
  my $status = 0 + ($args{status} // 0);
  if ($status == 429 || defined $retry) {
    my $secs;
    if (defined($retry) && $retry =~ /^\s*([\d.]+)\s*$/) {
      $secs = 0 + $1;
    } elsif ($status == 429) {
      # A 429 with no Retry-After still means "not now". One second is short enough not to
      # strand capacity and long enough to stop hammering.
      $secs = 1;
    }
    if (defined $secs && $secs > 0) {
      $reading{retry_after_ms} = $secs * 1000;
      $useful = 1;
    }
  }

  return unless $useful;
  return $self->set_capacity_reading($node_id, %reading);
}


sub start_request {
  my ($self, $node_id) = @_;
  croak 'node_id required' unless defined $node_id && length $node_id;
  my $node = (grep { ($_->{id} // '') eq $node_id } @{$self->nodes})[0];
  return 0 unless $node && $self->_node_can_take($node);

  $self->_inflight->{$node_id} = 1 + ($self->_inflight->{$node_id} // 0);
  $self->_stats->{$node_id}{started} = 1 + ($self->_stats->{$node_id}{started} // 0);
  return 1;
}


sub finish_request {
  my ($self, $node_id, %args) = @_;
  croak 'node_id required' unless defined $node_id && length $node_id;
  my $cur = 0 + ($self->_inflight->{$node_id} // 0);
  $cur--;
  $cur = 0 if $cur < 0;
  $self->_inflight->{$node_id} = $cur;

  if ($args{aborted}) {
    # The client left. The node did nothing wrong: not an error, not a failure in the window.
    $self->_stats->{$node_id}{aborted} = 1 + ($self->_stats->{$node_id}{aborted} // 0);
  } elsif ($args{ok}) {
    $self->_stats->{$node_id}{ok} = 1 + ($self->_stats->{$node_id}{ok} // 0);
  } else {
    $self->_stats->{$node_id}{error} = 1 + ($self->_stats->{$node_id}{error} // 0);
    $self->_record_failure($node_id);
  }

  if (defined $args{duration_ms}) {
    $self->_stats->{$node_id}{duration_ms_total}
      = (0 + ($self->_stats->{$node_id}{duration_ms_total} // 0)) + (0 + $args{duration_ms});
  }

  return 1;
}

# One bucket per second, pruned to the window on every write, so a node that fails a lot costs
# at most error_window_s buckets.
sub _record_failure {
  my ($self, $node_id) = @_;
  my $now = Time::HiRes::time();
  my $f = $self->_failures->{$node_id} //= { buckets => {} };
  $f->{last_at} = $now;
  $f->{buckets}{int $now}++;
  my $oldest = int($now - (0 + ($self->registry_error_window_s || 60)));
  for my $second (keys %{$f->{buckets}}) {
    delete $f->{buckets}{$second} if $second < $oldest;
  }
  return;
}

sub _errors_in_window {
  my ($self, $node_id) = @_;
  my $f = $self->_failures->{$node_id} or return 0;
  my $oldest = int(Time::HiRes::time() - (0 + ($self->registry_error_window_s || 60)));
  my $count = 0;
  for my $second (keys %{$f->{buckets}}) {
    $count += $f->{buckets}{$second} if $second >= $oldest;
  }
  return $count;
}


sub registry_snapshot {
  my ($self) = @_;
  my $instance = $self->registry_instance_id;
  unless (defined($instance) && length($instance)) {
    require Sys::Hostname;
    $instance = Sys::Hostname::hostname();
  }

  my @nodes;
  for my $node (sort { ($a->{id} // '') cmp ($b->{id} // '') } @{$self->nodes || []}) {
    my $id = $node->{id} // next;
    my $reading = $self->capacity_reading($id);
    my $failure = $self->_failures->{$id};
    push @nodes, {
      id               => "$id",
      tags             => [ @{$node->{tags} || []} ],
      healthy          => ($node->{healthy} ? 1 : 0),
      inflight         => 0 + ($self->_inflight->{$id} // 0),
      max_conns        => 0 + $self->worker_max_conns($node),
      errors_in_window => 0 + $self->_errors_in_window($id),
      last_failure_at  => ($failure && defined $failure->{last_at} ? 0 + $failure->{last_at} : undef),
      ($reading ? (capacity => {
        used   => (defined $reading->{used}  ? 0 + $reading->{used}  : undef),
        limit  => (defined $reading->{limit} ? 0 + $reading->{limit} : undef),
        source => "$reading->{source}",
        ($reading->{retry_after} ? (retry_after => 0 + $reading->{retry_after}) : ()),
      }) : ()),
    };
  }

  return {
    version      => 1,
    instance     => "$instance",
    generated_at => Time::HiRes::time(),
    ttl          => 0 + ($self->registry_ttl_s || 10),
    workers      => 0 + ($self->worker_count // 1),
    nodes        => \@nodes,
  };
}


sub node_metrics {
  my ($self, $node_id) = @_;
  if (defined $node_id && length $node_id) {
    my $s = $self->_stats->{$node_id} || {};
    my $reading = $self->capacity_reading($node_id);
    return {
      node_id => $node_id,
      inflight => 0 + ($self->_inflight->{$node_id} // 0),
      started => 0 + ($s->{started} // 0),
      ok => 0 + ($s->{ok} // 0),
      error => 0 + ($s->{error} // 0),
      aborted => 0 + ($s->{aborted} // 0),
      duration_ms_total => 0 + ($s->{duration_ms_total} // 0),
      # Present only when a probe has something current to say. A report must not present a
      # measured node and an inferred one as equally known (ADR 0009).
      ($reading ? (capacity => { %$reading }) : ()),
    };
  }

  my @rows;
  for my $n (@{$self->nodes}) {
    push @rows, $self->node_metrics($n->{id});
  }
  return \@rows;
}


sub call_function {
  my ($self, $name, $args) = @_;
  $args ||= {};
  croak 'function name required' unless defined $name && length $name;
  croak 'function args must be hashref' unless ref($args) eq 'HASH';

  # Dynamic config refresh on each task/function dispatch. Never dies: a failed reload keeps
  # the previous config and is reported by reload_status (skeid #39).
  $self->maybe_reload_config;

  if ($name eq 'metrics.estimate_cost') {
    return $self->estimate_cost(%$args);
  }
  if ($name eq 'metrics.normalize') {
    return $self->normalize_metrics(%$args);
  }
  if ($name eq 'pricing.set') {
    my $model = $args->{model} // croak 'pricing.set: model required';
    my $pricing = $args->{pricing} // croak 'pricing.set: pricing required';
    return $self->set_model_pricing($model, $pricing);
  }
  if ($name eq 'nodes.add') {
    return { ok => $self->add_node(%$args) ? 1 : 0 };
  }
  if ($name eq 'nodes.remove') {
    return { ok => $self->remove_node($args->{id}) ? 1 : 0 };
  }
  if ($name eq 'nodes.list') {
    return { nodes => $self->list_nodes };
  }
  if ($name eq 'nodes.select') {
    return { nodes => $self->select_nodes(tags => $args->{tags}, deny_tags => $args->{deny_tags}) };
  }
  if ($name eq 'alias.set') {
    my $alias = $args->{name} // croak 'alias.set: name required';
    return { ok => $self->set_model_alias($alias, $args->{alias} // $args) ? 1 : 0 };
  }
  if ($name eq 'route.plan') {
    return $self->route_plan(
      model      => ($args->{model} // ''),
      engine     => $args->{engine},
      api_key_id => $args->{api_key_id},
    );
  }
  if ($name eq 'policy.set') {
    my $policy = $args->{name} // croak 'policy.set: name required';
    return { ok => $self->set_policy($policy, $args->{policy} // $args) ? 1 : 0 };
  }
  if ($name eq 'policy.for_key') {
    return { policy => $self->policy_for_key($args->{api_key_id}) };
  }
  if ($name eq 'nodes.set_health') {
    return { ok => $self->set_node_health($args->{id}, $args->{healthy}) ? 1 : 0 };
  }
  if ($name eq 'nodes.metrics') {
    return { metrics => $self->node_metrics($args->{id}) };
  }
  if ($name eq 'engines.list') {
    return { engines => $self->supported_engine_ids };
  }
  if ($name eq 'route.next') {
    my $node = $self->pick_node(
      model  => ($args->{model} // ''),
      engine => $self->normalize_engine_id($args->{engine} // ''),
      tags   => $args->{tags},
      deny_tags => $args->{deny_tags},
    );
    return { node => $node };
  }
  if ($name eq 'route.state') {
    my $engine = $self->normalize_engine_id($args->{engine} // '');
    return $self->route_state(
      model  => ($args->{model} // ''),
      engine => $engine,
      tags   => $args->{tags},
      deny_tags => $args->{deny_tags},
    );
  }
  if ($name eq 'capacity.set') {
    my $id = $args->{id} // croak 'capacity.set: id required';
    return { capacity => $self->set_capacity_reading($id, %$args) };
  }
  if ($name eq 'capacity.get') {
    my $id = $args->{id} // croak 'capacity.get: id required';
    return { capacity => $self->capacity_reading($id) };
  }
  if ($name eq 'capacity.observe') {
    my $id = $args->{id} // croak 'capacity.observe: id required';
    return { capacity => $self->observe_response_headers(
      $id, ($args->{headers} || {}), status => $args->{status}) };
  }
  if ($name eq 'capacity.forget') {
    return { ok => $self->forget_capacity($args->{id}) ? 1 : 0 };
  }
  if ($name eq 'request.start') {
    my $id = $args->{id} // croak 'request.start: id required';
    return { ok => $self->start_request($id) ? 1 : 0 };
  }
  if ($name eq 'request.finish') {
    my $id = $args->{id} // croak 'request.finish: id required';
    return { ok => $self->finish_request($id, %$args) ? 1 : 0 };
  }
  if ($name eq 'config.reload') {
    return { config => $self->reload_config };
  }
  if ($name eq 'config.status') {
    return $self->reload_status;
  }
  if ($name eq 'usage.record') {
    return $self->record_usage(%$args);
  }
  if ($name eq 'usage.report') {
    return $self->usage_report(%$args);
  }
  if ($name eq 'usage.configure') {
    my $store = $args->{usage_store} // $args;
    return { usage_store => $self->configure_usage_store($store) };
  }

  croak "unknown function: $name";
}

sub DEMOLISH {
  my ($self) = @_;
  $self->_disconnect_usage_store;
}

sub _disconnect_usage_store {
  my ($self) = @_;
  my $store = $self->_usage_store_obj or return;
  $store->disconnect;
  $self->_usage_store_obj(undef);
  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid - Dynamic routing control-plane for multi-node LLM serving with normalized metrics and cost accounting

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Langertha::Skeid;

  my $skeid = Langertha::Skeid->new(
    config_file => '/etc/skeid/config.yaml',
  );

  my $cost = $skeid->call_function('metrics.estimate_cost', {
    model => 'gpt-4o-mini',
    usage => { prompt_tokens => 1000, completion_tokens => 200 },
  });

=head1 DESCRIPTION

Langertha::Skeid is a routing control-plane for provider-style LLM operations.
It keeps a live node table, routes by model/health/capacity, and records
normalized token/cost usage.

Skeid is commonly used as one API edge in front of many upstream APIs
(cloud + local). With C<pricing> and C<usage.record/report>, you can build
tenant billing from one consistent ledger.

=head2 Multi-API Billing Flow

1. Define multiple nodes in config (for example OpenAI-compatible cloud APIs
   and local vLLM/SGLang).
2. Set model pricing via C<pricing> or C<pricing.set>.
3. Let tenant identity follow from the API key the caller presents. C<skeid keyid>
   prints the id a given key resolves to. A deployment that authenticates callers
   in front of Skeid can instead pass C<x-skeid-key-id> and set
   C<routing.trust_key_id_header>.
4. Read totals by key/model/time with C<usage.report>.

=head2 Engine IDs

C<nodes[].engine> uses lowercased engine class names from L<Langertha>.
Examples: C<OpenAI =E<gt> openai>, C<OpenAIBase =E<gt> openaibase>,
C<vLLM =E<gt> vllm>. Legacy aliases like C<openai-compatible> are intentionally
rejected. A node without C<engine> is C<openaibase>. See L</normalize_engine_id>.

=head2 Pluggable Usage Storage

The usage storage layer is pluggable.  Built-in backends are C<jsonlog>
(recommended, no DBI required), C<sqlite>, and C<postgresql>.  You can also
replace the storage layer entirely via constructor callbacks or subclass
override.

B<jsonlog backend> (recommended — no DBI dependency):

  # Directory mode: one JSON file per event (no collision risk)
  my $skeid = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => '/var/log/skeid/events/' },
  );

  # File mode: JSON-lines appended to a single file
  my $skeid = Langertha::Skeid->new(
    usage_store => { backend => 'jsonlog', path => '/var/log/skeid/usage.jsonl', mode => 'file' },
  );

Directory mode is auto-detected when the path is an existing directory or ends
with C</>.  It writes one C<.json> file per event, which avoids file-level
locking and concurrent-write collisions entirely.

B<Constructor callbacks> (custom backend, no subclassing):

  my $skeid = Langertha::Skeid->new(
    store_usage_event => sub {
      my ($self, $event) = @_;
      # $event is a hashref with all normalized usage columns
      publish_to_nats($event);
      return { ok => 1 };
    },
    query_usage_report => sub {
      my ($self, $filters) = @_;
      # $filters has: since, api_key_id, model, limit
      return { ok => 1, enabled => 1, totals => { ... } };
    },
  );

B<Subclass override>:

  package MyApp::Skeid;
  use Moo;
  extends 'Langertha::Skeid';

  sub _store_usage_event {
    my ($self, $event) = @_;
    ...
    return { ok => 1 };
  }

  sub _query_usage_report {
    my ($self, $filters) = @_;
    ...
  }

B<Optional fields.> A streamed request's event also carries C<content_bytes>: the
UTF-8 byte count of the content Skeid relayed (OpenAI face) or translated (Anthropic
and Ollama faces). It is set on every stream, including one whose upstream reported
token counts, and is absent from non-streamed events -- a sink must not assume it is
there. It is an observation, not a billing quantity: Skeid never derives token counts
or cost from it. The DBI stores keep it in a nullable C<content_bytes> column (C<NULL>
for a non-streamed or pre-existing row); C<jsonlog> writes it as part of the event.

When a callback or override is provided, the configured store is bypassed entirely
and no database connection is created.  DBI, DBD::SQLite and DBD::Pg are C<recommends>
dependencies — they are not required for C<jsonlog> or when usage is handled externally.
With no sink at all, L</record_usage> builds no event and answers
C<< { ok => 0, enabled => 0, error => 'usage_store not configured' } >>. A sink that fails answers
C<< { ok => 0, error => ... } >> (or dies); the proxy logs that at C<error> level as a lost usage
event, naming the request id and the store backend.

=head2 Per-Key Routing Policy

Which nodes a customer key may be served from, and which models it may ask for:

  policies:
    standard:  { deny_tags: [cloud] }        # our own hardware only
    burstable: {}                            # cloud is fine when local is full
  default_policy: standard
  names:
    alice:   k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b  # id from `skeid keyid <key>` -- never the key
    bigcorp: k_9c8b7a6f5e4de5f60718293a4b5c6d7e8f901a2b
  keys:
    alice: burstable                          # a keys: entry may be written by name ...
    bigcorp:
      policy: standard
      models: [house-model]                  # sparse override of one field
    k_1122334455aae5f60718293a4b5c6d7e8f901a2b: burstable  # ... or still by the raw key id

Resolved once at config load: a request costs one hash lookup, keys on the same profile share
one policy object, and a key that takes the default is not listed at all. C<deny_tags> filters
node selection, not just the plan, so a denied node cannot be reached by asking for its own
model name instead of an alias. A refusal is C<403>, never a capacity error.

The optional C<names:> section maps a readable name to a customer key id (karr #17). It makes
C<keys:> entries legible and confines key rotation to a single line -- change the id a name
points at, and every policy line that named the customer follows. Its values are ids from
C<skeid keyid>, never customer keys, so the config still holds no secret; it is read only at
config load and never on the request path.

Identity comes from the API key the caller presented — see L</key_id_for_key>. See also ADR
0008 in the distribution repository.

=head2 Admin API Key

C<admin.api_key> (or C<admin_api_key>) controls access to proxy admin routes; C<admin.api_key_env>
(or C<admin_api_key_env>) names an environment variable to read it from instead, so the key need
not be written into a mounted file. If empty, admin routes are effectively disabled by returning
C<404>. If set, the proxy expects C<Authorization: Bearer ...>. An explicit key
(C<skeid serve --admin-api-key>, L</set_admin_api_key>) outranks the config, and
C<SKEID_ADMIN_API_KEY> stands in when the config names none; a reload re-applies that order.
See L</admin>.

=head2 Provider Manifest

C<GET /.well-known/langertha.json> serves a provider manifest (core's
L<Langertha::Manifest>, schema v1) to a customer key -- listing only the models that key's own
C<keys:> entry names. Nothing is published automatically: the route answers C<404> until the
config turns it on, and a key without a C<manifest:> entry gets C<403>, never the catalog.

  manifest:
    enabled: true
    public_url: https://llm.example.com   # where clients reach Skeid -- never a node URL
    provider_id: example-llm              # default: skeid
    faces: [openai, anthropic, ollama]    # default: all three
    capabilities:                         # optional claims per model; default chat + streaming
      house-model: { tools_native: true, tool_choice_auto: true }
  names:                                  # ids from `skeid keyid <key>` -- never the key
    alice: k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b
    bob:   k_9c8b7a6f5e4de5f60718293a4b5c6d7e8f901a2b
  keys:
    alice:
      policy: burstable
      manifest: { models: [house-model, qwen3-32b] }
    bob:
      manifest: { models: [house-model] }

One endpoint per face, all under C<public_url> and all with one C<api_key> auth entry (the
C<Authorization: Bearer> / C<x-api-key> scheme every face already takes): C<openai>
(C<openai-chat>, C<public_url/v1>), C<anthropic> (C<anthropic-compat> at C<public_url> --
Skeid translates C</v1/messages> to the OpenAI upstream call and does not carry
C<output_config.format>, so structured output takes the synthetic-tool path) and C<ollama>
(C<public_url>). Every listed model appears on every published face. Its capabilities default
to C<chat> and C<streaming>, take the claims declared for it (only flags from
L<Langertha::Manifest::Builder/model_capabilities>), and are then cut per face to what that
face's translator carries upstream -- a claim holds at that endpoint or is not made there. The
lists are L<Langertha::Skeid::Protocol/openai_manifest_endpoint>,
L<Langertha::Skeid::Protocol::Anthropic/manifest_endpoint> and
L<Langertha::Skeid::Protocol::Ollama/manifest_endpoint>.

Resolved at config load, like the routing policy: each key's manifest is built and validated
once and stored under the key id, so a request costs one hash lookup and one key's manifest
cannot be served for another. The load croaks on a model the key's routing policy does not
let it reach (not granted, or served only by nodes it is denied), on an unknown capability,
one no face carries, an unknown face, and an enabled manifest without C<public_url>. A config
that fails to load keeps the previous one in force, manifests included. The route never
reloads the config itself; the request paths that already do pick up a change.
Without a key the route answers C<401>. Needs a Langertha with L<Langertha::Manifest>; on an
older one the route answers C<404>. See ADR 0015 in the distribution repository.

=head1 CONFIGURATION

The config is a YAML file (C<config_file>) or the hashref a C<config_loader> returns; both go
through the same loader. The top-level keys below are every one Skeid reads -- anything else in
the file is ignored. A reload is all or nothing: a config that fails anywhere leaves the previous
one in force, and is reported by L</reload_status>.

A reload makes the running config equal to the file (skeid k65), as a restart with that file
would:

=over 4

=item * C<nodes>, C<pricing>, C<aliases>, the policy keys (C<policies>, C<default_policy>,
C<names>, C<keys>) and C<usage_store>: present, the section replaces what is loaded -- C<pricing>
too, so a model removed from it loses its price. Removed from the file, the section goes back
to empty with the next reload: no nodes, no prices, no aliases, no policies.

=item * C<routing>: each key present sets its value; a key removed from the file goes back to
the value it had before any config was applied -- passed to C<new>, else from
L</ENVIRONMENT>, else built in.

=item * The admin key: absent falls back to C<SKEID_ADMIN_API_KEY>, else off -- see L</admin>.

=item * C<registry> and C<manifest>: absent means off.

=back

Two exceptions. A section no applied config has declared belongs to whoever set it: nodes added
through the admin API or L</add_node>, prices from L</set_model_pricing>, values passed to
C<new> -- a config without that section leaves them alone. And the usage store is not removed by
a reload: a C<usage_store> taken out of the file keeps the running store in force until restart,
with one warning (C<usage_store was removed from the config ...>), because a reload that stopped
recording usage events would lose billing data silently (ADR 0004). A I<changed> C<usage_store>
is swapped at once, the new store prepared before the old one is let go.

Three settings look like config but are not read from it: L</capacity_max_age_ms> and
L</config_reload_interval> (constructor or environment only) and L</worker_count> (constructor,
set by C<skeid serve --workers>).

=head2 nodes

  nodes:
    - id: gpu-1                        # required, unique
      url: http://gpu-1:8000/v1        # required; /v1 is added when the URL does not end in it
      model: qwen3-32b                 # default '': matches any requested model
      engine: vllm                     # default openaibase; see "Engine IDs"
      weight: 3                        # default 1; round-robin weight, integer, below 1 counts as 1
      max_conns: 8                     # default 0 = unlimited; admission limit, see worker_max_conns
      healthy: true                    # default true; operator state, never derived from errors
      tags: [local, gb10]              # default none; "local, gb10" works too, see normalize_tags
      metadata: { rack: b2 }           # default {}; kept on the node, never read by routing
      api_key_ref: secret/skeid/remote/groq   # upstream key, resolved through the key broker
      api_key_env: GROQ_API_KEY        # upstream key from this variable when the ref resolves none
      capacity: { probe: prometheus }  # default none: inflight admission, see below

An entry without C<id> or C<url> is skipped; one with an unknown C<engine> fails the load. When
a node has a key of its own it replaces the client's C<Authorization> upstream (see
L<Langertha::Skeid::Proxy>); otherwise the client's headers go through. Key references and
variable names are the only key material a config holds (ADR 0003).

The section replaces the whole inventory when it changed -- nodes added through the admin API are
lost then -- and keeps the node list as it is when it did not: its inventory generation, its
running probes and any health set through the admin API. Removing the section empties the
inventory.

C<capacity> selects how admission learns a node's real occupancy (ADR 0009). C<probe> (or
C<type>) is C<inflight> (the default, also C<none>), C<ratelimit>, C<prometheus>, C<registry> or
C<custom>; C<interval_ms> (default 2000) sets the poll rate. Rate-limit headers are read off every
upstream response whatever the block says, so C<ratelimit> starts nothing. The keys per probe
are documented in L<Langertha::Skeid::CapacityProbe/for_node>,
L<Langertha::Skeid::CapacityProbe::Prometheus> and L<Langertha::Skeid::CapacityProbe::Registry>.

=head2 pricing

  pricing:
    gpt-4o-mini:
      input_per_million: 0.15          # default 0
      output_per_million: 0.60         # default 0
      cached_input_per_million: 0.075  # optional; prompt-cache reads
      cache_write_per_million: 0.1875  # optional; prompt-cache writes
    '*':                               # fallback for every model not listed
      input_per_million: 0
      output_per_million: 0

Keyed by the B<served> model -- the name the node is asked for, not an alias. The section is the
whole price list: a reload replaces it, it is not merged. A cache rate must be
a number C<E<gt>= 0>, or the load fails; on a Langertha that cannot price cache tokens the cache
rates are dropped with one warning and cached tokens bill at C<input_per_million>. See
L</set_model_pricing>.

=head2 aliases

  aliases:
    house-model:
      tiers:
        - { tags: [local], model: qwen3-32b, wait_ms: 200 }
        - { tags: [cloud], model: llama-3.3-70b-versatile }

A client-facing model name as an ordered plan of tiers (ADR 0008). Per tier: C<tags>, C<model>
(default: the alias name), C<engine> and C<wait_ms> (default 0). C<tiers> may be given as a bare
list. See L</set_model_alias>.

=head2 policies, default_policy, names, keys

Who may reach what; see L</Per-Key Routing Policy>. A policy is C<models> (or C<aliases>: the
requested names the key may use; absent or C<'*'> means all) and C<deny_tags> (nodes the key must
never reach). C<default_policy> names the policy of every unlisted key; unset, an unlisted key is
unrestricted. C<names> maps a readable name to a key id from C<skeid keyid>.

A C<keys> entry is keyed by a key id or a C<names> name and is either a policy name or a hash:

  keys:
    alice: burstable
    bigcorp:
      policy: standard          # default: default_policy
      models: [house-model]     # sparse overrides: an absent field keeps the policy's value
      deny_tags: [cloud]
      manifest: { models: [house-model] }   # see "Provider Manifest"

The override fields may instead sit under an C<overrides> hash. The load fails on a
C<default_policy> or a C<keys> entry naming an undefined policy, on a C<names> value that is not
a non-empty string, and on two entries that resolve to one key id -- including a short
(pre-ADR 0016) id beside the full id it is the prefix of. Short ids still match, with a one-time
warning.

=head2 routing

  routing:
    wait_timeout_ms: 2000        # default 2000: the wait of a model that has no alias
    wait_poll_ms: 25             # default 25, at least 1: how often a waiting request retries
    trust_key_id_header: false   # default false; see key_id_for_key
    frontend_count: 1            # default 1, at least 1; see frontend_count

The defaults come from L</ENVIRONMENT> when set there.

=head2 admin

  admin:
    api_key_env: SKEID_ADMIN_API_KEY   # or api_key: "..."

The key for the C</skeid/*> admin API. It comes from the first of these that has one
(skeid k64):

=over 4

=item 1. An explicit key: C<skeid serve --admin-api-key>, C<< build_app(admin_api_key => ...) >>,
an C<admin_api_key> passed to C<new>, or L</set_admin_api_key>.

=item 2. The config: the first of C<admin_api_key>, C<admin_api_key_env>, C<admin.api_key> and
C<admin.api_key_env> that is present decides -- set empty, or naming an unset variable, it turns
the admin API off.

=item 3. C<SKEID_ADMIN_API_KEY>, when the config names none of the four.

=back

With none of them the admin API is off (C<404>). Every applied config re-resolves the key in
this order, so a reload never replaces an explicit key, and removing the key from the config
falls back to the variable. A variable is read when the config is applied, so a changed value
takes effect with the next changed config.

=head2 registry

Publishes this Skeid's capacity to a fronting Skeid: C<enabled>, C<secret_env>, C<read_key_env>,
C<ttl_s> (default 10), C<instance_id> (default the hostname) and C<error_window_s> (default 60).
Documented under L</registry_enabled>.

=head2 manifest

The provider manifest: C<enabled>, C<public_url>, C<provider_id> (default C<skeid>), C<faces>
(default all three) and C<capabilities>. Documented under L</Provider Manifest>.

=head2 usage_store

  usage_store:
    backend: jsonlog                 # jsonlog | sqlite | postgresql; inferred when absent
    path: /var/log/skeid/events/     # jsonlog: log_path or path; mode dir|file (inferred), fsync
    # sqlite:     sqlite_path (or path, db_path), schema_file, auto_migrate (default on)
    # postgresql: dsn, or host (127.0.0.1) / port (5432) / dbname or database (skeid);
    #             user, password or password_env, schema_file, auto_migrate (default on)
    # sqlite and postgresql: flush_interval_ms (default 0) -- above 0, queue events and
    #             write them in one transaction per interval (write-behind)

Where usage events go; see L<Langertha::Skeid::UsageStore/normalize_config> for the inference and
the defaults. C<usage_db_path>, a top-level key, is the older spelling of a sqlite store and is
read only when C<usage_store> is absent. A changed store is swapped on reload; a removed one stays
in force until restart, with a warning -- see L</CONFIGURATION>.

C<flush_interval_ms> moves a database write off the request path: the request is answered at
once and the queued events are written together once per interval. Queued events are held in
memory until then; a process that is killed rather than stopped loses them. See
L<Langertha::Skeid::UsageStore::DBI/flush_interval_ms> and ADR 0005.

=head1 ENVIRONMENT

Defaults for the attributes of the same meaning; a value in the config wins. Besides these, the
config names variables of its own -- C<api_key_env> on a node, C<admin.api_key_env>, a usage
store's C<password_env>, the registry's C<secret_env> and C<read_key_env> -- so that no secret has
to be written into it. L<Langertha::Skeid::Proxy/build_app> reads the C<OPENBAO_*> variables,
C<SKEID_UPSTREAM_POOL> and C<SKEID_UPSTREAM_TIMEOUT>.

=head2 SKEID_ROUTE_WAIT_TIMEOUT_MS

Default of L</route_wait_timeout_ms> (2000).

=head2 SKEID_ROUTE_WAIT_POLL_MS

Default of L</route_wait_poll_ms> (25).

=head2 SKEID_TRUST_KEY_ID_HEADER

Default of L</trust_key_id_header>: C<1>, C<true>, C<yes> or C<on> turn it on.

=head2 SKEID_FRONTEND_COUNT

Default of L</frontend_count> (1).

=head2 SKEID_ADMIN_API_KEY

The admin API key when neither an explicit key nor the config names one; see L</admin>.

=head2 SKEID_USAGE_DB

Default of L</usage_db_path>: a SQLite usage store at this path when no C<usage_store> is given,
and the path of a C<sqlite> store that names none.

=head2 SKEID_CAPACITY_MAX_AGE_MS

Default of L</capacity_max_age_ms> (5000).

=head2 SKEID_CONFIG_RELOAD_INTERVAL

Default of L</config_reload_interval> (1 second).

=head1 ATTRIBUTES

Every attribute can be passed to C<new>. Those a config sets are overwritten by the next changed
config that sets them (see L</CONFIGURATION>) -- except L</admin_api_key>, which C<new> takes as
an explicit key that outranks the config.

=head2 nodes

The node inventory: an arrayref of node hashrefs, in the shape of the config's C<nodes> entries
after L</add_node> normalized them (default empty). Change it through L</add_node>,
L</remove_node> and L</set_node_health>, or assign a whole new list: routing caches what it
derives from the inventory, and only those paths invalidate the cache. Editing a node hash in
place does not.

=head2 model_pricing

Served model name to pricing rule, C<'*'> as the fallback (default empty). Written by
L</set_model_pricing>; read through L</pricing_for_model>.

=head2 model_aliases

Alias name to C<< { tiers => [...] } >>, normalized (default empty). Written by
L</set_model_alias>.

=head2 policies

Policy name to resolved policy (see L</resolve_policy>), from the config's C<policies> or
L</set_policy> (default empty).

=head2 default_policy

The resolved policy an unlisted key routes under -- the policy object, not its name -- or undef,
which leaves unlisted keys unrestricted (default undef).

=head2 key_policies

Customer key id to resolved policy, built at config load (default empty). Keys that take the
default policy are not in it; see L</policy_for_key>.

=head2 key_names

Readable name to customer key id, from the config's C<names> section (default empty). See
L</key_id_for_name>.

=head2 manifest_enabled

Whether the config enables the provider manifest (default 0).

=head2 manifest_available

Whether the installed Langertha has L<Langertha::Manifest>; with it missing an enabled manifest
answers C<404> instead of failing the config (default 0).

=head2 key_manifests

Customer key id to the canonical JSON of that key's manifest, built at config load (default
empty). Read through L</manifest_for_key>.

=head2 trust_key_id_header

Whether a client's C<x-skeid-key-id> (or C<x-api-key-id>) header names the customer key id
instead of the key it presented (default off, or C<SKEID_TRUST_KEY_ID_HEADER>; config
C<routing.trust_key_id_header>). Turn it on only behind a gateway that authenticates the caller
and sets that header itself: the key id selects both the routing policy and the bill.

=head2 route_wait_timeout_ms

How long, in milliseconds, a request for a model without an alias waits for a free node before
it is answered C<429> (default 2000, or C<SKEID_ROUTE_WAIT_TIMEOUT_MS>; config
C<routing.wait_timeout_ms>). An alias tier waits its own C<wait_ms> instead.

=head2 route_wait_poll_ms

How often, in milliseconds, a waiting request tries again (default 25, or
C<SKEID_ROUTE_WAIT_POLL_MS>; config C<routing.wait_poll_ms>, at least 1). The wait is a
L<Mojo::IOLoop> timer, never a sleep.

=head2 usage_db_path

A SQLite usage database path (default C<SKEID_USAGE_DB>, else unset). At construction it
configures a SQLite store when C<usage_store> is not given; it is also the path of a C<sqlite>
store config that names none. Kept in step with the store: set to a SQLite store's path, cleared
for PostgreSQL. C<has_usage_db_path> and C<clear_usage_db_path> are its predicate and clearer.

=head2 usage_store

The usage store config (default empty: no store). Passed to C<new> it is a raw C<usage_store>
config; afterwards it holds the normalized form (see
L<Langertha::Skeid::UsageStore/normalize_config>). Change it through
L</configure_usage_store>.

=head2 store_usage_event

  store_usage_event => sub { my ($skeid, $event) = @_; ...; return { ok => 1 } },

Optional code ref that receives every usage event instead of the configured store
(C<has_store_usage_event> is its predicate). See L</Pluggable Usage Storage>.

=head2 query_usage_report

  query_usage_report => sub { my ($skeid, $filters) = @_; ...; return { ok => 1, ... } },

Optional code ref that answers L</usage_report> instead of the configured store
(C<has_query_usage_report> is its predicate). It gets C<since>, C<api_key_id>, C<model> and
C<limit>.

=head2 on_usage_lost

  $skeid->on_usage_lost(sub { my ($skeid, $event, $error) = @_; ... });

Optional code ref (C<has_on_usage_lost> is its predicate), called for every usage event a
write-behind store (C<usage_store.flush_interval_ms>) queued and then could not write. The
request was answered before the write was tried, so this is the only place that failure can be
said. L<Langertha::Skeid::Proxy/build_app> sets it to the proxy's C<usage event lost> log line;
without it Skeid C<warn>s. A failure of a synchronous write is the caller's to report, from the
answer of L</record_usage>, and never comes here.

=head2 admin_api_key

The bearer token of the C</skeid/*> admin API in force; empty disables it, which the proxy
answers with C<404>. Passed to C<new> it is an explicit key (see L</set_admin_api_key>) that
wins over the config; otherwise it is resolved from the config and C<SKEID_ADMIN_API_KEY>
whenever a config is applied -- see L</admin> for the order. Read it here; set it through
L</set_admin_api_key>, since a value written through this accessor lasts only until the next
changed config.

=head2 key_broker

Optional L<Langertha::Skeid::KeyBroker> that resolves a node's C<api_key_ref> per request
(C<has_key_broker> is its predicate). L<Langertha::Skeid::Proxy/build_app> passes a
L<Langertha::Skeid::KeyBroker::OpenBao> when the C<OPENBAO_*> variables are set.

=head2 config_file

Path of a YAML config (see L</CONFIGURATION>; C<has_config_file> is its predicate). Read at
construction and again whenever its mtime moves. Give either this or L</config_loader>, not
both. A path that is not an existing file dies at construction (C<config file not found: ...>);
a file that disappears later keeps the config in force (see L</maybe_reload_config>).

=head2 config_loader

A code ref that returns the config as a hashref, instead of a C<config_file>. It is called with
the Skeid object, at construction and then from C<call_function> at most once per
L</config_reload_interval>.

It may return C<($config, $version)>. A defined version is the change detector: the same
version as last applied means nothing changed and the config is not applied again. Without a
version Skeid digests the returned structure (hash keys sorted) instead. Either way an
unchanged config is a no-op, and a changed one whose C<nodes> section is unchanged keeps the
node list -- its inventory generation, its running capacity probes and any health set through
the admin API. A code ref inside the config (a custom probe's C<code>) digests by identity, so
a loader that builds a fresh closure every call should return a version.

A config file follows the same rules, minus the throttle for a new file version: an mtime change
whose content is unchanged applies nothing. A version that fails to parse is retried with the
same bounded back-off as a failing loader, while a different mtime is read immediately. An
explicit C<config.reload> does too, so a value taken from the environment (C<admin.api_key_env>,
a usage store's C<password_env>) is read again only when the config itself changes.

=head2 config_reload_interval

The least time, in seconds, between two runs of a C<config_loader> (default 1; fractions
allowed; 0 runs it on every dispatch, as before skeid #38).

A loader-based config is re-read from C<call_function>, which every request passes through
several times. Without a throttle every request would rerun the loader. A config file normally
pays only one C<stat> per dispatch; only retries of one failed file version are throttled.

=head2 last_reload_error

Why the last config reload failed, or undef when the last one succeeded. A failed reload keeps
the previous config in force; see L</maybe_reload_config>. C<last_reload_error_at> is when (epoch
seconds), C<reload_failures> how many reloads in a row have failed.

=head2 capacity_max_age_ms

How long a capacity reading is trusted, in milliseconds (default 5000, 0 disables expiry).

A stale reading is worse than none: it describes a node as it was, and admission acts on it as
if it were now. Past this age a reading is ignored and C<inflight> decides again, which is the
same behaviour as having configured no probe at all (ADR 0009).

=head2 worker_count

How many worker processes share this configuration (default 1).

C<inflight> and C<max_conns> are per-process, so N workers would each admit up to C<max_conns>
to a node that can only serve one number — C<max_conns: 8> across 4 workers would permit 32,
silently. Setting this makes each worker take its share instead (ADR 0010). Anything on a timer
is spread the same way, so the process group's aggregate poll rate stays what was configured.

=head2 frontend_count

How many separate Skeid frontends stand in front of one node (default 1).

C<worker_count> partitions C<max_conns> across the prefork workers of one process; this
partitions it across the distinct Skeid hosts sharing a node — a number only the operator
knows, because two frontends are two processes on two machines with nothing between them to
count each other's C<inflight> (there is no probe and no shared state; that absence is the
whole reason this has to be declared rather than detected). With F frontends each admits its
share C<max_conns/F>, so the group as a whole never admits more than the node was configured
for (ADR 0009, ADR 0012).

It composes with C<worker_count>: the two divisors multiply, so one worker's share is
C<max_conns/(F*N)> — partitioned across frontends first, then across workers, which integer
division makes the same thing either way. Unlike the worker divisor it does not scale anything
on a timer: separate frontends each run their own probes and hold their own vault token, the
same reason vault renewal is not scaled per worker (ADR 0010).

Explicit and opt-in: the default 1 is today's behaviour, unchanged. An operator who runs two
frontends and forgets to say so over-admits the node by a factor of two, silently — which is
exactly the failure this field exists to prevent.

=head2 registry_enabled

Whether this Skeid publishes its registry snapshot on C<GET /skeid/registry/snapshot> (default
off; ADR 0017). Set by the config's C<registry> block:

  registry:
    enabled: true
    secret_env: SKEID_REGISTRY_SECRET   # required when enabled; the HMAC key
    ttl_s: 10                           # how long a snapshot may be believed
    instance_id: skeid-b                # default: the hostname
    error_window_s: 60                  # how far back errors_in_window counts
    read_key_env: SKEID_REGISTRY_READ_KEY   # optional; a bearer for the snapshot route only

The fronting tier reads the snapshot with L<Langertha::Skeid::CapacityProbe::Registry>. The
secret is taken from the environment only and kept in memory (ADR 0003); an enabled registry
whose variable is empty or shorter than 32 bytes does not load, because a snapshot is never
published unsigned or weakly signed. Neither does one without a credential to read it: an admin
API key or a registry read key.

C<read_key_env> names the variable holding the B<registry read key> (skeid #49). The snapshot
route accepts it as a bearer token besides the admin API key; it opens no other route, so a
fronting tier holding it cannot add nodes or flip health. A named variable that is empty does
not load. C<registry_secret>, C<registry_read_key>, C<registry_ttl_s>, C<registry_instance_id>
and C<registry_error_window_s> hold the other fields.

=head1 METHODS

=head2 add_node

  $skeid->add_node(id => 'gpu-1', url => 'http://gpu-1:8000/v1', model => 'qwen3-32b',
    tags => ['local'], max_conns => 8);

Adds a node, replacing any node with the same id. Takes the fields of a config C<nodes> entry
and fills in their defaults (see L</nodes>). Returns 1. Croaks without C<id> or C<url>, on an
unknown C<engine>, and on a C<registry> capacity block that
L<Langertha::Skeid::CapacityProbe::Registry/validate_config> rejects. The C<nodes.add> function
and C<POST /skeid/nodes> call it.

=head2 remove_node

  my $removed = $skeid->remove_node('gpu-1');

Removes a node, and with it its capacity reading and failure history, so a node later added
under the same id starts clean. Returns 1 when a node was removed, else 0.

=head2 normalize_tags

  my $tags = Langertha::Skeid->normalize_tags(['Local', 'gb10']);
  my $tags = Langertha::Skeid->normalize_tags('local, gb10');

Tags are lowercased, trimmed, de-duplicated and kept in the order first seen. A plain string is
accepted and split on commas or whitespace, because a hand-written config says
C<tags: local, gb10> at least as often as it says a YAML list.

=head2 list_nodes

  my $nodes = $skeid->list_nodes;

The inventory as an arrayref of shallow copies of the node hashes.

=head2 list_models

  my $models = $skeid->list_models(api_key_id => $key_id);
  # [ { model => 'house-model', engine => '' }, { model => 'qwen3-32b', engine => 'vllm' } ]

The names a client can put in C<model>, sorted by name, each once: the distinct C<model> of the
nodes plus the alias names. A node without a C<model> lists nothing -- it matches any name, so
none reaches it in particular. A name that is both a node model and an alias is one entry.
C<engine> is the first node's engine for a node model, empty for an alias.

The list is narrowed by the policy of C<api_key_id> (none means the default policy), so a key is
never shown a name L</route_plan> would refuse it: a name its C<models> do not grant is left out,
an alias with every tier denied is left out, and a node model that only nodes carrying a denied
tag serve is left out. This backs C</v1/models> and C</api/tags>.

=head2 set_node_health

  $skeid->set_node_health('gpu-1', 0);   # take it out of rotation

Sets the operator health flag. An unhealthy node is not eligible for routing. Health is operator
state: no error, timeout or C<429> ever sets it. Returns 1 when the node exists, else 0. Setting
the value it already has changes nothing, round-robin position included.

=head2 set_model_pricing

  $skeid->set_model_pricing('gpt-4o-mini', {
    input_per_million        => 0.15,
    output_per_million       => 0.60,
    cached_input_per_million => 0.075,   # optional
    cache_write_per_million  => 0.1875,  # optional
  });

Sets the pricing rule for one served model (C<'*'> is the fallback) and returns it as stored.
Absent input and output rates are 0. Croaks without a model or a pricing hash, and on a cache
rate that is not a number C<E<gt>= 0>. On a Langertha that cannot price prompt-cache tokens the
cache rates are dropped, with one warning per process.

=head2 pricing_for_model

  my $rule = $skeid->pricing_for_model('gpt-4o-mini');

The rule for a model, else the C<'*'> rule, else a rule that prices everything at 0.

=head2 reload_config

  my $config = $skeid->reload_config;

Reads the config source and applies it, returning the config hashref. A config whose fingerprint
matches the one last applied changes nothing. Dies when the source cannot be read or the config
does not apply; the previous config then stays in force and L</reload_status> reports the
failure. The C<config.reload> function calls it; the request path uses
L</maybe_reload_config>, which never dies.

=head2 reload_status

  my $status = $skeid->reload_status;
  # { ok => 0, error => '...', failed_at => '2026-09-25T16:08:30Z', failures => 3 }

Whether the last config reload succeeded, and if not, why, when, and how many times in a row.
Served by the admin route C<GET /skeid/config>; the public C</health> carries only C<ok>,
C<failed_at> and C<failures>, never the message, which can name customers and models.

=head2 set_admin_api_key

  $skeid->set_admin_api_key($key);   # explicit: wins over the config, on every reload
  $skeid->set_admin_api_key('');     # back to the config's key, or SKEID_ADMIN_API_KEY

Sets the explicit admin API key -- what C<skeid serve --admin-api-key> and
C<< build_app(admin_api_key => ...) >> set, and what an C<admin_api_key> passed to C<new> is. It
outranks the config: a reload re-applies the order of L</admin> under it instead of replacing it.
An empty or undefined key clears it, and the key the config resolved to takes over at once.
Returns the admin API key now in force.

=head2 maybe_reload_config

  my $applied = $skeid->maybe_reload_config;

Reloads the config if its source may have changed: the file's mtime moved, or a
C<config_loader> is due (L</config_reload_interval>). Returns true when a changed config was
applied. C<call_function> runs it on every dispatch, so it never dies: a reload that fails is
logged, recorded in L</reload_status>, and the request goes on under the config that was in
force before (the reload is all or nothing). A failing source is then retried with a back-off --
the interval doubling per failure, from at least a second up to a minute. A loader that keeps
returning the same broken config is not applied again; a changed config-file mtime bypasses the
failed version's retry window. A config file that has disappeared is not a reload at all: the
config in force stays, and the loss is warned once until the file is back. Only construction
and an explicit C<config.reload> still die on a bad or missing config.

=head2 manifest_for_key

  my $json = $skeid->manifest_for_key($api_key_id);   # UTF-8 JSON bytes, or undef

The provider manifest published to a customer key id, as canonical JSON, or undef when the
key has no C<manifest:> grant, the manifest is disabled, or this Langertha has no
L<Langertha::Manifest>. Built at config load; see L</Provider Manifest>.

=head2 configure_usage_store

  $skeid->configure_usage_store({ backend => 'jsonlog', path => '/var/log/skeid/events/' });

Normalizes a C<usage_store> config and, when it differs from the current one, prepares the new
store before disconnecting the old. Returns the normalized config. Croaks on a config
L<Langertha::Skeid::UsageStore/normalize_config> rejects and on a store that fails to prepare,
leaving the old store in place. The C<usage.configure> function calls it.

=head2 supported_engine_ids

  my $ids = $skeid->supported_engine_ids;   # [ 'aki', 'akiopenai', 'anthropic', ... ]

The engine ids a node may name, sorted: a built-in list, plus whatever
C<< Langertha->available_engine_ids >> reports when the installed Langertha has it.

=head2 normalize_engine_id

  my $id = $skeid->normalize_engine_id('Langertha::Engine::vLLM');   # 'vllm'

Lowercases an engine name and strips a C<Langertha::Engine::> or C<LangerthaX::Engine::>
prefix. Returns the empty string for an empty value and croaks on an id that is not in
L</supported_engine_ids>.

=head2 record_usage

  my $res = $skeid->record_usage(
    api_key_id => $key_id, model => 'qwen3-32b', requested_model => 'house-model',
    node_id => 'gpu-1', status_code => 200, ok => 1, duration_ms => 840,
    metrics => $normalized,   # from normalize_metrics
  );

Builds one usage event and hands it to the sink: the L</store_usage_event> callback, a subclass's
C<_store_usage_event>, or the configured store. Returns the sink's answer, or
C<< { ok => 0, enabled => 0, error => 'usage_store not configured' } >> without building an
event when there is no sink.

The event carries C<created_at>, C<request_id>, C<api_format>, C<endpoint>, C<api_key_id>,
C<provider>, C<engine>, C<model> (served), C<requested_model> (default C<model>), C<node_id>,
C<route_url>, C<status_code>, C<ok>, C<duration_ms>, C<error_type>, C<error_message>, and from
C<metrics> the token counts (C<input_tokens>, C<output_tokens>, C<total_tokens>,
C<cached_tokens>, C<cache_write_tokens>), C<tool_calls> and the costs (C<cost_input_usd>,
C<cost_output_usd>, C<cost_total_usd>, C<cost_cache_read_usd>, C<cost_cache_write_usd>). Costs
arrive already priced; nothing is priced here. C<content_bytes> is set only when given. The
C<usage.record> function calls it.

=head2 flush_usage

  my $res = $skeid->flush_usage;

Writes the usage events a write-behind store still holds (see
L<Langertha::Skeid::UsageStore::DBI/flush>) and returns its answer, or C<< { ok => 1, written
=> 0 } >> when the store holds nothing back. F<bin/skeid> calls it when the server stops, and an
application embedding the proxy should call it before it exits: queued events live in memory
only. Replacing the store on a reload and destroying this object flush as well.

=head2 usage_report

  my $report = $skeid->usage_report(since => '2026-09-01T00:00:00Z', api_key_id => $id,
    model => 'qwen3-32b', limit => 50);

Asks the L</query_usage_report> callback, a subclass's C<_query_usage_report> or the configured
store for a report (its shape: L<Langertha::Skeid::UsageStore>). Empty filters are dropped;
C<limit> defaults to 20 and is capped at 500. Without a store it returns
C<< { ok => 0, enabled => 0, error => 'usage_store not configured' } >>. The C<usage.report>
function, C<GET /skeid/usage> and C<skeid usage> call it.

=head2 estimate_cost

  my $cost = $skeid->estimate_cost(model => 'gpt-4o-mini',
    usage => { prompt_tokens => 1000, completion_tokens => 200 });

Prices a usage with the model's rule (L</pricing_for_model>) or an explicit C<pricing> rule, and
returns the hash form of the L<Langertha::Cost>. The usage is a hash, a L<Langertha::Usage>, or
read from a C<response>. The C<metrics.estimate_cost> function calls it.

=head2 normalize_metrics

  my $metrics = $skeid->normalize_metrics(model => 'gpt-4o-mini', response => $upstream_body,
    tool_calls => \@calls, duration_ms => 840, engine => 'openaibase', route => '/v1/chat/completions');

What a usage event is built from: the usage (as for L</estimate_cost>) priced into a
L<Langertha::UsageRecord>, returned as its hash, with C<tool_calls> counted by name. Adds
C<cached_tokens> and C<cache_write_tokens> when the installed L<Langertha::Usage> reads them.
Optional C<provider>, C<started_at>, C<finished_at> and C<pricing_version> are carried into the
record. The C<metrics.normalize> function calls it; the proxy runs it on every upstream answer,
streamed or not.

=head2 worker_max_conns

  my $share = $skeid->worker_max_conns($node);

This process's share of a node's C<max_conns> (ADR 0010, ADR 0012). With one worker and one
frontend that is the configured value; otherwise it is the configured value divided by the
number of processes sharing the node — C<frontend_count> separate Skeid hosts times the
C<worker_count> prefork workers of this one — so the group as a whole never admits more than was
asked for.

Never less than 1 when a limit is set: a process that may admit nothing is a process that does
nothing. That means a C<max_conns> below that combined process count cannot be honoured, and
L</worker_share_warnings> is what says so out loud.

=head2 worker_share_warnings

  warn $_ for @{ $skeid->worker_share_warnings };

The nodes whose C<max_conns> cannot be divided among the processes sharing them without
exceeding it — C<frontend_count> frontends times C<worker_count> workers. Returned rather than
warned so the caller decides where they go; C<bin/skeid> prints them at startup.

Silence here would be the bad kind: the operator wrote a number, and the process group is about
to ignore it.

=head2 set_model_alias

  $skeid->set_model_alias('our-fast-model', {
    tiers => [
      { tags => ['local'], model => 'qwen3-32b',              wait_ms => 200 },
      { tags => ['cloud'], model => 'llama-3.3-70b-versatile' },
    ],
  });

Defines a client-facing model name as an ordered list of tiers. A bare arrayref of tiers is
accepted as shorthand for C<< { tiers => [...] } >>.

Per tier: C<tags> selects nodes, C<model> is the model actually asked of them (defaulting to
the alias name itself, for the case where nodes carry that name), C<engine> optionally
constrains the engine, and C<wait_ms> is how long to wait for capacity in this tier before
falling through to the next.

C<wait_ms> defaults to B<0>. Writing tiers means "try here, then there"; waiting is the
exception you opt into, and a tier that waits by default would send traffic to a paid cloud
only after a delay nobody asked for -- or, worse, make a cheap tier look slow.

=head2 set_policy

  $skeid->set_policy('standard-local-only', { deny_tags => ['cloud'] });

Defines a named policy profile. Profiles are the "standard setups" most customers take
unchanged; a customer needing something precise gets the profile plus overrides, or a profile
of their own.

=head2 resolve_policy

  my $policy = $skeid->resolve_policy({ models => ['house-model'], deny_tags => ['cloud'] });

Turns a policy spec into the immutable form routing uses: C<models> (or C<aliases>) becomes a
lookup hash of the requested model names the key may ask for, absent meaning all of them, and
C<deny_tags> becomes a normalized tag list.

=head2 key_id_for_key

  my $id = Langertha::Skeid->key_id_for_key('sk-alice-secret');   # k_5f0e...

The customer key id derived from the presented API key. This is the name a C<keys:> entry has
to use, and C<skeid keyid> prints it, because the config must be able to name a customer
without holding that customer's key.

It is the full SHA-1 hex digest of the key (160 bits), not a secret: it identifies, it does not
authenticate. What authenticates is that the caller presented the key it was derived from.

Before ADR 0016 the id was the first 12 hex digits of the same digest (C<k_5f0e1a2b3c4d>), so
an old id is the prefix of the new one. A config may still name a customer by its short id:
it matches the key whose full id starts with it, with a one-time deprecation warning at
config load, and a config that lists both a short id and a full id it is the prefix of fails
to load. Usage events keep the id they were recorded under -- events from before the change
carry the short id, later ones the full id; nothing is migrated.

=head2 policy_for_key

  my $policy = $skeid->policy_for_key($key_id);   # k_5f0e...

The policy a customer key routes under. Unlisted keys take the default policy, which is what
makes a deployment with ten thousand identically-configured customers a config with zero key
entries. Returns undef when no policies are configured at all.

=head2 key_id_for_name

  my $id = $skeid->key_id_for_name('alice');   # k_5f0e1a2b3c4de5f60718293a4b5c6d7e8f901a2b, or undef

The customer key id a readable name maps to under the config C<names:> section, or undef when
the name is not registered. The registry is a config-authoring convenience -- it lets a
C<keys:> entry be written by name and confines key rotation to one line -- and is resolved to
ids at config load, so it never appears on the request path.

=head2 route_plan

  my $plan = $skeid->route_plan(model => 'our-fast-model', api_key_id => $key_id);
  # { tiers => [...], permitted => 1, reason => '' }

The ordered tiers to try for a requested model, under the policy of the key that asked. A model
with no alias yields a single implicit tier that selects on the name itself and inherits the
global C<route_wait_timeout_ms>, which is what makes an aliasless config behave exactly as it
did before aliases existed.

C<permitted> is false when the policy does not grant this model, or when every tier of it was
denied. Both mean the same thing to a caller — this key may not reach this model — and neither
is a capacity problem, so they must not be reported as one.

Tiers carry the policy's C<deny_tags> down into node selection. Dropping a denied tier is only
the reporting half; without the node-level filter, a key denied C<cloud> could still reach a
cloud node by asking for its raw model name instead of the alias.

=head2 select_nodes

  my $local = $skeid->select_nodes(tags => ['local']);

Nodes carrying every listed tag, as copies. No tags selects everything. Selection is by tag,
never by node id, so a config can talk about C<local> or C<cloud> without naming machines.
C<deny_tags> drops every node carrying any of those tags. Health is not considered. The
C<nodes.select> function calls it.

=head2 pick_node

  my $node = $skeid->pick_node(model => 'qwen3-32b', tags => ['local'], deny_tags => ['cloud']);

The next node for a selection by weighted round-robin (over the eligible nodes, ordered by id),
skipping every node admission would refuse right now. Returns a copy of the node with
C<inflight> and C<route_key> added, or nothing. Picking does not admit: the caller still has to
L</start_request>, which can refuse when another request took the slot in between. The
C<route.next> function calls it.

=head2 route_state

  my $state = $skeid->route_state(model => 'qwen3-32b', tags => ['local']);
  # { model, engine, tags, deny_tags, eligible_count, available_count,
  #   has_eligible, has_available }

How many nodes a selection matches (eligible) and how many of those admission would take now
(available). No eligible node is a C<503>; eligible but none available is worth waiting for. The
C<route.state> function calls it.

=head2 set_capacity_reading

  $skeid->set_capacity_reading('gpu-1', used => 6, limit => 8, source => 'prometheus');
  $skeid->set_capacity_reading('groq-1', retry_after_ms => 2000, source => 'ratelimit');

Records what a probe found. One shape for every probe, so admission never learns where a
number came from (ADR 0009):

=over 4

=item * C<used> / C<limit> — occupancy. C<limit> 0 or absent means the probe measured
something it cannot turn into a ceiling, so it does not constrain admission.

=item * C<retry_after_ms> — do not send anything here until it elapses. What a C<429> means.

=item * C<source> — which probe, for reports. Never consulted by admission. C<quota> -- which of
a provider's quotas (C<requests>, C<tokens>) the reading is about -- likewise.

=item * C<at> — when the reading was taken (default now), and C<expires_at> — an absolute
moment after which it is dropped even inside L</capacity_max_age_ms>. The registry probe uses
both: a snapshot is as old as its C<generated_at>, and never outlives its own C<ttl>.

=item * C<interval_ms> — how often this source reports, for a probe on a timer. Stored with the
reading; it sets how long a tighter reading can hold a looser one from another source off
(below). A passive observation (a response's rate-limit headers) passes none.

=back

A reading only ever narrows what C<max_conns> already allows, and expires after
L</capacity_max_age_ms>. Probing is a background activity: calling this from a request handler
is a bug unless the reading was a by-product of a response already in hand.

B<The tighter reading wins across sources, while it is current> (ADR 0017). A source always
replaces its own last reading. A reading from a different source is held off by the current one
only when the current one is tighter (a pending backoff is tightest, then C<used/limit>, then a
reading without a limit) B<and> either

=over 4

=item * it carries a pending backoff, or

=item * it is younger than the longer of the two sources' C<interval_ms> -- neither has had a
full poll since the tighter reading was taken.

=back

Otherwise the incoming reading replaces it. So a registry snapshot saying "empty" cannot lift a
C<429> backoff a response just recorded; a fresh, tight probe reading is not lifted by a roomy
response or by a faster, looser probe before its own next poll; and a passive reading that is
never refreshed (C<remaining: 0> with no reset, from the last response before traffic stopped)
cannot keep a fresh probe out for longer than one of that probe's polls. Returns the reading in
force afterwards.

=head2 capacity_reading

  my $reading = $skeid->capacity_reading('gpu-1');   # or nothing

The node's current capacity reading, or nothing when no probe has reported or the last report
has aged out. A backoff outlives the age limit: a provider that said "not for another 30
seconds" told us something that is still true.

=head2 forget_capacity

  $skeid->forget_capacity('gpu-1');   # or all of them with no argument
  $skeid->forget_capacity('gpu-1', source => 'registry');   # only if that source holds it

Drops probe readings, so C<inflight> decides again. What a node removal calls, and what a probe
calls when it can no longer reach its source — reporting nothing beats reporting last hour.

With C<source>, the reading is dropped only when that source wrote it. A probe forgetting what
I<it> said must not wipe a backoff another source recorded (ADR 0017).

=head2 capacity_header_names

The response headers worth looking at, so a caller on the request path can pull those few by
name instead of walking every header of every response.

=head2 observe_response_headers

  $skeid->observe_response_headers('groq-1', \%headers, status => 429);

The zero-cost probe: commercial providers do not publish queue depth, but they do put their
rate-limit state on every response Skeid already receives. Reading it costs no extra request
(ADR 0009).

Providers meter requests and tokens separately, and for an LLM API the token budget is usually
what runs out first. Both are read, and the one closest to exhausted decides — compared as a
fraction, since the two are not the same unit.

C<Retry-After> on a C<429> becomes a backoff. It deliberately does B<not> touch C<healthy>:
rate-limited is busy, not broken, and nothing would ever flip that back.

Returns the reading it recorded, or nothing when the response said nothing useful.

=head2 start_request

  $skeid->start_request('gpu-1') or ...;   # refused

Admits one request to a node and counts it in C<inflight>. Returns 1 when admitted, 0 when the
node is unknown, unhealthy or full. B<Every> 1 must be paired with a L</finish_request> on every
path -- errors, timeouts, client aborts -- or the node loses that slot until restart. The
C<request.start> function calls it.

=head2 finish_request

  $skeid->finish_request('gpu-1', ok => 1, duration_ms => 840);
  $skeid->finish_request('gpu-1', aborted => 1);   # the client hung up

Releases the slot L</start_request> took and counts the outcome for L</node_metrics>. There are
three outcomes: C<ok>, failed (neither C<ok> nor C<aborted>), and C<aborted> -- the client went
away, which says nothing about the node. A failed request counts toward the registry snapshot's
C<errors_in_window> and C<last_failure_at>; an aborted one is counted apart and toward neither.
C<aborted> wins over C<ok>. Never touches C<healthy>. Returns 1. The C<request.finish> function calls it.

=head2 registry_snapshot

  my $snapshot = $skeid->registry_snapshot;

What this Skeid publishes to a fronting tier (ADR 0017): schema C<version> 1, C<instance>,
C<generated_at>, C<ttl>, C<workers>, and per node C<id>, C<tags>, C<healthy>, C<inflight>,
C<max_conns> (this process's share), C<errors_in_window>, C<last_failure_at> and, when a
current reading exists, C<capacity> (C<used>, C<limit>, C<source>, C<retry_after>).

Built from a whitelist, so it cannot carry what it must not: no node URL, no key reference, no
metadata, no customer key id, no policy, no usage. L<Langertha::Skeid::Registry> signs it.

=head2 node_metrics

  my $one = $skeid->node_metrics('gpu-1');
  my $all = $skeid->node_metrics;

Volatile per-process counters for operations, never billed: C<node_id>, C<inflight>,
C<started>, C<ok>, C<error>, C<aborted>, C<duration_ms_total>, and C<capacity> while a current reading
exists. With no id, an arrayref with one entry per node. Served by C<GET /skeid/metrics/nodes>.

=head2 call_function

  my $result = $skeid->call_function('route.plan', { model => 'house-model', api_key_id => $id });

The command surface the proxy drives Skeid through. Every call first runs
L</maybe_reload_config>. Croaks on an unknown name, on args that are not a hashref, and where a
function names a required argument.

  function            args                                  returns
  metrics.estimate_cost  as estimate_cost                   estimate_cost
  metrics.normalize   as normalize_metrics                  normalize_metrics
  pricing.set         model, pricing                        the stored rule
  nodes.add           a node                                { ok }
  nodes.remove        id                                    { ok }
  nodes.list                                                { nodes }
  nodes.select        tags, deny_tags                       { nodes } (select_nodes)
  nodes.set_health    id, healthy                           { ok }
  nodes.metrics       id (optional)                         { metrics }
  alias.set           name, alias (or the tiers inline)     { ok }
  policy.set          name, policy (or the spec inline)     { ok }
  policy.for_key      api_key_id                            { policy }
  route.plan          model, engine, api_key_id             route_plan
  route.next          model, engine, tags, deny_tags        { node } (pick_node)
  route.state         model, engine, tags, deny_tags        route_state
  capacity.set        id, and the reading                   { capacity }
  capacity.get        id                                    { capacity }
  capacity.observe    id, headers, status                   { capacity }
  capacity.forget     id (optional)                         { ok }
  request.start       id                                    { ok }
  request.finish      id, ok|aborted, duration_ms                 { ok }
  config.reload                                             { config } (dies on failure)
  config.status                                             reload_status
  usage.record        as record_usage                       record_usage
  usage.report        since, api_key_id, model, limit       usage_report
  usage.configure     usage_store (or the config inline)    { usage_store }
  engines.list                                              { engines }

Add a function here rather than reaching into the object from the app.

=head1 SEE ALSO

=over 4

=item * L<Langertha::Skeid::Proxy> -- the HTTP application on top of this control plane, and its routes

=item * L<skeid> -- C<serve>, C<usage> and C<keyid>

=item * L<Langertha::Skeid::CapacityProbe> -- node capacity probes

=item * L<Langertha::Skeid::UsageStore> -- where usage events go

=item * L<Langertha::Skeid::KeyBroker> -- resolving a node's C<api_key_ref>

=item * L<Langertha::Skeid::Registry> -- the signed Skeid-to-Skeid snapshot

=item * L<Langertha> -- engines, usage, pricing

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
