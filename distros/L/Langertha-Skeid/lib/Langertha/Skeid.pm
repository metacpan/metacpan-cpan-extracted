package Langertha::Skeid;
our $VERSION = '0.001';
# ABSTRACT: Dynamic routing control-plane for multi-node LLM serving with normalized metrics and cost accounting
use Moo;
use strict;
use warnings;
use Carp qw(croak);
use POSIX qw(strftime);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::ShareDir qw(dist_dir);
use YAML::PP;
use JSON::MaybeXS qw(encode_json decode_json);
use Langertha ();
use Langertha::Knarr::Metrics;


has nodes => (
  is      => 'rw',
  default => sub { [] },
);

has model_pricing => (
  is      => 'rw',
  default => sub { {} },
);

has route_wait_timeout_ms => (
  is      => 'rw',
  default => sub {
    return (defined($ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS}) && length($ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS}))
      ? 0 + $ENV{SKEID_ROUTE_WAIT_TIMEOUT_MS}
      : 2000;
  },
);

has route_wait_poll_ms => (
  is      => 'rw',
  default => sub {
    return (defined($ENV{SKEID_ROUTE_WAIT_POLL_MS}) && length($ENV{SKEID_ROUTE_WAIT_POLL_MS}))
      ? 0 + $ENV{SKEID_ROUTE_WAIT_POLL_MS}
      : 25;
  },
);

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

has admin_api_key => (
  is      => 'rw',
  default => sub {
    return (defined($ENV{SKEID_ADMIN_API_KEY}) && length($ENV{SKEID_ADMIN_API_KEY}))
      ? $ENV{SKEID_ADMIN_API_KEY}
      : '';
  },
);

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

has _rr_cursor => (
  is      => 'rw',
  default => sub { {} },
);

has _inflight => (
  is      => 'rw',
  default => sub { {} },
);

has _stats => (
  is      => 'rw',
  default => sub { {} },
);

has _usage_dbh_cached => (
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

sub BUILD {
  my ($self) = @_;
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
  $self->_ensure_usage_schema_if_enabled;
}

sub add_node {
  my ($self, %node) = @_;
  my $id  = $node{id}  // croak 'node id required';
  my $url = $node{url} // croak 'node url required';

  $self->remove_node($id);
  push @{$self->nodes}, {
    id          => $id,
    url         => $url,
    model       => ($node{model} // ''),
    engine      => $self->normalize_engine_id((defined($node{engine}) && length($node{engine})) ? $node{engine} : 'OpenAIBase'),
    weight      => (defined $node{weight} ? 0 + $node{weight} : 1),
    max_conns   => (defined $node{max_conns} ? 0 + $node{max_conns} : 0),
    healthy     => (exists $node{healthy} ? ($node{healthy} ? 1 : 0) : 1),
    metadata    => (ref($node{metadata}) eq 'HASH' ? $node{metadata} : {}),
    (defined($node{api_key_env}) && length($node{api_key_env})
      ? (api_key_env => "$node{api_key_env}")
      : ()),
  };
  return 1;
}

sub remove_node {
  my ($self, $id) = @_;
  return 0 unless defined $id && length $id;
  my @keep = grep { ($_->{id} // '') ne $id } @{$self->nodes};
  my $removed = @{$self->nodes} - @keep;
  $self->nodes(\@keep);
  return $removed ? 1 : 0;
}

sub list_nodes {
  my ($self) = @_;
  return [ map { +{%$_} } @{$self->nodes} ];
}

sub set_node_health {
  my ($self, $id, $healthy) = @_;
  return 0 unless defined $id && length $id;
  my $found = 0;
  for my $n (@{$self->nodes}) {
    next unless ($n->{id} // '') eq $id;
    $n->{healthy} = $healthy ? 1 : 0;
    $found = 1;
    last;
  }
  return $found;
}

sub set_model_pricing {
  my ($self, $model, $pricing) = @_;
  croak 'model required' unless defined $model && length $model;
  croak 'pricing hash required' unless ref($pricing) eq 'HASH';
  $self->model_pricing->{$model} = {
    input_per_million  => 0 + ($pricing->{input_per_million}  // 0),
    output_per_million => 0 + ($pricing->{output_per_million} // 0),
  };
  return $self->model_pricing->{$model};
}

sub pricing_for_model {
  my ($self, $model) = @_;
  return $self->model_pricing->{$model}
    || $self->model_pricing->{'*'}
    || { input_per_million => 0, output_per_million => 0 };
}

sub reload_config {
  my ($self) = @_;
  my $cfg = {};

  if ($self->has_config_loader) {
    my $loaded = $self->config_loader->($self);
    $cfg = $loaded if ref($loaded) eq 'HASH';
  } elsif ($self->has_config_file) {
    my $file = $self->config_file;
    if (-f $file) {
      my $ypp = YAML::PP->new;
      my $loaded = $ypp->load_file($file);
      $cfg = $loaded if ref($loaded) eq 'HASH';
      $self->_config_mtime((stat($file))[9] || time);
    }
  }

  if (ref($cfg->{pricing}) eq 'HASH') {
    for my $model (keys %{$cfg->{pricing}}) {
      my $p = $cfg->{pricing}{$model};
      next unless ref($p) eq 'HASH';
      $self->set_model_pricing($model, $p);
    }
  }

  if (ref($cfg->{nodes}) eq 'ARRAY') {
    $self->nodes([]);
    for my $n (@{$cfg->{nodes}}) {
      next unless ref($n) eq 'HASH';
      next unless defined $n->{id} && defined $n->{url};
      $self->add_node(%$n);
    }
  }

  if (ref($cfg->{routing}) eq 'HASH') {
    if (defined $cfg->{routing}{wait_timeout_ms}) {
      $self->route_wait_timeout_ms(0 + $cfg->{routing}{wait_timeout_ms});
    }
    if (defined $cfg->{routing}{wait_poll_ms}) {
      my $poll = 0 + $cfg->{routing}{wait_poll_ms};
      $poll = 1 if $poll < 1;
      $self->route_wait_poll_ms($poll);
    }
  }

  if (exists $cfg->{admin_api_key}) {
    $self->admin_api_key(defined($cfg->{admin_api_key}) ? "$cfg->{admin_api_key}" : '');
  } elsif (ref($cfg->{admin}) eq 'HASH') {
    $self->admin_api_key(defined($cfg->{admin}{api_key}) ? "$cfg->{admin}{api_key}" : '');
  } elsif ($self->has_config_loader || $self->has_config_file) {
    # Config-managed mode: absent key means admin API is disabled.
    $self->admin_api_key('');
  }

  my $usage_cfg = $cfg->{usage_store};
  if (ref($usage_cfg) eq 'HASH') {
    $self->_configure_usage_store($usage_cfg);
  } elsif (exists $cfg->{usage_db_path}) {
    $self->_configure_usage_store({
      backend     => 'sqlite',
      sqlite_path => $cfg->{usage_db_path},
    });
  }

  return $cfg;
}

sub maybe_reload_config {
  my ($self) = @_;

  if ($self->has_config_loader && !$self->has_config_file) {
    # Loader-based configs are treated as dynamic and refreshed every task.
    $self->reload_config;
    return 1;
  }

  return 0 unless $self->has_config_file;
  my $file = $self->config_file;
  return 0 unless -f $file;

  my $mtime = (stat($file))[9] || 0;
  my $last  = $self->_config_mtime;
  if (!defined($last) || $mtime > $last) {
    $self->reload_config;
    return 1;
  }
  return 0;
}

sub configure_usage_store {
  my ($self, $cfg) = @_;
  return $self->_configure_usage_store($cfg);
}

sub _dist_root {
  my $root = dirname(dirname(dirname(__FILE__)));
  return $root;
}

sub _schema_file_for_backend {
  my ($self, $backend) = @_;
  my $name = ($backend eq 'postgresql') ? 'usage_events.postgresql.sql' : 'usage_events.sqlite.sql';
  my @candidates;

  # Installed/runtime lookup via dist sharedir.
  my $share_dir = eval { dist_dir('Langertha-Skeid') };
  if (!$@ && defined($share_dir) && length($share_dir)) {
    push @candidates, File::Spec->catfile($share_dir, 'sql', $name);
  }

  # Dev + dzil test fallback from repository/build paths.
  my $dir = _dist_root();
  for (1 .. 6) {
    push @candidates, File::Spec->catfile($dir, 'share', 'sql', $name);
    push @candidates, File::Spec->catfile($dir, 'sql', $name);
    my $parent = dirname($dir);
    last if !defined($parent) || $parent eq $dir;
    $dir = $parent;
  }

  for my $path (@candidates) {
    return $path if -f $path;
  }

  return $candidates[0];
}

sub _read_text_file {
  my ($path) = @_;
  open my $fh, '<', $path or die "Cannot open $path: $!";
  local $/;
  my $text = <$fh>;
  close $fh;
  return $text;
}

sub _apply_schema_sql {
  my ($dbh, $sql) = @_;
  my @stmts = grep { /\S/ } map {
    my $s = $_;
    $s =~ s/^\s+//;
    $s =~ s/\s+$//;
    $s;
  } split /;\s*(?:\n|$)/, $sql;
  for my $stmt (@stmts) {
    $dbh->do($stmt);
  }
  return 1;
}

sub _configure_usage_store {
  my ($self, $cfg) = @_;
  $cfg ||= {};
  croak 'usage_store must be a hashref' unless ref($cfg) eq 'HASH';

  my $backend = lc($cfg->{backend} // '');
  $backend = 'sqlite' if !$backend && (defined($cfg->{sqlite_path}) || defined($cfg->{path}) || defined($cfg->{db_path}));
  $backend = 'postgresql' if !$backend && defined($cfg->{dsn}) && $cfg->{dsn} =~ /^dbi:Pg:/i;
  $backend = 'jsonlog' if !$backend && defined($cfg->{log_path});
  $backend = 'sqlite' unless length $backend;
  $backend = 'postgresql' if $backend =~ /^postgres/;
  $backend = 'jsonlog' if $backend =~ /^json/;

  my $normalized;
  if ($backend eq 'sqlite') {
    my $path = $cfg->{sqlite_path} // $cfg->{path} // $cfg->{db_path} // ($self->has_usage_db_path ? $self->usage_db_path : undef);
    if (!defined($path) || !length($path)) {
      croak 'usage_store.sqlite_path (or path/db_path) is required for sqlite backend';
    }
    $normalized = {
      backend      => 'sqlite',
      path         => $path,
      dsn          => "dbi:SQLite:dbname=$path",
      user         => '',
      password     => '',
      schema_file  => ($cfg->{schema_file} // ''),
      auto_migrate => exists($cfg->{auto_migrate}) ? ($cfg->{auto_migrate} ? 1 : 0) : 1,
    };
  } elsif ($backend eq 'postgresql') {
    my $dsn = $cfg->{dsn};
    if (!defined($dsn) || !length($dsn)) {
      my $host = $cfg->{host} // '127.0.0.1';
      my $port = $cfg->{port} // 5432;
      my $name = $cfg->{dbname} // $cfg->{database} // 'skeid';
      $dsn = "dbi:Pg:dbname=$name;host=$host;port=$port";
    }
    my $user = $cfg->{user} // '';
    my $password = defined($cfg->{password}) ? $cfg->{password} : '';
    if (!length($password) && defined($cfg->{password_env}) && length($cfg->{password_env})) {
      $password = $ENV{$cfg->{password_env}} // '';
    }
    $normalized = {
      backend      => 'postgresql',
      path         => '',
      dsn          => $dsn,
      user         => $user,
      password     => $password,
      schema_file  => ($cfg->{schema_file} // ''),
      auto_migrate => exists($cfg->{auto_migrate}) ? ($cfg->{auto_migrate} ? 1 : 0) : 1,
    };
  } elsif ($backend eq 'jsonlog') {
    my $path = $cfg->{log_path} // $cfg->{path} // '';
    croak 'usage_store.log_path (or path) is required for jsonlog backend' unless length $path;
    my $mode = $cfg->{mode} // '';
    if (!length($mode)) {
      $mode = (-d $path || $path =~ m{/$}) ? 'dir' : 'file';
    }
    $normalized = {
      backend => 'jsonlog',
      path    => $path,
      mode    => $mode,
    };
  } else {
    croak "unsupported usage_store backend '$backend'";
  }

  my $old = $self->usage_store || {};
  my $same = ref($old) eq 'HASH'
    && (($old->{backend} // '') eq ($normalized->{backend} // ''))
    && (($old->{dsn} // '') eq ($normalized->{dsn} // ''))
    && (($old->{user} // '') eq ($normalized->{user} // ''))
    && (($old->{password} // '') eq ($normalized->{password} // ''))
    && (($old->{schema_file} // '') eq ($normalized->{schema_file} // ''))
    && ((($old->{auto_migrate} // 1) ? 1 : 0) == (($normalized->{auto_migrate} // 1) ? 1 : 0));

  my $changed = $same ? 0 : 1;
  unless ($same) {
    $self->_disconnect_usage_dbh;
    $self->usage_store($normalized);
  }

  if ($normalized->{backend} eq 'sqlite') {
    $self->usage_db_path($normalized->{path});
  } elsif ($normalized->{backend} ne 'jsonlog') {
    $self->clear_usage_db_path if $self->has_usage_db_path;
  }

  if ($normalized->{backend} eq 'jsonlog') {
    my $path = $normalized->{path};
    if ($normalized->{mode} eq 'dir') {
      make_path($path) unless -d $path;
    } else {
      my $dir = dirname($path);
      make_path($dir) if length($dir) && $dir ne '.' && !-d $dir;
    }
  } else {
    $self->_ensure_usage_schema_if_enabled if $changed || !$self->_usage_dbh_cached;
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

sub _usage_backend {
  my ($self) = @_;
  my $store = $self->usage_store || {};
  if (ref($store) eq 'HASH' && defined($store->{backend}) && length($store->{backend})) {
    return $store->{backend};
  }
  my $path = $self->usage_db_path;
  return (defined($path) && length($path)) ? 'sqlite' : '';
}

sub _usage_dsn {
  my ($self) = @_;
  my $store = $self->usage_store || {};
  if (ref($store) eq 'HASH' && defined($store->{dsn}) && length($store->{dsn})) {
    return $store->{dsn};
  }
  my $path = $self->usage_db_path;
  return (defined($path) && length($path)) ? ('dbi:SQLite:dbname=' . $path) : '';
}

sub _usage_dbh {
  my ($self) = @_;
  my $cached = $self->_usage_dbh_cached;
  return $cached if $cached;

  my $backend = $self->_usage_backend;
  my $dsn = $self->_usage_dsn;
  return unless length($backend) && length($dsn);

  eval { require DBI } or return;

  my $store = $self->usage_store || {};
  my $user = (ref($store) eq 'HASH' ? ($store->{user} // '') : '');
  my $password = (ref($store) eq 'HASH' ? ($store->{password} // '') : '');

  if ($backend eq 'sqlite') {
    my $path = (ref($store) eq 'HASH' ? ($store->{path} // $self->usage_db_path) : $self->usage_db_path);
    my $dir = dirname($path);
    if (defined $dir && length $dir && $dir ne '.' && !-d $dir) {
      make_path($dir);
    }
  }

  my %connect_attr = (
    RaiseError => 1,
    PrintError => 0,
    AutoCommit => 1,
  );
  $connect_attr{sqlite_unicode} = 1 if $backend eq 'sqlite';

  my $dbh = DBI->connect($dsn, $user, $password, \%connect_attr);
  $self->_usage_dbh_cached($dbh);
  return $dbh;
}

sub _disconnect_usage_dbh {
  my ($self) = @_;
  my $dbh = $self->_usage_dbh_cached or return;
  eval { $dbh->disconnect };
  $self->_usage_dbh_cached(undef);
  return;
}

sub _ensure_usage_schema_if_enabled {
  my ($self) = @_;
  my $backend = $self->_usage_backend;
  return unless length $backend;
  my $dbh = $self->_usage_dbh or return;

  my $store = $self->usage_store || {};
  my $auto_migrate = (ref($store) eq 'HASH' && exists($store->{auto_migrate}))
    ? ($store->{auto_migrate} ? 1 : 0)
    : 1;
  return 1 unless $auto_migrate;

  my $schema_file = (ref($store) eq 'HASH' ? ($store->{schema_file} // '') : '');
  $schema_file = $self->_schema_file_for_backend($backend) unless length $schema_file;
  croak "usage schema file not found: $schema_file" unless -f $schema_file;

  my $sql = _read_text_file($schema_file);
  _apply_schema_sql($dbh, $sql);
  return 1;
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

  my $metrics = ref($args{metrics}) eq 'HASH' ? $args{metrics} : {};
  my $usage = ref($metrics->{usage}) eq 'HASH' ? $metrics->{usage} : {};
  my $tool_calls = ref($metrics->{tool_names}) eq 'ARRAY'
    ? scalar(@{$metrics->{tool_names}})
    : _num($metrics->{tool_calls});
  my $input_tokens  = _num($usage->{input}) || _num($usage->{prompt_tokens}) || _num($metrics->{input_tokens});
  my $output_tokens = _num($usage->{output}) || _num($usage->{completion_tokens}) || _num($metrics->{output_tokens});
  my $total_tokens  = _num($usage->{total}) || _num($metrics->{total_tokens}) || ($input_tokens + $output_tokens);
  my $cost_input    = _num($metrics->{cost_input_usd}) || _num($metrics->{input_cost_usd});
  my $cost_output   = _num($metrics->{cost_output_usd}) || _num($metrics->{output_cost_usd});
  my $cost_total    = _num($metrics->{cost_total_usd}) || _num($metrics->{total_cost_usd});

  my %event = (
    created_at    => ($args{created_at} // _iso8601_now()),
    request_id    => ($args{request_id} // ''),
    api_format    => ($args{api_format} // ''),
    endpoint      => ($args{endpoint} // ''),
    api_key_id    => ($args{api_key_id} // ''),
    provider      => ($args{provider} // ''),
    engine        => ($args{engine} // ''),
    model         => ($args{model} // ''),
    node_id       => ($args{node_id} // ''),
    route_url     => ($args{route_url} // ''),
    status_code   => (_num($args{status_code}) || 0),
    ok            => ($args{ok} ? 1 : 0),
    duration_ms   => (_num($args{duration_ms}) || 0),
    input_tokens  => $input_tokens,
    output_tokens => $output_tokens,
    total_tokens  => $total_tokens,
    tool_calls    => _num($tool_calls),
    cost_input_usd  => $cost_input,
    cost_output_usd => $cost_output,
    cost_total_usd  => $cost_total,
    error_type    => ($args{error_type} // ''),
    error_message => ($args{error_message} // ''),
  );

  return $self->_store_usage_event(\%event);
}

sub _store_usage_event {
  my ($self, $event) = @_;
  return $self->store_usage_event->($self, $event) if $self->has_store_usage_event;
  my $backend = $self->_usage_backend;
  return { ok => 0, error => 'usage_store not configured' } unless length $backend;

  return $self->_store_usage_event_jsonlog($event) if $backend eq 'jsonlog';

  my $dbh = eval { $self->_usage_dbh };
  if (!$dbh || $@) {
    my $err = $@ || 'failed to connect usage database';
    $err =~ s/\s+$//;
    return { ok => 0, error => $err };
  }

  my $sth = $dbh->prepare_cached(q{
    INSERT INTO usage_events (
      created_at, request_id, api_format, endpoint, api_key_id, provider, engine, model, node_id, route_url,
      status_code, ok, duration_ms, input_tokens, output_tokens, total_tokens, tool_calls,
      cost_input_usd, cost_output_usd, cost_total_usd, error_type, error_message
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  });
  $sth->execute(
    $event->{created_at},
    $event->{request_id},
    $event->{api_format},
    $event->{endpoint},
    $event->{api_key_id},
    $event->{provider},
    $event->{engine},
    $event->{model},
    $event->{node_id},
    $event->{route_url},
    $event->{status_code},
    $event->{ok},
    $event->{duration_ms},
    $event->{input_tokens},
    $event->{output_tokens},
    $event->{total_tokens},
    $event->{tool_calls},
    $event->{cost_input_usd},
    $event->{cost_output_usd},
    $event->{cost_total_usd},
    $event->{error_type},
    $event->{error_message},
  );

  my %out = (ok => 1);
  if ($backend eq 'sqlite' && $dbh->can('sqlite_last_insert_rowid')) {
    $out{id} = _num($dbh->sqlite_last_insert_rowid);
  }
  return \%out;
}

sub _jsonlog_event_id {
  my $ts = strftime('%Y%m%d-%H%M%S', gmtime());
  my $rand = sprintf('%06d', int(rand(1_000_000)));
  return "${ts}-${rand}";
}

sub _store_usage_event_jsonlog {
  my ($self, $event) = @_;
  my $store = $self->usage_store || {};
  my $path = $store->{path} // '';
  my $mode = $store->{mode} // 'dir';

  my $id = _jsonlog_event_id();
  my $json = encode_json({ %$event, id => $id });

  if ($mode eq 'dir') {
    my $file = File::Spec->catfile($path, "${id}.json");
    open my $fh, '>', $file or return { ok => 0, error => "Cannot write $file: $!" };
    print $fh $json, "\n";
    close $fh;
  } else {
    open my $fh, '>>', $path or return { ok => 0, error => "Cannot append $path: $!" };
    flock($fh, 2); # LOCK_EX
    print $fh $json, "\n";
    close $fh;
  }

  return { ok => 1, id => $id };
}

sub _query_usage_report_jsonlog {
  my ($self, $filters) = @_;
  my $store = $self->usage_store || {};
  my $path = $store->{path} // '';
  my $mode = $store->{mode} // 'dir';

  my @events;
  if ($mode eq 'dir') {
    my @files = sort glob(File::Spec->catfile($path, '*.json'));
    for my $file (@files) {
      my $text = eval { _read_text_file($file) };
      next unless defined $text;
      my $ev = eval { decode_json($text) };
      push @events, $ev if ref($ev) eq 'HASH';
    }
  } else {
    if (open my $fh, '<', $path) {
      while (my $line = <$fh>) {
        chomp $line;
        next unless length $line;
        my $ev = eval { decode_json($line) };
        push @events, $ev if ref($ev) eq 'HASH';
      }
      close $fh;
    }
  }

  # Apply filters
  if (defined $filters->{since} && length $filters->{since}) {
    @events = grep { ($_->{created_at} // '') ge $filters->{since} } @events;
  }
  if (defined $filters->{api_key_id} && length $filters->{api_key_id}) {
    @events = grep { ($_->{api_key_id} // '') eq $filters->{api_key_id} } @events;
  }
  if (defined $filters->{model} && length $filters->{model}) {
    @events = grep { ($_->{model} // '') eq $filters->{model} } @events;
  }

  # Aggregate
  my %totals = (requests => 0, input_tokens => 0, output_tokens => 0, total_tokens => 0, tool_calls => 0, total_cost_usd => 0);
  my (%by_key, %by_model);
  for my $ev (@events) {
    $totals{requests}++;
    $totals{input_tokens}  += _num($ev->{input_tokens});
    $totals{output_tokens} += _num($ev->{output_tokens});
    $totals{total_tokens}  += _num($ev->{total_tokens});
    $totals{tool_calls}    += _num($ev->{tool_calls});
    $totals{total_cost_usd} += _num($ev->{cost_total_usd});

    my $kid = $ev->{api_key_id} // '';
    $by_key{$kid}{requests}++;
    $by_key{$kid}{total_tokens}   += _num($ev->{total_tokens});
    $by_key{$kid}{total_cost_usd} += _num($ev->{cost_total_usd});

    my $mid = $ev->{model} // '';
    $by_model{$mid}{requests}++;
    $by_model{$mid}{total_tokens}   += _num($ev->{total_tokens});
    $by_model{$mid}{total_cost_usd} += _num($ev->{cost_total_usd});
  }

  my $limit = $filters->{limit} // 20;
  my @recent = reverse @events;
  @recent = @recent[0 .. $limit - 1] if @recent > $limit;

  return {
    ok      => 1,
    enabled => 1,
    backend => 'jsonlog',
    since   => ($filters->{since} // ''),
    totals  => \%totals,
    by_key  => [ map {
      +{ api_key_id => $_, requests => $by_key{$_}{requests}, total_tokens => $by_key{$_}{total_tokens}, total_cost_usd => $by_key{$_}{total_cost_usd} }
    } sort { ($by_key{$b}{total_cost_usd} || 0) <=> ($by_key{$a}{total_cost_usd} || 0) } keys %by_key ],
    by_model => [ map {
      +{ model => $_, requests => $by_model{$_}{requests}, total_tokens => $by_model{$_}{total_tokens}, total_cost_usd => $by_model{$_}{total_cost_usd} }
    } sort { ($by_model{$b}{total_cost_usd} || 0) <=> ($by_model{$a}{total_cost_usd} || 0) } keys %by_model ],
    recent  => [ map {
      +{
        id => ($_->{id} // ''), created_at => ($_->{created_at} // ''), api_format => ($_->{api_format} // ''),
        endpoint => ($_->{endpoint} // ''), api_key_id => ($_->{api_key_id} // ''), model => ($_->{model} // ''),
        node_id => ($_->{node_id} // ''), status_code => _num($_->{status_code}), ok => ($_->{ok} ? 1 : 0),
        input_tokens => _num($_->{input_tokens}), output_tokens => _num($_->{output_tokens}),
        total_tokens => _num($_->{total_tokens}), tool_calls => _num($_->{tool_calls}),
        cost_total_usd => _num($_->{cost_total_usd}),
      }
    } @recent ],
  };
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
  my $backend = $self->_usage_backend;
  return $self->_query_usage_report_jsonlog($filters) if $backend eq 'jsonlog';
  return { ok => 0, enabled => 0, error => 'usage_store not configured' } unless length $backend;

  my $dbh = eval { $self->_usage_dbh };
  if (!$dbh || $@) {
    my $err = $@ || 'failed to connect usage database';
    $err =~ s/\s+$//;
    return { ok => 0, enabled => 0, error => $err };
  }

  my $limit = $filters->{limit} // 20;

  my @where;
  my @bind;
  if (defined $filters->{since} && length $filters->{since}) {
    push @where, 'created_at >= ?';
    push @bind, $filters->{since};
  }
  if (defined $filters->{api_key_id} && length $filters->{api_key_id}) {
    push @where, 'api_key_id = ?';
    push @bind, $filters->{api_key_id};
  }
  if (defined $filters->{model} && length $filters->{model}) {
    push @where, 'model = ?';
    push @bind, $filters->{model};
  }

  my $where_sql = @where ? ('WHERE ' . join(' AND ', @where)) : '';

  my $totals = $dbh->selectrow_hashref(
    "SELECT
       COUNT(*) AS requests,
       COALESCE(SUM(input_tokens), 0) AS input_tokens,
       COALESCE(SUM(output_tokens), 0) AS output_tokens,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(tool_calls), 0) AS tool_calls,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events $where_sql",
    undef,
    @bind,
  ) || {};

  my $by_key = $dbh->selectall_arrayref(
    "SELECT
       COALESCE(api_key_id, '') AS api_key_id,
       COUNT(*) AS requests,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events
     $where_sql
     GROUP BY api_key_id
     ORDER BY total_cost_usd DESC, requests DESC",
    { Slice => {} },
    @bind,
  ) || [];

  my $by_model = $dbh->selectall_arrayref(
    "SELECT
       COALESCE(model, '') AS model,
       COUNT(*) AS requests,
       COALESCE(SUM(total_tokens), 0) AS total_tokens,
       COALESCE(SUM(cost_total_usd), 0) AS total_cost_usd
     FROM usage_events
     $where_sql
     GROUP BY model
     ORDER BY total_cost_usd DESC, requests DESC",
    { Slice => {} },
    @bind,
  ) || [];

  my $recent = $dbh->selectall_arrayref(
    "SELECT
       id, created_at, api_format, endpoint, api_key_id, model, node_id, status_code, ok,
       input_tokens, output_tokens, total_tokens, tool_calls, cost_total_usd
     FROM usage_events
     $where_sql
     ORDER BY id DESC
     LIMIT ?",
    { Slice => {} },
    @bind,
    $limit,
  ) || [];

  return {
    ok        => 1,
    enabled   => 1,
    backend   => $backend,
    db_path   => ($backend eq 'sqlite' ? ($self->usage_db_path // '') : ''),
    since     => ($filters->{since} // ''),
    totals    => {
      requests       => _num($totals->{requests}),
      input_tokens   => _num($totals->{input_tokens}),
      output_tokens  => _num($totals->{output_tokens}),
      total_tokens   => _num($totals->{total_tokens}),
      tool_calls     => _num($totals->{tool_calls}),
      total_cost_usd => _num($totals->{total_cost_usd}),
    },
    by_key   => [ map {
      +{
        api_key_id     => ($_->{api_key_id} // ''),
        requests       => _num($_->{requests}),
        total_tokens   => _num($_->{total_tokens}),
        total_cost_usd => _num($_->{total_cost_usd}),
      }
    } @$by_key ],
    by_model => [ map {
      +{
        model          => ($_->{model} // ''),
        requests       => _num($_->{requests}),
        total_tokens   => _num($_->{total_tokens}),
        total_cost_usd => _num($_->{total_cost_usd}),
      }
    } @$by_model ],
    recent   => [ map {
      +{
        id            => _num($_->{id}),
        created_at    => ($_->{created_at} // ''),
        api_format    => ($_->{api_format} // ''),
        endpoint      => ($_->{endpoint} // ''),
        api_key_id    => ($_->{api_key_id} // ''),
        model         => ($_->{model} // ''),
        node_id       => ($_->{node_id} // ''),
        status_code   => _num($_->{status_code}),
        ok            => ($_->{ok} ? 1 : 0),
        input_tokens  => _num($_->{input_tokens}),
        output_tokens => _num($_->{output_tokens}),
        total_tokens  => _num($_->{total_tokens}),
        tool_calls    => _num($_->{tool_calls}),
        cost_total_usd => _num($_->{cost_total_usd}),
      }
    } @$recent ],
  };
}

sub estimate_cost {
  my ($self, %args) = @_;
  my $model = $args{model} // '';
  my $usage = $args{usage}
    || Langertha::Knarr::Metrics->usage_from_response($args{response});
  my $pricing = $args{pricing} || $self->pricing_for_model($model);

  return Langertha::Knarr::Metrics->estimate_cost_usd(
    usage   => $usage,
    pricing => $pricing,
  );
}

sub normalize_metrics {
  my ($self, %args) = @_;
  my $model = $args{model} // '';
  my $usage = $args{usage}
    || Langertha::Knarr::Metrics->usage_from_response($args{response});
  my $pricing = $args{pricing} || $self->pricing_for_model($model);

  return Langertha::Knarr::Metrics->build_record(
    provider        => $args{provider},
    engine          => $args{engine},
    model           => $model,
    route           => $args{route},
    duration_ms     => $args{duration_ms},
    started_at      => $args{started_at},
    finished_at     => $args{finished_at},
    usage           => $usage,
    tool_calls      => ($args{tool_calls} || []),
    pricing         => $pricing,
    pricing_version => $args{pricing_version},
  );
}

sub _route_key {
  my ($self, %args) = @_;
  my $model  = $args{model}  // '';
  my $engine = $self->normalize_engine_id($args{engine} // '');
  return join('|', $model, $engine);
}

sub _node_can_take {
  my ($self, $node) = @_;
  return 0 unless ref($node) eq 'HASH';
  return 0 unless ($node->{healthy} // 0);
  my $id = $node->{id} // '';
  return 0 unless length $id;
  my $max = 0 + ($node->{max_conns} // 0);
  my $inflight = 0 + ($self->_inflight->{$id} // 0);
  return 1 if $max <= 0;
  return $inflight < $max ? 1 : 0;
}

sub _eligible_nodes {
  my ($self, %args) = @_;
  my $model  = $args{model};
  my $engine = $self->normalize_engine_id($args{engine} // '');
  my @nodes = @{$self->nodes || []};

  @nodes = grep {
    !defined($model) || !length($model) || !defined($_->{model}) || !length($_->{model}) || $_->{model} eq $model
  } @nodes;
  @nodes = grep {
    !defined($engine) || !length($engine) || !defined($_->{engine}) || !length($_->{engine}) || $_->{engine} eq $engine
  } @nodes;
  @nodes = grep { ($_->{healthy} // 0) ? 1 : 0 } @nodes;

  return [ map { +{%$_} } @nodes ];
}

sub pick_node {
  my ($self, %args) = @_;
  my $eligible = $self->_eligible_nodes(%args);
  return unless @$eligible;

  my @nodes = sort { ($a->{id} // '') cmp ($b->{id} // '') } @$eligible;
  my @weights = map {
    my $w = 0 + ($_->{weight} // 1);
    $w = 1 if $w < 1;
    int($w);
  } @nodes;
  my $total_weight = 0;
  $total_weight += $_ for @weights;
  return unless $total_weight > 0;

  my $key = $self->_route_key(%args);
  my $cursor = 0 + ($self->_rr_cursor->{$key} // 0);

  # Weighted round-robin with admission checks.
  for my $step (0 .. $total_weight - 1) {
    my $target = ($cursor + $step) % $total_weight;
    my $acc = 0;
    for my $idx (0 .. $#nodes) {
      $acc += $weights[$idx];
      next if $target >= $acc;
      my $candidate = $nodes[$idx];
      next unless $self->_node_can_take($candidate);
      $self->_rr_cursor->{$key} = ($cursor + $step + 1) % $total_weight;
      my $id = $candidate->{id};
      my $inflight = 0 + ($self->_inflight->{$id} // 0);
      return {
        %$candidate,
        inflight => $inflight,
        route_key => $key,
      };
    }
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
    eligible_count => scalar(@$eligible),
    available_count => scalar(@$available),
    has_eligible   => @$eligible ? 1 : 0,
    has_available  => @$available ? 1 : 0,
  };
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

  if ($args{ok}) {
    $self->_stats->{$node_id}{ok} = 1 + ($self->_stats->{$node_id}{ok} // 0);
  } else {
    $self->_stats->{$node_id}{error} = 1 + ($self->_stats->{$node_id}{error} // 0);
  }

  if (defined $args{duration_ms}) {
    $self->_stats->{$node_id}{duration_ms_total}
      = (0 + ($self->_stats->{$node_id}{duration_ms_total} // 0)) + (0 + $args{duration_ms});
  }

  return 1;
}

sub node_metrics {
  my ($self, $node_id) = @_;
  if (defined $node_id && length $node_id) {
    my $s = $self->_stats->{$node_id} || {};
    return {
      node_id => $node_id,
      inflight => 0 + ($self->_inflight->{$node_id} // 0),
      started => 0 + ($s->{started} // 0),
      ok => 0 + ($s->{ok} // 0),
      error => 0 + ($s->{error} // 0),
      duration_ms_total => 0 + ($s->{duration_ms_total} // 0),
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

  # Dynamic config refresh on each task/function dispatch.
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
    );
    return { node => $node };
  }
  if ($name eq 'route.state') {
    my $engine = $self->normalize_engine_id($args->{engine} // '');
    return $self->route_state(
      model  => ($args->{model} // ''),
      engine => $engine,
    );
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
  $self->_disconnect_usage_dbh;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Skeid - Dynamic routing control-plane for multi-node LLM serving with normalized metrics and cost accounting

=head1 VERSION

version 0.001

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
3. Forward tenant identity via C<x-skeid-key-id> (or C<x-api-key-id>).
4. Read totals by key/model/time with C<usage.report>.

=head2 Engine IDs

C<nodes[].engine> uses lowercased engine class names from L<Langertha>.
Examples: C<OpenAI =E<gt> openai>, C<OpenAIBase =E<gt> openaibase>,
C<vLLM =E<gt> vllm>. Legacy aliases like C<openai-compatible> are intentionally
rejected.

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
      # $event is a hashref with all 22 normalized columns
      publish_to_nats($event);
      return { ok => 1 };
    },
    query_usage_report => sub {
      my ($self, $filters) = @_;
      # $filters has: since, api_key_id, model, limit
      return { ok => 1, enabled => 1, totals => { ... } };
    },
  );

B<Option 2 – Subclass override>:

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

When a callback or override is provided, the DBI default is bypassed entirely
and no database connection is created.  DBI and DBD::SQLite are C<recommends>
dependencies — they are not required when usage is handled externally.

=head2 Admin API Key

C<admin.api_key> (or C<admin_api_key>) controls access to proxy admin routes.
If empty, admin routes are effectively disabled by returning C<404>. If set,
the proxy expects C<Authorization: Bearer ...>. This value can be changed
through dynamic config reload.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-skeid/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
