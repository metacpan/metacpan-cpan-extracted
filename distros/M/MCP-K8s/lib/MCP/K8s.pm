package MCP::K8s;
# ABSTRACT: MCP Server for Kubernetes with RBAC-aware dynamic tools
our $VERSION = '0.002';
use Moo;
use MCP::Server;
extends 'MCP::Server';
use MCP::K8s::Permissions;
use Kubernetes::REST;
use Kubernetes::REST::Kubeconfig;
use JSON::MaybeXS;
use Carp qw( croak );
use namespace::clean;


# Map common resource short names to their plural form for RBAC checking.
# This is necessary because RBAC rules use plural resource names (e.g. "pods")
# while the Kubernetes::REST API accepts singular Kind names (e.g. "Pod").
my %RESOURCE_PLURALS = (
  Pod                   => 'pods',
  Service               => 'services',
  Deployment            => 'deployments',
  ReplicaSet            => 'replicasets',
  StatefulSet           => 'statefulsets',
  DaemonSet             => 'daemonsets',
  Job                   => 'jobs',
  CronJob               => 'cronjobs',
  ConfigMap             => 'configmaps',
  Secret                => 'secrets',
  Namespace             => 'namespaces',
  Node                  => 'nodes',
  PersistentVolume      => 'persistentvolumes',
  PersistentVolumeClaim => 'persistentvolumeclaims',
  ServiceAccount        => 'serviceaccounts',
  Role                  => 'roles',
  RoleBinding           => 'rolebindings',
  ClusterRole           => 'clusterroles',
  ClusterRoleBinding    => 'clusterrolebindings',
  Ingress               => 'ingresses',
  NetworkPolicy         => 'networkpolicies',
  HorizontalPodAutoscaler => 'horizontalpodautoscalers',
  Event                 => 'events',
  Endpoints             => 'endpoints',
  LimitRange            => 'limitranges',
  ResourceQuota         => 'resourcequotas',
);

has context_name => (
  is        => 'ro',
  lazy      => 1,
  default   => sub { $ENV{MCP_K8S_CONTEXT} },
  predicate => 1,
);


has token => (
  is        => 'ro',
  lazy      => 1,
  default   => sub { $ENV{MCP_K8S_TOKEN} },
  predicate => 1,
);


has server_endpoint => (
  is        => 'ro',
  lazy      => 1,
  default   => sub { $ENV{MCP_K8S_SERVER} },
  predicate => 1,
);


has namespaces => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_namespaces',
);


has api => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_api',
);


has permissions => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_permissions',
);


has _resource_plurals_cache => (
  is      => 'rw',
  default => sub { {} },
);

# Stores [tool_ref, base_desc, verb] tuples for lazy description updates
has _tool_desc_map => (
  is      => 'rw',
  default => sub { [] },
);

has _descriptions_updated => (
  is      => 'rw',
  default => 0,
);

has json => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    JSON::MaybeXS->new(utf8 => 1, pretty => 1, canonical => 1, convert_blessed => 1);
  },
);



sub server { $_[0] }

sub BUILD {
  my ($self) = @_;
  $self->name('MCP-K8s') if $self->name eq 'PerlServer';
  $self->version($MCP::K8s::VERSION || 'dev') if $self->version eq '1.0.0';
  $self->_register_tools;
}

my $IN_CLUSTER_TOKEN_PATH = '/var/run/secrets/kubernetes.io/serviceaccount/token';
my $IN_CLUSTER_CA_PATH   = '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt';
my $IN_CLUSTER_NS_PATH   = '/var/run/secrets/kubernetes.io/serviceaccount/namespace';
my $IN_CLUSTER_DEFAULT_SERVER = 'https://kubernetes.default.svc.cluster.local';

sub _read_file {
  my ($self, $path) = @_;
  open my $fh, '<', $path or return undef;
  my $content = do { local $/; <$fh> };
  close $fh;
  chomp $content if defined $content;
  return $content;
}

sub _build_api {
  my ($self) = @_;

  # Tier 1: Direct token from MCP_K8S_TOKEN
  if ($self->has_token && defined $self->token && length $self->token) {
    my $endpoint = ($self->has_server_endpoint && $self->server_endpoint)
      ? $self->server_endpoint
      : $IN_CLUSTER_DEFAULT_SERVER;
    my %server = (endpoint => $endpoint);
    $server{ssl_ca_file} = $IN_CLUSTER_CA_PATH if -f $IN_CLUSTER_CA_PATH;
    return Kubernetes::REST->new(
      server      => \%server,
      credentials => { token => $self->token },
    );
  }

  # Tier 2: In-cluster service account token
  if (-f $IN_CLUSTER_TOKEN_PATH) {
    my $sa_token = $self->_read_file($IN_CLUSTER_TOKEN_PATH);
    if (defined $sa_token && length $sa_token) {
      my $endpoint = ($self->has_server_endpoint && $self->server_endpoint)
        ? $self->server_endpoint
        : $IN_CLUSTER_DEFAULT_SERVER;
      my %server = (endpoint => $endpoint);
      $server{ssl_ca_file} = $IN_CLUSTER_CA_PATH if -f $IN_CLUSTER_CA_PATH;
      return Kubernetes::REST->new(
        server      => \%server,
        credentials => { token => $sa_token },
      );
    }
  }

  # Tier 3: Kubeconfig (original behavior)
  my %kc_args;
  $kc_args{context_name} = $self->context_name if $self->has_context_name;
  my $kc = Kubernetes::REST::Kubeconfig->new(%kc_args);
  return $kc->api;
}

sub _build_namespaces {
  my ($self) = @_;

  # From environment variable
  if (my $env = $ENV{MCP_K8S_NAMESPACES}) {
    return [ split /,/, $env ];
  }

  # In-cluster: read mounted namespace as default
  if (-f $IN_CLUSTER_NS_PATH) {
    my $ns = $self->_read_file($IN_CLUSTER_NS_PATH);
    if (defined $ns && length $ns) {
      # Try to discover more, but use in-cluster namespace as fallback
      my $list = eval { $self->api->list('Namespace') };
      if (!$@ && $list) {
        my @ns = map { $_->metadata->name } @{ $list->items // [] };
        return \@ns if @ns;
      }
      return [$ns];
    }
  }

  # Auto-discover from cluster
  my $list = eval { $self->api->list('Namespace') };
  if ($@ || !$list) {
    return ['default'];
  }

  my @ns = map { $_->metadata->name } @{ $list->items // [] };
  return @ns ? \@ns : ['default'];
}

sub _build_permissions {
  my ($self) = @_;
  return MCP::K8s::Permissions->new(
    api        => $self->api,
    namespaces => $self->namespaces,
  );
}

sub _to_json {
  my ($self, $data) = @_;
  return $self->json->encode($data);
}

sub _resource_plural {
  my ($self, $resource) = @_;


  # Tier 1: Static map (fast path)
  return $RESOURCE_PLURALS{$resource} if $RESOURCE_PLURALS{$resource};

  # Tier 2: IO::K8s class method (CRD classes like IO::K8s::...)
  my $class = eval { $self->api->expand_class($resource) };
  if ($class && $class->can('resource_plural')) {
    my $plural = eval { $class->resource_plural };
    return $plural if defined $plural && length $plural;
  }

  # Tier 3: API server discovery (cached)
  my $cache = $self->_resource_plurals_cache;
  unless (%$cache) {
    $self->_discover_resource_plurals;
    $cache = $self->_resource_plurals_cache;
  }
  return $cache->{$resource} if $cache->{$resource};

  # Tier 4: Heuristic fallback
  my $plural = lc($resource);
  $plural .= 's' unless $plural =~ /s$/;
  $plural =~ s/ys$/ies/;
  return $plural;
}

sub _discover_resource_plurals {
  my ($self) = @_;


  my %cache;

  # Query /api/v1 for core resources
  my $core = eval {
    my $resp = $self->api->_request('GET', '/api/v1');
    return undef if !$resp || $resp->status >= 400;
    JSON::MaybeXS->new->decode($resp->content);
  };
  if ($core && $core->{resources}) {
    for my $r (@{ $core->{resources} }) {
      next if ($r->{name} // '') =~ m{/};  # skip subresources
      $cache{ $r->{kind} } = $r->{name} if $r->{kind} && $r->{name};
    }
  }

  # Query /apis for API groups
  my $groups = eval {
    my $resp = $self->api->_request('GET', '/apis');
    return undef if !$resp || $resp->status >= 400;
    JSON::MaybeXS->new->decode($resp->content);
  };
  if ($groups && $groups->{groups}) {
    for my $group (@{ $groups->{groups} }) {
      my $pv = $group->{preferredVersion}{groupVersion} // next;
      my $group_resources = eval {
        my $resp = $self->api->_request('GET', "/apis/$pv");
        return undef if !$resp || $resp->status >= 400;
        JSON::MaybeXS->new->decode($resp->content);
      };
      if ($group_resources && $group_resources->{resources}) {
        for my $r (@{ $group_resources->{resources} }) {
          next if ($r->{name} // '') =~ m{/};
          $cache{ $r->{kind} } = $r->{name} if $r->{kind} && $r->{name};
        }
      }
    }
  }

  $self->_resource_plurals_cache(\%cache);
}

sub _resolve_namespace {
  my ($self, $args) = @_;


  my $ns = $args->{namespace};
  return $ns if defined $ns && length $ns;

  # Auto-fill if only one namespace accessible
  my @allowed = $self->permissions->allowed_namespaces;
  return $allowed[0] if @allowed == 1;

  return undef;
}

sub _format_resource_summary {
  my ($self, $obj) = @_;


  my %summary;

  if ($obj->can('metadata') && $obj->metadata) {
    my $meta = $obj->metadata;
    $summary{name}      = $meta->name if $meta->can('name');
    $summary{namespace} = $meta->namespace if $meta->can('namespace') && $meta->namespace;
    $summary{labels}    = $meta->labels if $meta->can('labels') && $meta->labels;
    $summary{creationTimestamp} = $meta->creationTimestamp if $meta->can('creationTimestamp') && $meta->creationTimestamp;
  }

  if ($obj->can('kind') && $obj->kind) {
    $summary{kind} = $obj->kind;
  }

  if ($obj->can('status') && $obj->status) {
    my $status = $obj->status;
    $summary{phase} = $status->phase if $status->can('phase') && $status->phase;
    $summary{replicas} = $status->replicas if $status->can('replicas') && defined $status->replicas;
    $summary{readyReplicas} = $status->readyReplicas if $status->can('readyReplicas') && defined $status->readyReplicas;
    $summary{availableReplicas} = $status->availableReplicas if $status->can('availableReplicas') && defined $status->availableReplicas;
    $summary{conditions} = $status->conditions if $status->can('conditions') && $status->conditions;
  }

  if ($obj->can('spec') && $obj->spec) {
    my $spec = $obj->spec;
    $summary{replicas} //= $spec->replicas if $spec->can('replicas') && defined $spec->replicas;
    if ($spec->can('containers') && $spec->containers) {
      $summary{containers} = [ map { $_->name } @{ $spec->containers } ];
    }
    if ($spec->can('type') && $spec->type) {
      $summary{type} = $spec->type;
    }
    if ($spec->can('ports') && $spec->ports) {
      $summary{ports} = [ map {
        my $p = $_;
        my %port;
        $port{port}       = $p->port if $p->can('port') && defined $p->port;
        $port{targetPort} = $p->targetPort if $p->can('targetPort') && defined $p->targetPort;
        $port{protocol}   = $p->protocol if $p->can('protocol') && $p->protocol;
        \%port;
      } @{ $spec->ports } ];
    }
  }

  return \%summary;
}

sub _format_list {
  my ($self, $items) = @_;


  my @summaries;
  for my $item (@{ $items // [] }) {
    push @summaries, $self->_format_resource_summary($item);
  }
  return \@summaries;
}

sub _available_resources_desc {
  my ($self, $verb) = @_;
  my @parts;
  for my $ns ($self->permissions->allowed_namespaces) {
    my @resources = $self->permissions->allowed_resources($verb, $ns);
    if (@resources) {
      my @display = grep { $_ ne '*' } @resources;
      if (grep { $_ eq '*' } @resources) {
        push @parts, "$ns: all resources";
      } elsif (@display > 10) {
        push @parts, "$ns: " . join(', ', @display[0..9]) . ", ...";
      } else {
        push @parts, "$ns: " . join(', ', @display);
      }
    }
  }
  return join('; ', @parts) || 'none discovered';
}

sub _update_tool_descriptions {
  my ($self) = @_;
  return if $self->_descriptions_updated;
  $self->permissions->ensure_discovered;

  for my $entry (@{ $self->_tool_desc_map }) {
    my ($tool, $base, $verb) = @$entry;
    if ($verb eq '_logs') {
      my @log_ns = grep {
        $self->permissions->can_read_logs($_)
      } $self->permissions->allowed_namespaces;
      $tool->description($base . (join(', ', @log_ns) || 'none'));
    } else {
      $tool->description($base . $self->_available_resources_desc($verb));
    }
  }
  $self->_descriptions_updated(1);
}


sub _register_tools {
  my ($self) = @_;

  my @desc_map;

  # ---- Tool 1: k8s_permissions ----
  $self->tool(
    name        => 'k8s_permissions',
    description => 'Show what this Kubernetes service account is allowed to do (RBAC permissions). Call this first to understand available capabilities.',
    input_schema => {
      type       => 'object',
      properties => {},
    },
    code => sub {
      my ($tool, $args) = @_;
      return $self->permissions->summary;
    },
  );

  # ---- Tool 2: k8s_list ----
  my $list_desc = 'List Kubernetes resources.';
  push @desc_map, [$self->tool(
    name        => 'k8s_list',
    description => $list_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type (e.g. Pod, Deployment, Service, ConfigMap)',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace (auto-detected if only one available)',
        },
        label_selector => {
          type        => 'string',
          description => 'Label selector filter (e.g. app=web)',
        },
        field_selector => {
          type        => 'string',
          description => 'Field selector filter (e.g. status.phase=Running)',
        },
      },
      required => ['resource'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource = $args->{resource};
      my $ns = $self->_resolve_namespace($args);
      my $plural = $self->_resource_plural($resource);

      unless ($self->permissions->can_do('list', $plural, $ns // '')) {
        return "Permission denied: cannot list $resource" . ($ns ? " in namespace $ns" : "");
      }

      my %api_args;
      $api_args{namespace}     = $ns if defined $ns;
      $api_args{labelSelector} = $args->{label_selector} if $args->{label_selector};
      $api_args{fieldSelector} = $args->{field_selector} if $args->{field_selector};

      my $list = eval { $self->api->list($resource, %api_args) };
      return "Failed to list $resource: $@" if $@;

      my $items = $list->items // [];
      return "No $resource resources found" unless @$items;

      my $summaries = $self->_format_list($items);
      return $self->_to_json({
        count => scalar @$items,
        items => $summaries,
      });
    },
  ), 'List Kubernetes resources. Available: ', 'list'];

  # ---- Tool 3: k8s_get ----
  my $get_desc = 'Get a single Kubernetes resource.';
  push @desc_map, [$self->tool(
    name        => 'k8s_get',
    description => $get_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type (e.g. Pod, Deployment, Service)',
        },
        name => {
          type        => 'string',
          description => 'Resource name',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace (auto-detected if only one available)',
        },
        output => {
          type        => 'string',
          description => 'Output format: summary (default), json, yaml',
          enum        => ['summary', 'json', 'yaml'],
        },
      },
      required => ['resource', 'name'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource = $args->{resource};
      my $name     = $args->{name};
      my $ns       = $self->_resolve_namespace($args);
      my $output   = $args->{output} // 'summary';
      my $plural   = $self->_resource_plural($resource);

      unless ($self->permissions->can_do('get', $plural, $ns // '')) {
        return "Permission denied: cannot get $resource" . ($ns ? " in namespace $ns" : "");
      }

      my %api_args = (name => $name);
      $api_args{namespace} = $ns if defined $ns;

      my $obj = eval { $self->api->get($resource, %api_args) };
      return "Failed to get $resource/$name: $@" if $@;

      if ($output eq 'json') {
        return $self->_to_json($obj->TO_JSON);
      } elsif ($output eq 'yaml') {
        eval { require YAML::XS };
        if ($@) {
          return $self->_to_json($obj->TO_JSON);
        }
        return YAML::XS::Dump($obj->TO_JSON);
      } else {
        return $self->_to_json($self->_format_resource_summary($obj));
      }
    },
  ), 'Get a single Kubernetes resource. Available: ', 'get'];

  # ---- Tool 4: k8s_create ----
  my $create_desc = 'Create a Kubernetes resource.';
  push @desc_map, [$self->tool(
    name        => 'k8s_create',
    description => $create_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type (e.g. Pod, Deployment, ConfigMap)',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace for the resource',
        },
        manifest => {
          type        => 'object',
          description => 'Resource manifest (apiVersion/kind auto-populated from resource type)',
        },
      },
      required => ['resource', 'manifest'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource = $args->{resource};
      my $ns       = $self->_resolve_namespace($args);
      my $manifest = $args->{manifest};
      my $plural   = $self->_resource_plural($resource);

      unless ($self->permissions->can_do('create', $plural, $ns // '')) {
        return "Permission denied: cannot create $resource" . ($ns ? " in namespace $ns" : "");
      }

      # Auto-populate namespace in metadata
      if (defined $ns) {
        $manifest->{metadata} //= {};
        $manifest->{metadata}{namespace} //= $ns;
      }

      my $obj = eval { $self->api->new_object($resource, $manifest) };
      return "Failed to build $resource object: $@" if $@;

      my $created = eval { $self->api->create($obj) };
      return "Failed to create $resource: $@" if $@;

      my $created_name = eval { $created->metadata->name } // 'unknown';
      return $self->_to_json({
        status  => 'created',
        kind    => $resource,
        name    => $created_name,
        ($ns ? (namespace => $ns) : ()),
      });
    },
  ), 'Create a Kubernetes resource. Available: ', 'create'];

  # ---- Tool 5: k8s_patch ----
  my $patch_desc = 'Patch (partial update) a Kubernetes resource.';
  push @desc_map, [$self->tool(
    name        => 'k8s_patch',
    description => $patch_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type (e.g. Deployment, Service)',
        },
        name => {
          type        => 'string',
          description => 'Resource name',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace',
        },
        patch => {
          type        => 'object',
          description => 'Patch body (fields to change)',
        },
        patch_type => {
          type        => 'string',
          description => 'Patch strategy: strategic (default), merge, json',
          enum        => ['strategic', 'merge', 'json'],
        },
      },
      required => ['resource', 'name', 'patch'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource   = $args->{resource};
      my $name       = $args->{name};
      my $ns         = $self->_resolve_namespace($args);
      my $patch      = $args->{patch};
      my $patch_type = $args->{patch_type} // 'strategic';
      my $plural     = $self->_resource_plural($resource);

      unless ($self->permissions->can_do('patch', $plural, $ns // '')) {
        return "Permission denied: cannot patch $resource" . ($ns ? " in namespace $ns" : "");
      }

      my %api_args = (
        patch => $patch,
        type  => $patch_type,
      );
      $api_args{namespace} = $ns if defined $ns;

      my $patched = eval { $self->api->patch($resource, $name, %api_args) };
      return "Failed to patch $resource/$name: $@" if $@;

      return $self->_to_json({
        status => 'patched',
        kind   => $resource,
        name   => $name,
        ($ns ? (namespace => $ns) : ()),
      });
    },
  ), 'Patch (partial update) a Kubernetes resource. Available: ', 'patch'];

  # ---- Tool 6: k8s_delete ----
  my $delete_desc = 'Delete a Kubernetes resource.';
  push @desc_map, [$self->tool(
    name        => 'k8s_delete',
    description => $delete_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type (e.g. Pod, Deployment)',
        },
        name => {
          type        => 'string',
          description => 'Resource name',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace',
        },
      },
      required => ['resource', 'name'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource = $args->{resource};
      my $name     = $args->{name};
      my $ns       = $self->_resolve_namespace($args);
      my $plural   = $self->_resource_plural($resource);

      unless ($self->permissions->can_do('delete', $plural, $ns // '')) {
        return "Permission denied: cannot delete $resource" . ($ns ? " in namespace $ns" : "");
      }

      my %api_args = (name => $name);
      $api_args{namespace} = $ns if defined $ns;

      eval { $self->api->delete($resource, %api_args) };
      return "Failed to delete $resource/$name: $@" if $@;

      return $self->_to_json({
        status => 'deleted',
        kind   => $resource,
        name   => $name,
        ($ns ? (namespace => $ns) : ()),
      });
    },
  ), 'Delete a Kubernetes resource. Available: ', 'delete'];

  # ---- Tool 7: k8s_logs ----
  my $logs_desc = 'Get pod logs from Kubernetes pods.';
  push @desc_map, [$self->tool(
    name        => 'k8s_logs',
    description => $logs_desc,
    input_schema => {
      type       => 'object',
      properties => {
        name => {
          type        => 'string',
          description => 'Pod name',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace (auto-detected if only one available)',
        },
        container => {
          type        => 'string',
          description => 'Container name (required for multi-container pods)',
        },
        tail_lines => {
          type        => 'integer',
          description => 'Number of lines from end (default: 100)',
        },
        previous => {
          type        => 'boolean',
          description => 'Get logs from previous container instance',
        },
      },
      required => ['name'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $name       = $args->{name};
      my $ns         = $self->_resolve_namespace($args);
      my $container  = $args->{container};
      my $tail_lines = $args->{tail_lines} // 100;
      my $previous   = $args->{previous} // 0;

      unless ($ns) {
        return "Namespace required for pod logs";
      }

      unless ($self->permissions->can_read_logs($ns)) {
        return "Permission denied: cannot read pod logs in namespace $ns";
      }

      # Build the log URL path directly
      my $path = "/api/v1/namespaces/$ns/pods/$name/log";
      my %params;
      $params{tailLines} = $tail_lines if $tail_lines;
      $params{container} = $container if $container;
      $params{previous}  = 'true' if $previous;

      my $response = eval { $self->api->_request('GET', $path, undef, parameters => \%params) };
      return "Failed to get logs for pod/$name: $@" if $@;

      if ($response->status >= 400) {
        return "Error getting logs: " . $response->status . " " . ($response->content // '');
      }

      my $content = $response->content // '';
      return $content || "(no log output)";
    },
  ), 'Get pod logs. Available in namespaces: ', '_logs'];

  # ---- Tool 8: k8s_events ----
  my $events_desc = 'Get Kubernetes events for debugging.';
  push @desc_map, [$self->tool(
    name        => 'k8s_events',
    description => $events_desc,
    input_schema => {
      type       => 'object',
      properties => {
        namespace => {
          type        => 'string',
          description => 'Namespace (auto-detected if only one available)',
        },
        involved_object => {
          type        => 'string',
          description => 'Filter events by involved object name (e.g. a pod name)',
        },
        field_selector => {
          type        => 'string',
          description => 'Field selector filter (e.g. reason=BackOff)',
        },
      },
    },
    code => sub {
      my ($tool, $args) = @_;

      my $ns = $self->_resolve_namespace($args);

      unless ($self->permissions->can_do('list', 'events', $ns // '')) {
        return "Permission denied: cannot list events" . ($ns ? " in namespace $ns" : "");
      }

      my %api_args;
      $api_args{namespace} = $ns if defined $ns;

      my @selectors;
      if (my $obj = $args->{involved_object}) {
        push @selectors, "involvedObject.name=$obj";
      }
      if (my $fs = $args->{field_selector}) {
        push @selectors, $fs;
      }
      $api_args{fieldSelector} = join(',', @selectors) if @selectors;

      my $list = eval { $self->api->list('Event', %api_args) };
      return "Failed to list events: $@" if $@;

      my $items = $list->items // [];
      return "No events found" unless @$items;

      my $summaries = $self->_format_list($items);
      return $self->_to_json({
        count => scalar @$items,
        items => $summaries,
      });
    },
  ), 'Get Kubernetes events for debugging. Available in: ', 'list'];

  # ---- Tool 9: k8s_rollout_restart ----
  my $restart_desc = 'Trigger rolling restart of a Deployment, StatefulSet, or DaemonSet.';
  push @desc_map, [$self->tool(
    name        => 'k8s_rollout_restart',
    description => $restart_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type: Deployment, StatefulSet, or DaemonSet',
          enum        => ['Deployment', 'StatefulSet', 'DaemonSet'],
        },
        name => {
          type        => 'string',
          description => 'Resource name',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace',
        },
      },
      required => ['resource', 'name'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource = $args->{resource};
      my $name     = $args->{name};
      my $ns       = $self->_resolve_namespace($args);
      my $plural   = $self->_resource_plural($resource);

      unless ($self->permissions->can_do('patch', $plural, $ns // '')) {
        return "Permission denied: cannot patch $resource" . ($ns ? " in namespace $ns" : "");
      }

      # Generate ISO 8601 timestamp without POSIX dependency
      my @t = gmtime;
      my $timestamp = sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ',
        $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);

      my $patch = {
        spec => {
          template => {
            metadata => {
              annotations => {
                'kubectl.kubernetes.io/restartedAt' => $timestamp,
              },
            },
          },
        },
      };

      my %api_args = (
        patch => $patch,
        type  => 'strategic',
      );
      $api_args{namespace} = $ns if defined $ns;

      my $patched = eval { $self->api->patch($resource, $name, %api_args) };
      return "Failed to restart $resource/$name: $@" if $@;

      return $self->_to_json({
        status    => 'restarting',
        kind      => $resource,
        name      => $name,
        restartAt => $timestamp,
        ($ns ? (namespace => $ns) : ()),
      });
    },
  ), 'Trigger rolling restart of a Deployment, StatefulSet, or DaemonSet. Available: ', 'patch'];

  # ---- Tool 10: k8s_apply ----
  my $apply_desc = 'Create or update a Kubernetes resource (like kubectl apply).';
  push @desc_map, [$self->tool(
    name        => 'k8s_apply',
    description => $apply_desc,
    input_schema => {
      type       => 'object',
      properties => {
        resource => {
          type        => 'string',
          description => 'Resource type (e.g. Deployment, ConfigMap)',
        },
        namespace => {
          type        => 'string',
          description => 'Namespace for the resource',
        },
        manifest => {
          type        => 'object',
          description => 'Resource manifest (must include metadata.name)',
        },
      },
      required => ['resource', 'manifest'],
    },
    code => sub {
      my ($tool, $args) = @_;

      my $resource = $args->{resource};
      my $ns       = $self->_resolve_namespace($args);
      my $manifest = $args->{manifest};
      my $plural   = $self->_resource_plural($resource);

      my $can_create = $self->permissions->can_do('create', $plural, $ns // '');
      my $can_patch  = $self->permissions->can_do('patch', $plural, $ns // '');

      unless ($can_create || $can_patch) {
        return "Permission denied: cannot create or patch $resource" . ($ns ? " in namespace $ns" : "");
      }

      my $res_name = eval { $manifest->{metadata}{name} };
      return "manifest must include metadata.name" unless defined $res_name && length $res_name;

      # Auto-populate namespace in metadata
      if (defined $ns) {
        $manifest->{metadata} //= {};
        $manifest->{metadata}{namespace} //= $ns;
      }

      # Try create first
      if ($can_create) {
        my $obj = eval { $self->api->new_object($resource, $manifest) };
        return "Failed to build $resource object: $@" if $@;

        my $created = eval { $self->api->create($obj) };
        if (!$@) {
          my $created_name = eval { $created->metadata->name } // $res_name;
          return $self->_to_json({
            status => 'created',
            kind   => $resource,
            name   => $created_name,
            ($ns ? (namespace => $ns) : ()),
          });
        }

        # If 409 Conflict / AlreadyExists, fall through to patch
        my $err = "$@";
        unless ($err =~ /409|AlreadyExists/i) {
          return "Failed to create $resource: $err";
        }
      }

      # Fall back to strategic merge patch
      unless ($can_patch) {
        return "Resource already exists and cannot patch $resource" . ($ns ? " in namespace $ns" : "");
      }

      my %api_args = (
        patch => $manifest,
        type  => 'strategic',
      );
      $api_args{namespace} = $ns if defined $ns;

      my $patched = eval { $self->api->patch($resource, $res_name, %api_args) };
      return "Failed to update $resource/$res_name: $@" if $@;

      return $self->_to_json({
        status => 'updated',
        kind   => $resource,
        name   => $res_name,
        ($ns ? (namespace => $ns) : ()),
      });
    },
  ), 'Create or update a Kubernetes resource (like kubectl apply). Available: ', 'create'];

  $self->_tool_desc_map(\@desc_map);
}

sub run_stdio {
  my ($self) = @_;


  $self = $self->new unless ref $self;
  $self->_update_tool_descriptions;
  $self->to_stdio;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::K8s - MCP Server for Kubernetes with RBAC-aware dynamic tools

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # Start the MCP server on stdio (for Claude Desktop, Claude Code, etc.)
  use MCP::K8s;
  MCP::K8s->run_stdio;

  # Or use the included script:
  $ mcp-k8s

  # Configure via environment variables:
  $ export MCP_K8S_CONTEXT="my-cluster"
  $ export MCP_K8S_NAMESPACES="default,production"
  $ mcp-k8s

  # Direct token authentication:
  $ export MCP_K8S_TOKEN="eyJhbGci..."
  $ export MCP_K8S_SERVER="https://my-cluster:6443"
  $ mcp-k8s

  # In-cluster: auto-detects when running as a Kubernetes pod

  # Programmatic usage with custom API:
  use MCP::K8s;
  my $k8s = MCP::K8s->new(
    api        => $my_kubernetes_rest_instance,
    namespaces => ['default', 'staging'],
  );
  $k8s->to_stdio;

=head1 DESCRIPTION

MCP::K8s provides an MCP (Model Context Protocol) server that gives AI
assistants like Claude access to Kubernetes clusters.

The key innovation: B<the server dynamically discovers what the connected
service account can do via RBAC> and only exposes those capabilities as
MCP tools. A read-only service account gets read-only tools; a cluster-admin
gets everything. Tool descriptions include the specific resources and
namespaces available, so the LLM always knows exactly what it can do.

=head2 How it works

=over 4

=item 1. B<Connect> — Authenticates via direct token, in-cluster service account, or kubeconfig

=item 2. B<Discover> — Submits C<SelfSubjectRulesReview> requests to discover RBAC permissions per namespace

=item 3. B<Register> — Creates MCP tools with dynamic descriptions reflecting actual permissions

=item 4. B<Serve> — Runs the MCP protocol over stdio, checking permissions on every tool call

=back

=head2 Why generic tools?

Kubernetes has 50+ built-in resource types plus unlimited Custom Resources.
Instead of creating hundreds of specific tools (C<list_pods>, C<get_deployment>,
C<delete_configmap>...), MCP::K8s uses 10 generic tools with a C<resource>
parameter — the same pattern as C<kubectl get>, C<kubectl delete>, etc.
This keeps the tool count manageable for MCP clients while supporting
every resource type including CRDs.

Built on top of L<Kubernetes::REST> (API client), L<IO::K8s> (typed objects),
and L<MCP::Server> (protocol implementation).

=head2 context_name

Optional. Kubeconfig context name to use. Read from C<$ENV{MCP_K8S_CONTEXT}>
by default. If not set, the kubeconfig's C<current-context> is used.

=head2 token

Optional. Bearer token for direct authentication. Read from
C<$ENV{MCP_K8S_TOKEN}> by default. When set, bypasses kubeconfig
entirely and connects using this token directly.

=head2 server_endpoint

Optional. Kubernetes API server URL. Read from C<$ENV{MCP_K8S_SERVER}>
by default. Used with L</token> for direct authentication, or with
in-cluster auth. Defaults to C<https://kubernetes.default.svc.cluster.local>
when running in-cluster.

=head2 namespaces

ArrayRef of namespace names to operate on. Configured via:

=over 4

=item * C<$ENV{MCP_K8S_NAMESPACES}> — comma-separated list (e.g. C<"default,production">)

=item * Auto-discovery — lists all namespaces from the cluster

=item * Fallback — C<['default']> if discovery fails

=back

=head2 api

L<Kubernetes::REST> instance for cluster communication. Built automatically
from kubeconfig using L<Kubernetes::REST::Kubeconfig>. Can be provided
directly for testing or custom configurations.

=head2 permissions

L<MCP::K8s::Permissions> instance holding the discovered RBAC permissions.
Built and populated automatically on first access via C<SelfSubjectRulesReview>.

=head2 json

L<JSON::MaybeXS> encoder instance. Configured with C<utf8>, C<pretty>,
C<canonical>, and C<convert_blessed> for consistent, readable output.

=head2 server

Returns C<$self> for backward compatibility. Since MCP::K8s now inherits
from L<MCP::Server>, the object itself is the server.

=head2 _resource_plural

  my $plural = $self->_resource_plural('Pod');       # => 'pods'
  my $plural = $self->_resource_plural('Ingress');   # => 'ingresses'

Convert a Kubernetes Kind name (e.g. C<Pod>, C<Deployment>) to its plural
form used in RBAC rules (e.g. C<pods>, C<deployments>). Uses a 4-tier
lookup:

=over 4

=item 1. Static C<%RESOURCE_PLURALS> map (fast, zero-cost)

=item 2. C<IO::K8s> class C<resource_plural()> method (supports CRDs like Cilium)

=item 3. API server discovery cache (lazy, one-time query)

=item 4. Heuristic fallback (lowercase + simple pluralization)

=back

=head2 _discover_resource_plurals

  $self->_discover_resource_plurals;

Query the API server's discovery endpoints (C</api/v1> and C</apis>) to
build a Kind-to-plural mapping. Results are cached in
L</_resource_plurals_cache>. Failures are silently ignored — the cache
simply remains empty and callers fall through to heuristic pluralization.

=head2 _resolve_namespace

  my $ns = $self->_resolve_namespace($args);

Resolve the namespace for a tool call. If C<< $args->{namespace} >> is
provided, uses that. Otherwise, if only one namespace is accessible,
auto-fills it. Returns C<undef> if the namespace cannot be determined
(the tool should handle this case).

=head2 _format_resource_summary

  my $summary = $self->_format_resource_summary($io_k8s_object);

Extract a concise summary hashref from an L<IO::K8s> object, suitable for
LLM consumption. Includes metadata (name, namespace, labels, creation time),
kind, status fields (phase, replicas, conditions), and key spec fields
(containers, ports, type).

The summary is intentionally compact — for full details, the C<k8s_get>
tool with C<output =E<gt> 'json'> should be used.

=head2 _format_list

  my $summaries = $self->_format_list($list->items);

Format an arrayref of L<IO::K8s> objects into an arrayref of summary
hashrefs using L</_format_resource_summary>.

=head1 MCP TOOLS

All tools are registered on the L</server> during construction. Each tool
checks RBAC permissions before executing and returns clear error messages
on denial. Tool descriptions dynamically include which resources and
namespaces are available.

=head2 k8s_permissions

Show what the current Kubernetes service account is allowed to do. Returns
a Markdown-formatted RBAC summary. B<The LLM should call this first> to
understand its capabilities.

No parameters required.

=head2 k8s_list

List Kubernetes resources with optional filtering.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — Resource type: C<Pod>, C<Deployment>, C<Service>, C<ConfigMap>, etc.

=item C<namespace> (string) — Target namespace. Auto-detected if only one is accessible.

=item C<label_selector> (string) — Label filter, e.g. C<app=web,env=prod>

=item C<field_selector> (string) — Field filter, e.g. C<status.phase=Running>

=back

Returns JSON with C<count> and C<items> (array of resource summaries).

=head2 k8s_get

Get a single Kubernetes resource by name.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — Resource type

=item C<name> (string, B<required>) — Resource name

=item C<namespace> (string) — Target namespace

=item C<output> (string) — Format: C<summary> (default), C<json>, or C<yaml>

=back

=head2 k8s_create

Create a Kubernetes resource from a manifest. The C<apiVersion> and C<kind>
fields are auto-populated from the resource type via L<IO::K8s>.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — Resource type

=item C<manifest> (object, B<required>) — Resource manifest (metadata, spec, etc.)

=item C<namespace> (string) — Target namespace (also auto-populated in metadata)

=back

Returns JSON confirmation with the created resource name.

=head2 k8s_patch

Partially update a Kubernetes resource.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — Resource type

=item C<name> (string, B<required>) — Resource name

=item C<patch> (object, B<required>) — Fields to change

=item C<namespace> (string) — Target namespace

=item C<patch_type> (string) — Strategy: C<strategic> (default), C<merge>, or C<json>

=back

See L<Kubernetes::REST/patch> for details on patch strategies.

=head2 k8s_delete

Delete a Kubernetes resource by name.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — Resource type

=item C<name> (string, B<required>) — Resource name

=item C<namespace> (string) — Target namespace

=back

=head2 k8s_logs

Get container logs from a pod. Essential for debugging. Uses the raw
C</api/v1/namespaces/{ns}/pods/{name}/log> endpoint.

B<Parameters:>

=over 4

=item C<name> (string, B<required>) — Pod name

=item C<namespace> (string) — Target namespace (B<required> for logs)

=item C<container> (string) — Container name (required for multi-container pods)

=item C<tail_lines> (integer) — Number of lines from end (default: 100)

=item C<previous> (boolean) — Get logs from previous container instance

=back

=head2 k8s_events

Get Kubernetes events for debugging. Supports filtering by involved object
name and arbitrary field selectors.

B<Parameters:>

=over 4

=item C<namespace> (string) — Target namespace

=item C<involved_object> (string) — Filter events by object name (e.g. pod name)

=item C<field_selector> (string) — Field selector filter (e.g. C<reason=BackOff>)

=back

Returns JSON with C<count> and C<items> (array of event summaries).

=head2 k8s_rollout_restart

Trigger a rolling restart of a Deployment, StatefulSet, or DaemonSet.
Works by patching the pod template annotation C<kubectl.kubernetes.io/restartedAt>
with the current timestamp — the same mechanism as C<kubectl rollout restart>.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — One of C<Deployment>, C<StatefulSet>, C<DaemonSet>

=item C<name> (string, B<required>) — Resource name

=item C<namespace> (string) — Target namespace

=back

=head2 k8s_apply

Create or update a Kubernetes resource (like C<kubectl apply>). Tries to
create the resource first; if it already exists (409 Conflict), falls back
to a strategic merge patch.

B<Parameters:>

=over 4

=item C<resource> (string, B<required>) — Resource type (e.g. C<Deployment>, C<ConfigMap>)

=item C<manifest> (object, B<required>) — Resource manifest. Must include C<metadata.name>.

=item C<namespace> (string) — Target namespace

=back

Returns JSON confirmation with the action taken (C<created> or C<updated>).

=head2 run_stdio

  # As class method:
  MCP::K8s->run_stdio;

  # As instance method:
  my $k8s = MCP::K8s->new(%opts);
  $k8s->run_stdio;

Start the MCP server on stdio. If called as a class method, creates a
new instance first. This is the main entry point used by the C<mcp-k8s>
script.

=head1 ENVIRONMENT

=over 4

=item C<KUBECONFIG>

Path to kubeconfig file. Default: C<~/.kube/config>.
Standard Kubernetes environment variable, also used by C<kubectl>.

=item C<MCP_K8S_CONTEXT>

Kubeconfig context to use. Default: the kubeconfig's C<current-context>.

=item C<MCP_K8S_TOKEN>

Bearer token for direct authentication. Bypasses kubeconfig entirely.
Useful for CI/CD pipelines or when you have a service account token.

=item C<MCP_K8S_SERVER>

Kubernetes API server URL. Used with C<MCP_K8S_TOKEN> or in-cluster auth.
Default when in-cluster: C<https://kubernetes.default.svc.cluster.local>.

=item C<MCP_K8S_NAMESPACES>

Comma-separated list of namespaces to operate on.
Default: auto-discovered from the cluster (lists all namespaces the
service account can see). Falls back to C<default> if discovery fails.

=back

=head1 AUTHENTICATION

MCP::K8s supports three authentication methods, tried in order:

=over 4

=item 1. B<Direct token> — Set C<MCP_K8S_TOKEN> (and optionally C<MCP_K8S_SERVER>)

=item 2. B<In-cluster> — Auto-detected when running as a Kubernetes pod (reads mounted service account token from C</var/run/secrets/kubernetes.io/serviceaccount/token>)

=item 3. B<Kubeconfig> — Reads C<~/.kube/config> (or C<$KUBECONFIG>), optionally filtered by C<MCP_K8S_CONTEXT>

=back

For in-cluster and direct token auth, the CA certificate at
C</var/run/secrets/kubernetes.io/serviceaccount/ca.crt> is automatically
used if present.

=head1 RBAC SETUP

Use a dedicated ServiceAccount with minimal permissions for AI access.
Example RBAC manifests are included in the C<examples/> directory:

=over 4

=item C<examples/readonly-serviceaccount.yaml> — Read-only access (recommended starting point)

=item C<examples/deployer-serviceaccount.yaml> — Read + deploy/restart capabilities

=item C<examples/full-ops-serviceaccount.yaml> — Full access except secrets

=back

RBAC is the single source of truth — if the service account shouldn't have
access, don't grant it via RBAC. MCP::K8s does B<not> implement
application-layer permission filtering.

=head1 CLAUDE DESKTOP INTEGRATION

Add this to your Claude Desktop MCP configuration
(C<~/.config/claude/claude_desktop_config.json>):

  {
    "mcpServers": {
      "kubernetes": {
        "command": "mcp-k8s",
        "env": {
          "MCP_K8S_CONTEXT": "my-cluster",
          "MCP_K8S_NAMESPACES": "default,production"
        }
      }
    }
  }

=head1 CLAUDE CODE INTEGRATION

Add to your project's C<.mcp.json> or global MCP settings:

  {
    "mcpServers": {
      "kubernetes": {
        "command": "mcp-k8s",
        "env": {
          "MCP_K8S_CONTEXT": "dev-cluster"
        }
      }
    }
  }

=head1 LANGERTHA RAIDER INTEGRATION

Use L<Langertha::Raider> to build an autonomous AI agent that can
interact with your Kubernetes cluster using MCP::K8s as its tool source:

  use IO::Async::Loop;
  use Future::AsyncAwait;
  use Net::Async::MCP;
  use Langertha::Engine::Anthropic;
  use Langertha::Raider;
  use MCP::K8s;

  my $k8s = MCP::K8s->new(
    namespaces => ['default', 'production'],
  );

  my $loop = IO::Async::Loop->new;
  my $mcp = Net::Async::MCP->new(server => $k8s->server);
  $loop->add($mcp);

  async sub main {
    await $mcp->initialize;

    my $engine = Langertha::Engine::Anthropic->new(
      api_key     => $ENV{ANTHROPIC_API_KEY},
      model       => 'claude-sonnet-4-6',
      mcp_servers => [$mcp],
    );

    my $raider = Langertha::Raider->new(
      engine  => $engine,
      mission => 'You are a Kubernetes operations assistant. '
               . 'Always check permissions first, then help the user '
               . 'investigate and manage their cluster.',
    );

    # First raid: discover capabilities
    my $r1 = await $raider->raid_f('What can I do on this cluster?');
    say $r1;

    # Second raid: uses history from the first
    my $r2 = await $raider->raid_f('List all pods and check for any issues.');
    say $r2;
  }

  main()->get;

The Raider maintains conversation history across raids, so the LLM
can reference earlier context (e.g. the RBAC permissions it discovered)
in follow-up interactions.

A ready-to-run demo is included in C<examples/raider-configmap-demo.pl> — an AI
creates, reads, updates, and deletes a ConfigMap. See the script's POD
for requirements.

=head1 SECURITY CONSIDERATIONS

=over 4

=item * The server inherits the permissions of whatever kubeconfig context
it connects with. Use a dedicated service account with minimal RBAC
permissions for AI assistant access.

=item * All tool calls check RBAC permissions B<before> executing. Even if
the service account has broad permissions, the permission check provides
a clear audit trail.

=item * Secrets are supported as a resource type. If your service account
can read secrets, the LLM will be able to read them too. Consider excluding
C<secrets> from RBAC roles used for AI access.

=back

=head1 SEE ALSO

L<MCP::K8s::Permissions> — RBAC discovery engine

L<MCP::Kubernetes> — Alias for this module

L<Langertha::Raider> — Autonomous agent with conversation history and MCP tools

L<Kubernetes::REST> — The underlying Kubernetes API client

L<IO::K8s> — Typed Kubernetes resource objects

L<MCP::Server> — MCP protocol implementation

L<Kubernetes::REST::Kubeconfig> — Kubeconfig parsing

L<https://modelcontextprotocol.io/> — Model Context Protocol specification

L<https://kubernetes.io/docs/reference/access-authn-authz/rbac/> — Kubernetes RBAC

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-mcp-k8s/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
