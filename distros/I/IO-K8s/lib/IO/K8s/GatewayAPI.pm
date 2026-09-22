package IO::K8s::GatewayAPI;
# ABSTRACT: Gateway API CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v1.6.1' }  # kubernetes-sigs/gateway-api (GA/Standard channel only)

# Upstream CRD manifests for the pinned upstream_version, consumed by
# maint/crd-drift-check.pl. Data only -- no fetching here. GA/Standard
# channel only (config/crd/standard), matching this provider's scope; the
# experimental channel is deliberately not tracked. `base` + each `files`
# entry is the raw manifest URL, cached under spec/crd/GatewayAPI/.
sub crd_sources {
    my $v = __PACKAGE__->upstream_version;
    return {
        status => 'ok',
        base   => "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/$v/config/crd/standard",
        files  => [
            'gateway.networking.k8s.io_backendtlspolicies.yaml',
            'gateway.networking.k8s.io_gatewayclasses.yaml',
            'gateway.networking.k8s.io_gateways.yaml',
            'gateway.networking.k8s.io_grpcroutes.yaml',
            'gateway.networking.k8s.io_httproutes.yaml',
            'gateway.networking.k8s.io_listenersets.yaml',
            'gateway.networking.k8s.io_referencegrants.yaml',
            'gateway.networking.k8s.io_tcproutes.yaml',
            'gateway.networking.k8s.io_tlsroutes.yaml',
            'gateway.networking.k8s.io_udproutes.yaml',
        ],
    };
}

sub resource_map {
    return {
        # gateway.networking.k8s.io/v1 -- the storage version of every Kind
        # except ReferenceGrant; short names resolve here (D7).
        GatewayClass     => 'GatewayAPI::V1::GatewayClass',
        Gateway          => 'GatewayAPI::V1::Gateway',
        HTTPRoute        => 'GatewayAPI::V1::HTTPRoute',
        GRPCRoute        => 'GatewayAPI::V1::GRPCRoute',
        BackendTLSPolicy => 'GatewayAPI::V1::BackendTLSPolicy',
        ListenerSet      => 'GatewayAPI::V1::ListenerSet',
        TLSRoute         => 'GatewayAPI::V1::TLSRoute',
        TCPRoute         => 'GatewayAPI::V1::TCPRoute',
        UDPRoute         => 'GatewayAPI::V1::UDPRoute',
        # ReferenceGrant is served at both v1 and v1beta1 as of v1.5.0; v1beta1
        # remains the storage version as of v1.6.1, so it keeps the short name.
        # The v1 class is reachable via its domain-qualified key below.
        'gateway.networking.k8s.io/v1/ReferenceGrant' => 'GatewayAPI::V1::ReferenceGrant',

        # gateway.networking.k8s.io/v1beta1 -- Gateway, GatewayClass and
        # HTTPRoute are also served here (served: true, storage: false in
        # the upstream CRD manifest at v1.6.1): older, deprecated tracks of
        # Kinds whose storage version is v1 (D7 -- every served version gets
        # a class). Reachable only by their domain-qualified keys, since the
        # short name resolves to each Kind's storage version above.
        ReferenceGrant   => 'GatewayAPI::V1beta1::ReferenceGrant',
        'gateway.networking.k8s.io/v1beta1/Gateway'      => 'GatewayAPI::V1beta1::Gateway',
        'gateway.networking.k8s.io/v1beta1/GatewayClass' => 'GatewayAPI::V1beta1::GatewayClass',
        'gateway.networking.k8s.io/v1beta1/HTTPRoute'    => 'GatewayAPI::V1beta1::HTTPRoute',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI - Gateway API CRD resource map provider for IO::K8s

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    my $gw = $k8s->new_object('Gateway',
        metadata => { name => 'my-gateway', namespace => 'default' },
        spec => {
            gatewayClassName => 'istio',
            listeners => [{ name => 'http', port => 80, protocol => 'HTTP' }],
        },
    );

    print $gw->to_yaml;

=head1 DESCRIPTION

Resource map provider for the L<Kubernetes Gateway API|https://gateway-api.sigs.k8s.io/>
Custom Resource Definitions, modeled to full depth (D5/D6): C<spec> and
C<status> are typed field-by-field, nested classes carry their upstream Go
type names, and embedded core types (C<LabelSelector>-shaped structs, ...)
are referenced rather than re-modeled. 143 classes across 14 GVKs: 10 Kinds
at C<gateway.networking.k8s.io/v1> (GA/Standard channel) and, per D7, every
Kind upstream also serves at C<gateway.networking.k8s.io/v1beta1> --
Gateway, GatewayClass, HTTPRoute and ReferenceGrant.

The Gateway API is an official Kubernetes SIG-Network project that provides
expressive, extensible, and role-oriented interfaces for service networking.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::GatewayAPI') >> at runtime.

=head2 Included CRDs (gateway.networking.k8s.io/v1)

These are the storage version of every Kind except C<ReferenceGrant>, so every short
name except C<ReferenceGrant> resolves here.

=over 4

=item * C<GatewayClass> (cluster-scoped) -- describes a class of Gateways available to
the user for creating C<Gateway> resources, provided by the infrastructure/controller
(the Gateway API counterpart of Kubernetes' C<IngressClass>).

=item * C<Gateway> (namespaced) -- represents an instance of service-traffic handling
infrastructure by binding Listeners to a set of IP addresses; creating one triggers its
C<GatewayClass>'s controller to provision or reconfigure the underlying load balancer.

=item * C<HTTPRoute> (namespaced) -- provides a way to route HTTP requests from a
C<Gateway> listener to backend Services.

=item * C<GRPCRoute> (namespaced) -- provides a way to route gRPC requests; the gRPC
counterpart of C<HTTPRoute>.

=item * C<BackendTLSPolicy> (namespaced) -- provides a way to configure how a
C<Gateway> connects to a backend via TLS (client-side backend TLS, as opposed to a
Listener's own server-side TLS).

=item * C<ListenerSet> (namespaced) -- defines a set of additional listeners to attach
to an existing C<Gateway>, letting a delegated team add listeners without editing the
C<Gateway> itself.

=item * C<TLSRoute> (namespaced) -- similar to C<TCPRoute>, but matches against
TLS-specific metadata (SNI) without terminating TLS.

=item * C<TCPRoute> (namespaced) -- provides a way to route TCP requests from a
C<Gateway> listener to backend Services.

=item * C<UDPRoute> (namespaced) -- provides a way to route UDP traffic from a
C<Gateway> listener to backend Services.

=item * C<ReferenceGrant> (namespaced; reachable only via the domain-qualified name
C<gateway.networking.k8s.io/v1/ReferenceGrant> since the short name C<ReferenceGrant>
resolves to the v1beta1 storage version) -- identifies kinds of resources in other
namespaces that are trusted to reference the specified kinds of resources in the same
namespace as the policy: the opt-in that makes cross-namespace backend references safe
by default.

=back

=head2 Included CRDs (gateway.networking.k8s.io/v1beta1)

C<ReferenceGrant> (namespaced) is the storage version here, so the short name
C<ReferenceGrant> resolves to this class -- same purpose as described above.
C<Gateway>, C<GatewayClass> and C<HTTPRoute> (namespaced) are also served at v1beta1
upstream but v1 is their storage version, so these three are reachable only via their
domain-qualified names (C<gateway.networking.k8s.io/v1beta1/Gateway>,
C<gateway.networking.k8s.io/v1beta1/GatewayClass>,
C<gateway.networking.k8s.io/v1beta1/HTTPRoute>) -- again, same purpose as their v1
counterparts above.

=head1 SEE ALSO

L<IO::K8s>

L<Gateway API documentation|https://gateway-api.sigs.k8s.io/>

L<Gateway API reference|https://gateway-api.sigs.k8s.io/reference/spec/>

L<GatewayClass|https://gateway-api.sigs.k8s.io/api-types/gatewayclass/>

L<HTTPRoute|https://gateway-api.sigs.k8s.io/api-types/httproute/>

L<BackendTLSPolicy|https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/>

L<ListenerSet|https://gateway-api.sigs.k8s.io/api-types/listenerset/>

L<TLSRoute|https://gateway-api.sigs.k8s.io/api-types/tlsroute/>

L<TCPRoute|https://gateway-api.sigs.k8s.io/api-types/tcproute/>

L<UDPRoute|https://gateway-api.sigs.k8s.io/api-types/udproute/>

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
