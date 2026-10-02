package IO::K8s::APIObject;
# ABSTRACT: Base class for top-level Kubernetes API objects
our $VERSION = '1.110';
use v5.10;
use strict;
use warnings;
use IO::K8s::Resource ();
use Import::Into;
use Package::Stash;
use Moo::Role ();
use Carp qw( croak );


# The import parameters a class may pass (see import below).
my @KNOWN_PARAMS = qw( api_version resource_plural subresources );
my %KNOWN_PARAM  = map { $_ => 1 } @KNOWN_PARAMS;

sub import {
    my ($class, @args) = @_;
    my $caller = caller;

    # Name => value pairs or nothing: an odd count (a value lost to an edit,
    # `use IO::K8s::APIObject 'api_version';`) used to leave the lone name
    # with undef behind Perl's "Odd number of elements" warning (k182).
    croak $caller.': odd number of import arguments for '.__PACKAGE__
        .' ('.scalar(@args).'); expected name => value pairs'
        if @args % 2;
    my %params = @args;

    # A misspelt parameter (subresource, resource_plurals) was ignored and
    # the class built as if it had never been written (k174). Checked
    # before anything is set up, so a refused import leaves no half-built
    # class behind; sort: several unknown keys name a deterministic one.
    for my $param (sort keys %params) {
        croak $caller.": unknown import parameter '".$param."' for ".__PACKAGE__
            .' (known: '.join(', ', @KNOWN_PARAMS).')'
            unless $KNOWN_PARAM{$param};
    }

    # api_version and resource_plural, when given, are the class's identity:
    # an empty or undef value used to fail the truth tests below and was
    # skipped without a word, leaving the api_version derived from the
    # package name or no resource_plural at all (k182). exists, not truth,
    # as for subresources; checked before anything is set up as well.
    for my $param (grep { exists $params{$_} } qw( api_version resource_plural )) {
        my $value = $params{$param};
        croak $caller.": import parameter '".$param."' for ".__PACKAGE__
            .' must be a non-empty string, got '
            .(!defined $value ? 'undef'
            : ref $value      ? 'a reference of type '.ref($value)
            :                   'an empty string')
            unless defined $value && !ref $value && length $value;
    }

    # First, do everything IO::K8s::Resource does
    IO::K8s::Resource->import::into($caller);

    # Install CRD overrides *before* applying the role
    # This way the role sees these methods and doesn't install its defaults
    if (defined(my $api_ver = $params{api_version})) {
        my $stash = Package::Stash->new($caller);
        # A fixed identity method, not a writable field: reject an argument
        # rather than swallow it (k67).
        $stash->add_symbol('&api_version', sub {
            croak 'api_version is fixed for this class and cannot be set' if @_ > 1;
            $api_ver;
        });
    }
    if (defined(my $plural = $params{resource_plural})) {
        my $stash = Package::Stash->new($caller);
        # A fixed identity method, not a writable field: reject an argument
        # rather than swallow it (k70, same shape as k67).
        $stash->add_symbol('&resource_plural', sub {
            croak 'resource_plural is fixed for this class and cannot be set' if @_ > 1;
            $plural;
        });
    }
    # exists, not truth: an empty hashref is a declaration (no subresource
    # served) and undef is a mistake the check below names (k158).
    _install_subresources($caller, _checked_subresources($caller, $params{subresources}))
        if exists $params{subresources};

    # Apply the APIObject role (provides metadata, labels, conditions,
    # owners -- and, since k103, IO::K8s::Role::SpecBuilder, which that role
    # composes for every top-level Kind rather than only for CRDs)
    Moo::Role->apply_roles_to_package($caller, 'IO::K8s::Role::APIObject');

    # Register the role's metadata attribute for the registry readers, so
    # _inflate_struct inflates metadata as ObjectMeta. Adopted, not declared:
    # the role already created the attribute, and the public k8s refuses to
    # register over an attribute it did not create itself (k144).
    IO::K8s::Resource->_k8s_adopt($caller, 'metadata', 'Meta::V1::ObjectMeta');
}

# The subresources a CRD version may serve (k158), the shape of
# apiextensions/v1 CustomResourceSubresources: status is an empty object,
# scale names where the replica counts and the label selector live.
my %SCALE_KEY = (
    specReplicasPath   => 'required',
    statusReplicasPath => 'required',
    labelSelectorPath  => 'optional',
);

# A validated, private copy of a class's subresources declaration, or a
# croak naming $class and the offending key. Shared with IO::K8s::AutoGen,
# which checks a CRD version's subresources with it before it begins the
# class, so a malformed manifest builds nothing.
sub _checked_subresources {
    my ($class, $subresources) = @_;
    my $where = $class.':';
    croak $where.' subresources must be a hashref of status and/or scale, got '
        .(defined $subresources ? ref $subresources || 'a plain scalar' : 'undef')
        unless ref $subresources eq 'HASH';
    for my $key (sort keys %$subresources) {
        croak $where." unknown subresource '".$key."' (known: scale, status)"
            unless $key eq 'status' || $key eq 'scale';
    }
    my %copy;
    if (exists $subresources->{status}) {
        my $status = $subresources->{status};
        croak $where." subresource 'status' must be an empty hashref"
            unless ref $status eq 'HASH' && !%$status;
        $copy{status} = {};
    }
    if (exists $subresources->{scale}) {
        my $scale = $subresources->{scale};
        croak $where." subresource 'scale' must be a hashref" unless ref $scale eq 'HASH';
        for my $key (sort keys %$scale) {
            croak $where." unknown key '".$key."' in subresource 'scale' (known: "
                .join(', ', sort keys %SCALE_KEY).')'
                unless $SCALE_KEY{$key};
        }
        for my $key (sort grep { $SCALE_KEY{$_} eq 'required' } keys %SCALE_KEY) {
            croak $where." subresource 'scale' needs '".$key."'" unless exists $scale->{$key};
        }
        for my $key (sort keys %$scale) {
            my $path = $scale->{$key};
            croak $where." '".$key."' in subresource 'scale' must be a non-empty string"
                unless defined $path && !ref $path && length $path;
        }
        $copy{scale} = { %$scale };
    }
    return \%copy;
}

# Install the checked declaration as the fixed identity method
# subresources, the way api_version and resource_plural are installed: an
# argument croaks (k67), and every call hands out a fresh copy, so a
# caller editing the result cannot change what the class declares.
sub _install_subresources {
    my ($class, $subresources) = @_;
    Package::Stash->new($class)->add_symbol('&subresources', sub {
        croak 'subresources is fixed for this class and cannot be set' if @_ > 1;
        return { map { $_ => { %{ $subresources->{$_} } } } keys %$subresources };
    });
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::APIObject - Base class for top-level Kubernetes API objects

=head1 VERSION

version 1.110

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

    k8s spec   => Opaque;
    k8s status => Opaque;

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
below, passing an argument croaks rather than silently rebinding.
The methods derive their value from the class name in the built-in case, so
the same guard applies -- see L<IO::K8s::Role::APIObject> for the exact
messages.

For Custom Resource Definitions (CRDs), pass C<api_version> and
optionally C<resource_plural> as import parameters. These are installed
as class methods before the role is composed, avoiding redefinition warnings.

C<api_version>, C<resource_plural> and C<subresources> (below) are the only
import parameters. Any other name -- a typo such as C<subresource> or
C<resource_plurals> -- croaks at the C<use> line before anything is set up,
naming the class, the parameter and the known ones:

    My::StaticWebSite: unknown import parameter 'subresource' for IO::K8s::APIObject (known: api_version, resource_plural, subresources)

The same goes for an odd number of import arguments, and for an
C<api_version> or C<resource_plural> given as C<undef>, as an empty string
or as a reference, which used to be skipped as if the parameter were not
there:

    My::StaticWebSite: odd number of import arguments for IO::K8s::APIObject (1); expected name => value pairs
    My::StaticWebSite: import parameter 'resource_plural' for IO::K8s::APIObject must be a non-empty string, got an empty string

A CRD class may also declare the subresources its CRD version serves,
which L<IO::K8s::Role::APIObject/to_crd> writes into
C<spec.versions[].subresources>:

    package My::StaticWebSite;
    use IO::K8s::APIObject
        api_version     => 'homelab.example.com/v1',
        resource_plural => 'staticwebsites',
        subresources    => {
            status => {},
            scale  => {
                specReplicasPath   => '.spec.replicas',
                statusReplicasPath => '.status.replicas',
                labelSelectorPath  => '.status.selector'
            }
        };

C<subresources> becomes a fixed identity class method like C<api_version>:
it returns a fresh copy of the declaration on every call, and passing an
argument croaks (C<subresources is fixed for this class and cannot be
set>). A class without the parameter has no C<subresources> method, and its
C<to_crd> writes no C<subresources> key. The declaration is checked at
C<use> time: only C<status> and C<scale> are known; C<status> is an empty
hashref; C<scale> needs C<specReplicasPath> and C<statusReplicasPath>, takes
C<labelSelectorPath> as well, and nothing else, each a non-empty string. An
empty hashref declares no subresource. Anything else croaks naming the
class and the key, for example

    My::StaticWebSite: unknown subresource 'foo' (known: scale, status)
    My::StaticWebSite: subresource 'scale' needs 'statusReplicasPath'

A class L<IO::K8s/add_crd> generates from a CRD version with
C<subresources> gets the same method, and L<IO::K8s::CRD::Emitter> renders
it as this parameter.

Every class built this way gets L<IO::K8s::Role::SpecBuilder> for
deep-path spec manipulation (C<spec_get>, C<spec_set>, C<spec_array>,
C<spec_hash>, C<spec_push>, C<spec_merge>, C<spec_delete>), walking a
typed C<spec> through its own declared fields as readily as a plain hash
one -- built-in Kinds as well as CRDs, since 1.108. A Kind that
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
