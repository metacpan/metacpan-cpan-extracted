package MCP::K8s::Permissions;
# ABSTRACT: RBAC discovery and permission checking for Kubernetes
our $VERSION = '0.002';
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

  for my $ns (@{ $self->namespaces }) {
    my $ns_rules = eval { $self->_discover_namespace($ns) };
    if ($@) {
      warn "Failed to discover permissions for namespace '$ns': $@";
      next;
    }
    $rules{$ns} = $ns_rules if keys %$ns_rules;
  }

  # Also try cluster-scoped discovery (empty namespace)
  my $cluster_rules = eval { $self->_discover_namespace('') };
  if (!$@ && keys %$cluster_rules) {
    $rules{''} = $cluster_rules;
  }

  $self->_rules(\%rules);
  $self->_discovered(1);
  return $self;
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
      # Skip subresources except pods/log which we handle specifically
      next if $resource =~ m{/} && $resource ne 'pods/log';

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

  # Check explicit resource permission
  return 1 if $ns_rules->{$resource_plural} && $ns_rules->{$resource_plural}{$verb};
  # Check wildcard verb on explicit resource
  return 1 if $ns_rules->{$resource_plural} && $ns_rules->{$resource_plural}{'*'};
  # Check wildcard resource
  return 1 if $ns_rules->{'*'} && $ns_rules->{'*'}{$verb};
  return 1 if $ns_rules->{'*'} && $ns_rules->{'*'}{'*'};

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

version 0.002

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
review request for each configured namespace (plus cluster scope),
parses the returned C<ResourceRule> entries, and builds an internal
permission map.

This map powers permission checks throughout L<MCP::K8s> — every tool
verifies access before making API calls, providing clear error messages
when a service account lacks the required permissions.

B<Wildcard handling:> The C<*> wildcard in verbs or resources is expanded
at discovery time. A rule with C<verbs: ["*"]> grants all standard Kubernetes
verbs (get, list, watch, create, update, patch, delete). A rule with
C<resources: ["*"]> grants access to all resource types.

=head2 api

Required. A L<Kubernetes::REST> instance used to submit C<SelfSubjectRulesReview>
requests. Stored as a weak reference to avoid circular references with
the parent L<MCP::K8s> object.

=head2 namespaces

Required. ArrayRef of namespace names to discover permissions for. Typically
comes from C<$ENV{MCP_K8S_NAMESPACES}> or auto-discovery in L<MCP::K8s>.

=head2 discover

  $perms->discover;

Submit C<SelfSubjectRulesReview> requests for each namespace in L</namespaces>
plus an empty-namespace request for cluster-scoped resources. Populates the
internal permission map.

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
