package IO::K8s::APIObject;
# ABSTRACT: Base class for top-level Kubernetes API objects
our $VERSION = '1.009';
use v5.10;
use IO::K8s::Resource ();
use Import::Into;
use Package::Stash;
use Moo::Role ();


sub import {
    my $class = shift;
    my %params = @_;
    my $caller = caller;

    # First, do everything IO::K8s::Resource does
    IO::K8s::Resource->import::into($caller);

    # Install CRD overrides *before* applying the role
    # This way the role sees these methods and doesn't install its defaults
    my $is_crd = 0;
    if (my $api_ver = $params{api_version}) {
        my $stash = Package::Stash->new($caller);
        $stash->add_symbol('&api_version', sub { $api_ver });
        $is_crd = 1;
    }
    if (my $plural = $params{resource_plural}) {
        my $stash = Package::Stash->new($caller);
        $stash->add_symbol('&resource_plural', sub { $plural });
    }

    # Apply the APIObject role (provides metadata, labels, conditions, owners)
    Moo::Role->apply_roles_to_package($caller, 'IO::K8s::Role::APIObject');

    # CRDs get SpecBuilder automatically (deep-path spec manipulation)
    if ($is_crd) {
        Moo::Role->apply_roles_to_package($caller, 'IO::K8s::Role::SpecBuilder');
    }

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

version 1.009

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

=item * C<resource_plural()> method (returns undef = auto-pluralize)

=item * Label, annotation, condition, and owner convenience methods

=back

For Custom Resource Definitions (CRDs), pass C<api_version> and
optionally C<resource_plural> as import parameters. These are installed
as class methods before the role is composed, avoiding redefinition warnings.
CRD classes also get L<IO::K8s::Role::SpecBuilder> applied automatically
for deep-path spec manipulation (C<spec_get>, C<spec_set>, C<spec_push>,
C<spec_merge>, C<spec_delete>).

Use C<IO::K8s::Resource> for embedded objects (PodSpec, Container, etc.)
and C<IO::K8s::APIObject> for top-level resources (Pod, Deployment, Service, etc.)

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
