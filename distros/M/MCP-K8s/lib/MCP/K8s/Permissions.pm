package MCP::K8s::Permissions;
# ABSTRACT: RBAC discovery and permission checking for Kubernetes
our $VERSION = '0.004';
use Moo;
use Carp qw( croak );
use Scalar::Util qw( weaken );
use namespace::clean;


has api => (
  is       => 'ro',
  required => 1,
  weak_ref => 1,
);


has namespaces => (
  is       => 'ro',
  required => 1,
);


has scope_resolver => (
  is        => 'ro',
  predicate => 1,
);


has _rules => (
  is      => 'rw',
  default => sub { {} },
);

has _discovered => (
  is      => 'rw',
  default => 0,
);

sub discover {
  my ($self) = @_;


  my %rules;
  my %reviewed;

  for my $ns (@{ $self->namespaces }) {
    my $ns_rules = eval { $self->_discover_namespace($ns) };
    if ($@) {
      warn "Failed to discover permissions for namespace '$ns': $@";
      next;
    }
    $reviewed{$ns} = $ns_rules;
    $rules{$ns} = $ns_rules if keys %$ns_rules;
  }

  my $cluster_rules = $self->_cluster_rules(\%reviewed);
  $rules{''} = $cluster_rules if keys %$cluster_rules;

  $self->_rules(\%rules);
  $self->_discovered(1);
  return $self;
}

sub _cluster_rules {
  my ($self, $reviewed) = @_;

  my @maps = values %$reviewed;
  return {} unless @maps;

  # Every (resource, verb) pair any of the namespaces knows about.
  my %pairs;
  for my $map (@maps) {
    for my $resource (keys %$map) {
      $pairs{$resource}{$_} = 1 for keys %{ $map->{$resource} };
    }
  }

  # Of those, the ones every namespace knows about too. The wildcard rules
  # are read the way can_do reads them, so a namespace holding "*" covers
  # the explicit pairs the other namespaces bring.
  my %cluster;
  for my $resource (sort keys %pairs) {
    for my $verb (sort keys %{ $pairs{$resource} }) {
      my $everywhere = 1;
      for my $map (@maps) {
        unless ($self->_map_allows($map, $resource, $verb)) {
          $everywhere = 0;
          last;
        }
      }
      next unless $everywhere;

      # A namespaced resource is never cluster-scoped, whatever the rules
      # say. The wildcard carries no scope of its own and stays.
      if ($resource ne '*') {
        my $scope = $self->_scope_of($resource);
        next if defined $scope && $scope;
      }

      $cluster{$resource}{$verb} = 1;
    }
  }

  return \%cluster;
}

sub _scope_of {
  my ($self, $plural) = @_;

  my $resolver = $self->scope_resolver or return undef;
  my $scope = eval { $resolver->($plural) };
  return $@ ? undef : $scope;
}

sub _discover_namespace {
  my ($self, $namespace) = @_;

  my $review = $self->api->new_object('SelfSubjectRulesReview', {
    spec => {
      namespace => $namespace,
    },
  });

  my $result = $self->api->create($review);
  my $status = $result->status;
  return {} unless $status;

  my %ns_rules;
  my $resource_rules = $status->resourceRules // [];

  for my $rule (@$resource_rules) {
    my @verbs     = @{ $rule->verbs // [] };
    my @resources = @{ $rule->resources // [] };

    for my $resource (@resources) {
      # Subresources (pods/log, deployments/status, ...) are kept. RBAC treats
      # them as resources in their own right — patch on 'deployments' does not
      # grant patch on 'deployments/status' — so can_do has to be able to see
      # them, or a correctly narrow Role gets a false denial. They can never
      # collide with a base plural: a subresource name always contains '/'.
      # Filtering happens on the presentation side instead, in
      # L</allowed_resources>, which is what feeds the tool descriptions.
      for my $verb (@verbs) {
        $ns_rules{$resource}{$verb} = 1;
        # Wildcard verb means all standard verbs
        if ($verb eq '*') {
          $ns_rules{$resource}{$_} = 1 for qw(get list watch create update patch delete);
        }
      }
    }

    # Wildcard resource means all resources for these verbs
    if (grep { $_ eq '*' } @resources) {
      for my $verb (@verbs) {
        $ns_rules{'*'}{$verb} = 1;
        if ($verb eq '*') {
          $ns_rules{'*'}{$_} = 1 for qw(get list watch create update patch delete);
        }
      }
    }
  }

  return \%ns_rules;
}

sub ensure_discovered {
  my ($self) = @_;
  return $self if $self->_discovered;
  return $self->discover;
}

sub can_do {
  my ($self, $verb, $resource_plural, $namespace) = @_;


  $self->ensure_discovered;
  $namespace //= '';

  my $ns_rules = $self->_rules->{$namespace};
  return 0 unless $ns_rules;

  return $self->_map_allows($ns_rules, $resource_plural, $verb) ? 1 : 0;
}

sub _map_allows {
  my ($self, $map, $resource, $verb) = @_;

  # Check explicit resource permission
  return 1 if $map->{$resource} && $map->{$resource}{$verb};
  # Check wildcard verb on explicit resource
  return 1 if $map->{$resource} && $map->{$resource}{'*'};
  # Check wildcard resource
  return 1 if $map->{'*'} && $map->{'*'}{$verb};
  return 1 if $map->{'*'} && $map->{'*'}{'*'};

  return 0;
}

sub allowed_resources {
  my ($self, $verb, $namespace) = @_;


  $self->ensure_discovered;
  $namespace //= '';

  my $ns_rules = $self->_rules->{$namespace};
  return () unless $ns_rules;

  my @resources;
  for my $resource (sort keys %$ns_rules) {
    next if $resource eq '*';
    next if $resource =~ m{/};  # skip subresources
    if ($ns_rules->{$resource}{$verb}
        || $ns_rules->{$resource}{'*'}
        || ($ns_rules->{'*'} && ($ns_rules->{'*'}{$verb} || $ns_rules->{'*'}{'*'}))) {
      push @resources, $resource;
    }
  }

  # If wildcard resource is allowed, indicate that
  if ($ns_rules->{'*'} && ($ns_rules->{'*'}{$verb} || $ns_rules->{'*'}{'*'})) {
    unshift @resources, '*' unless grep { $_ eq '*' } @resources;
  }

  return @resources;
}

sub allowed_namespaces {
  my ($self) = @_;


  $self->ensure_discovered;
  return grep { $_ ne '' } sort keys %{ $self->_rules };
}

sub can_read_logs {
  my ($self, $namespace) = @_;


  $self->ensure_discovered;
  $namespace //= '';
  my $ns_rules = $self->_rules->{$namespace};
  return 0 unless $ns_rules;

  # Check pods/log get permission
  return 1 if $ns_rules->{'pods/log'} && ($ns_rules->{'pods/log'}{'get'} || $ns_rules->{'pods/log'}{'*'});
  # Wildcard resource covers subresources too
  return 1 if $ns_rules->{'*'} && ($ns_rules->{'*'}{'get'} || $ns_rules->{'*'}{'*'});
  # pods wildcard often implies pods/log
  return 1 if $ns_rules->{'pods'} && ($ns_rules->{'pods'}{'get'} || $ns_rules->{'pods'}{'*'});

  return 0;
}

sub summary {
  my ($self) = @_;


  $self->ensure_discovered;
  my @lines;
  push @lines, "# Kubernetes RBAC Permissions\n";

  my @namespaces = $self->allowed_namespaces;
  unless (@namespaces) {
    push @lines, "No namespace permissions discovered.";
    return join("\n", @lines);
  }

  for my $ns (@namespaces) {
    push @lines, "## Namespace: $ns\n";

    my $ns_rules = $self->_rules->{$ns};
    if ($ns_rules->{'*'} && $ns_rules->{'*'}{'*'}) {
      push @lines, "Full access (all resources, all verbs)\n";
      next;
    }

    my %by_verb;
    for my $resource (sort keys %$ns_rules) {
      next if $resource eq '*';
      for my $verb (sort keys %{ $ns_rules->{$resource} }) {
        next if $verb eq '*';
        push @{ $by_verb{$verb} }, $resource;
      }
      if ($ns_rules->{$resource}{'*'}) {
        push @{ $by_verb{'all verbs'} }, $resource;
      }
    }

    for my $verb (sort keys %by_verb) {
      my @resources = @{ $by_verb{$verb} };
      push @lines, "- **$verb**: " . join(', ', @resources);
    }

    push @lines, "";
  }

  # Cluster-scoped
  if (my $cluster = $self->_rules->{''}) {
    push @lines, "## Cluster-scoped\n";
    if ($cluster->{'*'} && $cluster->{'*'}{'*'}) {
      push @lines, "Full cluster access (all resources, all verbs)\n";
    } else {
      for my $resource (sort keys %$cluster) {
        next if $resource eq '*';
        my @verbs = sort keys %{ $cluster->{$resource} };
        push @lines, "- **$resource**: " . join(', ', @verbs);
      }
      push @lines, "";
    }
  }

  return join("\n", @lines);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MCP::K8s::Permissions - RBAC discovery and permission checking for Kubernetes

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use MCP::K8s::Permissions;

  my $perms = MCP::K8s::Permissions->new(
    api        => $kubernetes_rest_api,
    namespaces => ['default', 'production'],
  );

  # Discover what the current service account can do
  $perms->discover;

  # Check specific permissions
  if ($perms->can_do('list', 'pods', 'default')) {
    say "Can list pods in default namespace";
  }

  # Get all resources allowed for a verb
  my @listable = $perms->allowed_resources('list', 'default');

  # Check pod log access
  if ($perms->can_read_logs('production')) {
    say "Can read pod logs in production";
  }

  # Human-readable summary (Markdown formatted)
  say $perms->summary;

=head1 DESCRIPTION

MCP::K8s::Permissions encapsulates Kubernetes RBAC discovery using
the C<SelfSubjectRulesReview> API. On L</discover>, it submits a
review request for each configured namespace, parses the returned
C<ResourceRule> entries, and builds an internal permission map.

The cluster scope is not reviewed on its own — the API server rejects a
review without a namespace (C<400 no namespace on request>). It is
derived from the namespace reviews instead: the rules a
C<ClusterRoleBinding> grants appear in every namespace review, the rules
a C<RoleBinding> grants only in its own. What all namespace reviews have
in common is what the account may do cluster-wide. L</scope_resolver>
tells the derivation which of those resources are cluster-scoped, so a
namespaced resource never lands in the cluster-scope map.

This map powers permission checks throughout L<MCP::K8s> — every tool
verifies access before making API calls, providing clear error messages
when a service account lacks the required permissions.

B<Wildcard handling:> The C<*> wildcard in verbs or resources is expanded
at discovery time. A rule with C<verbs: ["*"]> grants all standard Kubernetes
verbs (get, list, watch, create, update, patch, delete). A rule with
C<resources: ["*"]> grants access to all resource types — subresources
included, as in Kubernetes itself.

B<Subresources:> Entries like C<pods/log> or C<deployments/status> are kept
in the map exactly as the API server reports them, because RBAC treats them
as resources in their own right: C<patch> on C<deployments> does not grant
C<patch> on C<deployments/status>. Callers therefore ask for the full name —
C<< $perms->can_do('patch', 'deployments/status', $ns) >>. They cannot
collide with a base plural, which never contains a C</>. Presentation is
where they are filtered out again: L</allowed_resources> omits them, so the
tool descriptions built from it stay about main endpoints.

=head2 api

Required. A L<Kubernetes::REST> instance used to submit C<SelfSubjectRulesReview>
requests. Stored as a weak reference to avoid circular references with
the parent L<MCP::K8s> object.

=head2 namespaces

Required. ArrayRef of namespace names to discover permissions for. Typically
comes from C<$ENV{MCP_K8S_NAMESPACES}> or auto-discovery in L<MCP::K8s>.

=head2 scope_resolver

Optional. Coderef that answers the scope of a resource plural. Called with
the plural (e.g. C<'pods'>) and returns 1 for a namespaced resource, 0 for a
cluster-scoped one and C<undef> when the scope is unknown.

L<MCP::K8s> passes a resolver built from the API discovery, which knows the
C<namespaced> flag of every resource the cluster serves. It is what keeps
namespaced resources out of the cluster-scope map.

=head2 discover

  $perms->discover;

Submit C<SelfSubjectRulesReview> requests for each namespace in L</namespaces>
and populate the internal permission map.

The cluster scope is derived from the namespace reviews. A
C<SelfSubjectRulesReview> is namespace-scoped by design — the API server
rejects a review without a namespace with C<400 no namespace on request> —
but the rules a C<ClusterRoleBinding> grants show up in B<every> namespace
review, while the rules a C<RoleBinding> grants only show up in its own
namespace. The rules that all namespace reviews have in common are therefore
the cluster-wide ones.

Returns C<$self> for chaining.

Failures for individual namespaces are warned and skipped — a single
inaccessible namespace won't prevent discovery of the others.

=head2 can_do

  my $allowed = $perms->can_do('list', 'pods', 'default');
  my $allowed = $perms->can_do('create', 'deployments', 'production');

Check whether the current service account is allowed to perform C<$verb>
on C<$resource_plural> in C<$namespace>. Returns a boolean.

C<$namespace> defaults to C<''> (cluster scope) if not provided.

Handles wildcards: if the account has C<*> on verbs or resources for the
given namespace, the check succeeds.

=head2 allowed_resources

  my @resources = $perms->allowed_resources('list', 'default');
  # => ('configmaps', 'deployments', 'pods', 'services')

Return a sorted list of resource plurals that are allowed for C<$verb> in
C<$namespace>. If the account has wildcard resource access, C<'*'> is
prepended to the list.

Subresources (e.g. C<pods/log>) are excluded from the returned list.

=head2 allowed_namespaces

  my @ns = $perms->allowed_namespaces;

Return a sorted list of namespaces that have any discovered permissions.
Excludes the cluster scope (empty string).

=head2 can_read_logs

  if ($perms->can_read_logs('default')) { ... }

Check whether pod log access is available in C<$namespace>. This checks
for the C<pods/log> subresource C<get> permission, wildcard resource
access, or general C<pods> C<get> access (which in practice implies
log access on most clusters).

=head2 summary

  my $text = $perms->summary;

Generate a human-readable Markdown-formatted summary of all discovered
permissions. Organized by namespace, with verbs grouped and their
allowed resources listed.

This is the output returned by the C<k8s_permissions> MCP tool — designed
to give an LLM a quick overview of what it can and cannot do.

Example output:

  # Kubernetes RBAC Permissions

  ## Namespace: default

  - **get**: deployments, pods, services
  - **list**: deployments, pods, services
  - **create**: configmaps
  - **delete**: configmaps

  ## Namespace: admin

  Full access (all resources, all verbs)

=head1 SEE ALSO

L<MCP::K8s> — Main module that uses this for tool registration

L<IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview> — The K8s API object used for discovery

L<IO::K8s::Api::Authorization::V1::ResourceRule> — Individual permission rules

L<https://kubernetes.io/docs/reference/access-authn-authz/rbac/> — Kubernetes RBAC documentation

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/p5-mcp-k8s/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
