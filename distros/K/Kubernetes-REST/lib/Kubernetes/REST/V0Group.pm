package Kubernetes::REST::V0Group;
our $VERSION = '1.109';
# ABSTRACT: Base class for backwards-compatible v0 API group wrappers
use Moo;
use Carp qw(croak carp);
use IO::K8s ();

has api => (is => 'ro', required => 1);
has group => (is => 'ro', required => 1);
has version => (is => 'ro', default => sub { 'v1' });

# Kinds whose own name ends in Status - ComponentStatus is the only built-in
# one. _parse_method's non-greedy resource capture would otherwise read
# ListComponentStatus as the Kind Component plus a Status subresource suffix
# and die loading a non-existent IO::K8s::Api::Core::V1::Component. Built once
# from what the installed IO::K8s ships (bare Kind names, not the versioned
# aliases), so a future Status-named Kind is handled too (karr k66).
my %STATUS_KIND = map { $_ => 1 }
    grep { /Status\z/ && !m{/} }
    keys %{ IO::K8s->default_resource_map };

# ============================================================================
# BACKWARDS COMPATIBILITY LAYER (v0 API → v1 API)
#
# The original Kubernetes::REST (v0.01/v0.02, by JLMARTIN) used method names
# like $api->Core->ListNamespacedPod(...) with dedicated Call classes in
# lib/Kubernetes/REST/Call/v1/Core/ListNamespacedPod.pm (978 classes total).
#
# Our v1 rewrite simplified this to $api->list('Pod', namespace => ...).
#
# AUTOLOAD catches the old method names (e.g. "ListNamespacedPod"), parses
# them into action + resource, and dispatches to the new API. Each call
# emits a deprecation warning showing the new equivalent call.
#
# Subclasses (Kubernetes::REST::Core, ::Apps, ::Batch, etc.) only set the
# 'group' attribute. AUTOLOAD + _parse_method + _dispatch handle the rest.
#
# Pattern: {Action}{Namespaced?}{Resource}{ForAllNamespaces?}
#   Actions: List, Read, Create, Replace, Patch, Delete, Watch
#   Example: ListNamespacedPod → list('IO::K8s::Api::Core::V1::Pod', ...)
#
# The old Call classes no longer ship here at all - their names are tombstoned
# in Kubernetes-REST-Deprecated. This layer is the only thing left keeping the
# v0 method names alive, and can go once no downstream code uses them.
# ============================================================================

our $AUTOLOAD;

# AUTOLOAD dispatches to list/get/update/... in Kubernetes::REST, so an
# APIError thrown there - or a plain croak - has this layer's frames between
# it and the caller. Trust Kubernetes::REST so Carp's bidirectional check
# walks past both packages and blames the code that made the v0 call, not
# V0Group.pm; the object model's own errors are unaffected (karr k67).
our @CARP_NOT = ('Kubernetes::REST');

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    return if $method eq 'DESTROY';

    # Parse method name: ListNamespacedPod, ReadNamespacedPod, CreateNamespacedPod, etc.
    my ($action, $namespaced, $resource, $status) = _parse_method($method);

    unless ($action && $resource) {
        croak "Unknown method: $method";
    }

    # Build class name
    my $class = $self->_build_class($resource);

    # Convert args to hash if needed
    my %params = @args == 1 && ref($args[0]) eq 'HASH' ? %{$args[0]} : @args;

    # Read*Status reads the status subresource, not the object itself (karr
    # k62); get takes it since k58. Set here, the warning names it too.
    $params{subresource} = 'status' if $status && $action eq 'read';

    # Show deprecation warning
    $self->_warn_deprecated($method, $action, $class, \%params, $status);

    # Call new API
    return $self->_dispatch($action, $class, \%params, $status);
}

sub _parse_method {
    my ($method) = @_;

    # Patterns: List/Read/Create/Replace/Patch/Delete/Watch + Namespaced? + Resource + ForAllNamespaces|Status?
    # The fourth value says whether the name ends in Status.
    if ($method =~ /^(List|Read|Create|Replace|Patch|Delete|Watch)(Namespaced)?(\w+?)(ForAllNamespaces|Status)?$/) {
        my ($action, $namespaced, $resource, $suffix) = ($1, $2, $3, $4);

        # A Kind that itself ends in Status (ComponentStatus) is one whole
        # resource, not a shorter Kind plus a Status subresource: the
        # non-greedy capture split it, so put the suffix back (karr k66).
        if ($suffix && $suffix eq 'Status' && $STATUS_KIND{$resource . $suffix}) {
            $resource .= $suffix;
            $suffix = undef;
        }

        $namespaced = 0 if $suffix && $suffix eq 'ForAllNamespaces';
        return (lc($action), $namespaced ? 1 : 0, $resource,
            ($suffix && $suffix eq 'Status') ? 1 : 0);
    }

    return (undef, undef, undef);
}

# v0 group name -> IO::K8s group path. Only entries that actually rename
# something belong here; anything else falls through to the group name as
# written, which is already the IO::K8s spelling for every shipped group.
my %GROUP_MAP = (
    RbacAuthorization => 'Rbac',
);

sub _build_class {
    my ($self, $resource) = @_;
    my $group = $self->group;
    my $version = ucfirst(lc($self->version));

    my $io_group = $GROUP_MAP{$group} // $group;

    # Not every group lives under IO::K8s::Api:: - apiextensions and
    # apiregistration sit in their own staging namespaces. Kubernetes::REST
    # owns that table, so ask it rather than reimplementing the exception
    # here; the two copies drifting apart is exactly what broke this before.
    return 'IO::K8s::' . $self->api->_io_k8s_namespace_for_group_path($io_group)
        . "::${version}::${resource}";
}

sub _warn_deprecated {
    my ($self, $method, $action, $class, $params, $status) = @_;

    return if $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};

    my $group = $self->group;
    my $new_call;

    if ($action eq 'list') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        $new_call = "\$api->list('$class'$ns)";
    } elsif ($action eq 'read') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        my $sub = $params->{subresource} ? ", subresource => '$params->{subresource}'" : '';
        $new_call = "\$api->get('$class', name => '$params->{name}'$ns$sub)";
    } elsif ($action eq 'create') {
        $new_call = "\$api->create(\$object)";
    } elsif ($action eq 'replace') {
        $new_call = $status ? "\$api->update_status(\$object)"
                            : "\$api->update(\$object)";
    } elsif ($action eq 'delete') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        $new_call = "\$api->delete('$class', name => '$params->{name}'$ns)";
    } elsif ($action eq 'patch') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        my $name = $status ? 'patch_status' : 'patch';
        $new_call = "\$api->$name('$class', name => '$params->{name}'$ns, patch => \\%patch)";
    } elsif ($action eq 'watch') {
        my $ns = $params->{namespace} ? ", namespace => '$params->{namespace}'" : '';
        $new_call = "\$api->watch('$class'$ns, on_event => sub { ... })";
    } else {
        $new_call = "\$api->$action('$class', ...)";
    }

    carp "Kubernetes::REST v0 API is deprecated: \$api->$group->$method(...) should be: $new_call";
}

sub _dispatch {
    my ($self, $action, $class, $params, $status) = @_;
    my $api = $self->api;

    if ($action eq 'list') {
        # list, get and watch croak on arguments they do not take, as delete
        # does (below). The v0 parameters they have no use for (limit,
        # pretty, watch, timeoutSeconds, ...) were ignored all along; they
        # stay ignored rather than break v0 callers. A List* name goes with
        # them: it made the request a GET of one object, read as an empty
        # list (karr k58).
        my %args = map { exists $params->{$_} ? ($_ => $params->{$_}) : () }
            qw(namespace labelSelector fieldSelector);
        return $api->list($class, %args);
    } elsif ($action eq 'read') {
        my %args = map { exists $params->{$_} ? ($_ => $params->{$_}) : () }
            qw(name namespace subresource);
        return $api->get($class, %args);
    } elsif ($action eq 'create') {
        # For create, we need the body object
        my $body = $params->{body} // croak "create requires 'body' parameter";
        return $api->create($body);
    } elsif ($action eq 'replace') {
        my $body = $params->{body} // croak "replace requires 'body' parameter";
        # Replace*Status replaces through the /status subresource: a plain
        # update writes the main endpoint, where the server drops the status
        # and still answers 2xx, losing it silently (karr k65).
        return $status ? $api->update_status($body) : $api->update($body);
    } elsif ($action eq 'delete') {
        # delete croaks on arguments it does not take. The v0 parameters it
        # has no use for (body, gracePeriodSeconds, dryRun, ...) were ignored
        # all along; they stay ignored rather than break v0 callers.
        my %args = map { exists $params->{$_} ? ($_ => $params->{$_}) : () }
            qw(name namespace propagationPolicy);
        return $api->delete($class, %args);
    } elsif ($action eq 'patch') {
        # patch croaks on arguments it does not take (karr k61); the v0
        # parameters it has no use for (pretty, dryRun, fieldManager, ...)
        # stay ignored, as with delete above.
        my %args = map { exists $params->{$_} ? ($_ => $params->{$_}) : () }
            qw(name namespace patch type);
        # Patch*Status patches through /status, for the same reason as
        # Replace*Status above (karr k65).
        return $status ? $api->patch_status($class, %args) : $api->patch($class, %args);
    } elsif ($action eq 'watch') {
        my %args = map { exists $params->{$_} ? ($_ => $params->{$_}) : () }
            qw(on_event timeout resourceVersion labelSelector fieldSelector namespace);
        return $api->watch($class, %args);
    } else {
        croak "Unknown action: $action";
    }
}

# Prevent AUTOLOAD from being called for can()
sub can {
    my ($self, $method) = @_;
    return $self->SUPER::can($method) if $self->SUPER::can($method);
    # For v0 API methods, we always "can"
    my ($action, $namespaced, $resource) = _parse_method($method);
    return sub { $self->$method(@_) } if $action && $resource;
    return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::V0Group - Base class for backwards-compatible v0 API group wrappers

=head1 VERSION

version 1.109

=head1 SYNOPSIS

    # This API is deprecated - use the new API instead
    my $api = Kubernetes::REST->new(...);

    # Old way (deprecated):
    my $pods = $api->Core->ListNamespacedPod(namespace => 'default');

    # New way:
    my $pods = $api->list('Pod', namespace => 'default');

=head1 DESCRIPTION

This module provides backwards compatibility for the old v0 API that used method
names like C<ListNamespacedPod>, C<ReadNamespacedPod>, etc. It translates these
calls to the new simplified API.

Every call through this layer emits a deprecation warning unless you set
C<$ENV{HIDE_KUBERNETES_REST_V0_API_WARNING}>.

See L<Kubernetes::REST/"UPGRADING FROM 0.02"> for migration guide.

=head1 METHODS

This module uses C<AUTOLOAD> to intercept method calls like C<ListNamespacedPod>
and translates them to the new API. The following actions are supported:

=over 4

=item * List -> list()

=item * Read -> get(); a name ending in C<Status> (C<ReadNamespacedPodStatus>)
reads the status subresource, C<< get(..., subresource => 'status') >>

=item * Create -> create()

=item * Replace -> update(); a name ending in C<Status>
(C<ReplaceNamespacedPodStatus>) replaces through the status subresource,
C<update_status()>

=item * Delete -> delete()

=item * Patch -> patch(); a name ending in C<Status>
(C<PatchNamespacedPodStatus>) patches through the status subresource,
C<patch_status()>

=item * Watch -> watch()

=back

List, Read, Watch, Delete and Patch pass on only the parameters the new
method takes - C<namespace>, C<labelSelector> and C<fieldSelector>; C<name>,
C<namespace> and C<subresource>; C<on_event>, C<timeout>,
C<resourceVersion>, C<labelSelector>, C<fieldSelector> and C<namespace>;
C<name>, C<namespace> and C<propagationPolicy>; C<name>, C<namespace>,
C<patch> and C<type> - and ignore the others, which the new methods croak
on.

The trailing C<Status> is only a subresource suffix when the Kind before it is
a real Kind. A Kind whose own name ends in C<Status> - C<ComponentStatus> is
the only built-in one - is kept whole: C<ListComponentStatus> and
C<ReadComponentStatus> resolve the C<ComponentStatus> Kind itself, not a
C<Status> subresource of a C<Component>.

=head1 SEE ALSO

L<Kubernetes::REST>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
