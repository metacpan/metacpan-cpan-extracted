package IO::K8s::APIObject;
# ABSTRACT: Base class for top-level Kubernetes API objects
our $VERSION = '1.108';
use v5.10;
use IO::K8s::Resource ();
use Import::Into;
use Package::Stash;
use Moo::Role ();
use Carp qw( croak );


sub import {
    my $class = shift;
    my %params = @_;
    my $caller = caller;

    # First, do everything IO::K8s::Resource does
    IO::K8s::Resource->import::into($caller);

    # Install CRD overrides *before* applying the role
    # This way the role sees these methods and doesn't install its defaults
    if (my $api_ver = $params{api_version}) {
        my $stash = Package::Stash->new($caller);
        # A fixed identity method, not a writable field: reject an argument
        # rather than swallow it (k67).
        $stash->add_symbol('&api_version', sub {
            croak 'api_version is fixed for this class and cannot be set' if @_ > 1;
            $api_ver;
        });
    }
    if (my $plural = $params{resource_plural}) {
        my $stash = Package::Stash->new($caller);
        # A fixed identity method, not a writable field: reject an argument
        # rather than swallow it (k70, same shape as k67).
        $stash->add_symbol('&resource_plural', sub {
            croak 'resource_plural is fixed for this class and cannot be set' if @_ > 1;
            $plural;
        });
    }

    # Apply the APIObject role (provides metadata, labels, conditions,
    # owners -- and, since k103, IO::K8s::Role::SpecBuilder, which that role
    # composes for every top-level Kind rather than only for CRDs)
    Moo::Role->apply_roles_to_package($caller, 'IO::K8s::Role::APIObject');

    # Register metadata attribute using the k8s DSL
    # This allows _inflate_struct to properly inflate metadata as ObjectMeta
    # The k8s function skips attribute creation if it already exists (from the role)
    $caller->can('k8s')->('metadata', 'Meta::V1::ObjectMeta');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::APIObject - Base class for top-level Kubernetes API objects

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    # Built-in API object (api_version/kind derived from class name):
    package IO::K8s::Api::Core::V1::Pod;
    use IO::K8s::APIObject;

    k8s spec => 'Core::V1::PodSpec';
    k8s status => 'Core::V1::PodStatus';

    1;

    # Custom Resource Definition (CRD):
    package My::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites';
    with 'IO::K8s::Role::Namespaced';

    k8s spec   => { Str => 1 };
    k8s status => { Str => 1 };

    1;

=head1 DESCRIPTION

Like L<IO::K8s::Resource>, but for top-level Kubernetes API objects.
Automatically applies L<IO::K8s::Role::APIObject> which provides:

=over 4

=item * C<metadata> attribute

=item * C<api_version()> method (derived from class name)

=item * C<kind()> method (derived from class name)

=item * C<resource_plural()> method (from a generated table for built-in
Kinds; C<undef> when there is no plural, e.g. a subresource)

=item * Label, annotation, condition, and owner convenience methods

=back

C<api_version()> and C<resource_plural()> are fixed identity methods, not
writable fields: when a CRD declares its own via the import parameters
below, passing an argument croaks rather than silently rebinding (k67, k70).
The methods derive their value from the class name in the built-in case, so
the same guard applies -- see L<IO::K8s::Role::APIObject> for the exact
messages.

For Custom Resource Definitions (CRDs), pass C<api_version> and
optionally C<resource_plural> as import parameters. These are installed
as class methods before the role is composed, avoiding redefinition warnings.

Every class built this way gets L<IO::K8s::Role::SpecBuilder> for
deep-path spec manipulation (C<spec_get>, C<spec_set>, C<spec_array>,
C<spec_hash>, C<spec_push>, C<spec_merge>, C<spec_delete>), walking a
typed C<spec> through its own declared fields as readily as a plain hash
one -- built-in Kinds as well as CRDs, since 1.108 (k103). A Kind that
carries no C<spec> field at all (C<ConfigMap>, C<Secret>, the RBAC kinds,
...) has the methods too, and every one of them croaks naming the class
rather than failing on a missing accessor.

Use C<IO::K8s::Resource> for embedded objects (PodSpec, Container, etc.)
and C<IO::K8s::APIObject> for top-level resources (Pod, Deployment, Service, etc.)

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

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

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
