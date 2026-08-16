package IO::K8s::GatewayAPI;
# ABSTRACT: Gateway API CRD resource map provider for IO::K8s
our $VERSION = '1.107';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v1.6.1' }  # kubernetes-sigs/gateway-api (GA/Standard channel only)

sub resource_map {
    return {
        # gateway.networking.k8s.io/v1
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
        # gateway.networking.k8s.io/v1beta1
        ReferenceGrant   => 'GatewayAPI::V1beta1::ReferenceGrant',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI - Gateway API CRD resource map provider for IO::K8s

=head1 VERSION

version 1.107

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
Custom Resource Definitions. Registers 11 CRD classes covering
C<gateway.networking.k8s.io/v1> (GA/Standard channel) and
C<gateway.networking.k8s.io/v1beta1> (still the storage version for
ReferenceGrant).

The Gateway API is an official Kubernetes SIG-Network project that provides
expressive, extensible, and role-oriented interfaces for service networking.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::GatewayAPI') >> at runtime.

=head2 Included CRDs (gateway.networking.k8s.io/v1)

GatewayClass (cluster-scoped), Gateway (namespaced), HTTPRoute (namespaced),
GRPCRoute (namespaced), BackendTLSPolicy (namespaced), ListenerSet
(namespaced), TLSRoute (namespaced), TCPRoute (namespaced), UDPRoute
(namespaced), ReferenceGrant (namespaced; reachable only via the
domain-qualified name C<gateway.networking.k8s.io/v1/ReferenceGrant> since
the short name C<ReferenceGrant> resolves to the v1beta1 storage version)

=head2 Included CRDs (gateway.networking.k8s.io/v1beta1)

ReferenceGrant (namespaced) - the storage version; the short name
C<ReferenceGrant> resolves here

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
