package IO::K8s::Cilium;
# ABSTRACT: Cilium CRD resource map provider for IO::K8s
our $VERSION = '1.008';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub resource_map {
    return {
        # cilium.io/v2
        CiliumNetworkPolicy            => 'Cilium::V2::CiliumNetworkPolicy',
        CiliumClusterwideNetworkPolicy => 'Cilium::V2::CiliumClusterwideNetworkPolicy',
        CiliumLocalRedirectPolicy      => 'Cilium::V2::CiliumLocalRedirectPolicy',
        CiliumEgressGatewayPolicy      => 'Cilium::V2::CiliumEgressGatewayPolicy',
        CiliumIdentity                 => 'Cilium::V2::CiliumIdentity',
        CiliumEndpoint                 => 'Cilium::V2::CiliumEndpoint',
        CiliumNode                     => 'Cilium::V2::CiliumNode',
        CiliumNodeConfig               => 'Cilium::V2::CiliumNodeConfig',
        CiliumLoadBalancerIPPool       => 'Cilium::V2::CiliumLoadBalancerIPPool',
        CiliumEnvoyConfig              => 'Cilium::V2::CiliumEnvoyConfig',
        CiliumClusterwideEnvoyConfig   => 'Cilium::V2::CiliumClusterwideEnvoyConfig',
        CiliumExternalWorkload         => 'Cilium::V2::CiliumExternalWorkload',
        # cilium.io/v2alpha1
        CiliumEndpointSlice            => 'Cilium::V2alpha1::CiliumEndpointSlice',
        CiliumL2AnnouncementPolicy     => 'Cilium::V2alpha1::CiliumL2AnnouncementPolicy',
        CiliumBGPPeeringPolicy         => 'Cilium::V2alpha1::CiliumBGPPeeringPolicy',
        CiliumBGPClusterConfig         => 'Cilium::V2alpha1::CiliumBGPClusterConfig',
        CiliumBGPPeerConfig            => 'Cilium::V2alpha1::CiliumBGPPeerConfig',
        CiliumBGPAdvertisement         => 'Cilium::V2alpha1::CiliumBGPAdvertisement',
        CiliumBGPNodeConfig            => 'Cilium::V2alpha1::CiliumBGPNodeConfig',
        CiliumBGPNodeConfigOverride    => 'Cilium::V2alpha1::CiliumBGPNodeConfigOverride',
        CiliumGatewayClassConfig       => 'Cilium::V2alpha1::CiliumGatewayClassConfig',
        CiliumCIDRGroup                => 'Cilium::V2alpha1::CiliumCIDRGroup',
        CiliumPodIPPool                => 'Cilium::V2alpha1::CiliumPodIPPool',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium - Cilium CRD resource map provider for IO::K8s

=head1 VERSION

version 1.008

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

    my $cnp = $k8s->new_object('CiliumNetworkPolicy',
        metadata => { name => 'allow-dns', namespace => 'kube-system' },
        spec => { endpointSelector => {} },
    );

    print $cnp->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<Cilium|https://cilium.io/> Custom Resource
Definitions. Registers 23 CRD classes covering C<cilium.io/v2> and
C<cilium.io/v2alpha1>.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::Cilium') >> at runtime.

=head2 Included CRDs (cilium.io/v2)

CiliumNetworkPolicy, CiliumClusterwideNetworkPolicy,
CiliumLocalRedirectPolicy, CiliumEgressGatewayPolicy, CiliumIdentity,
CiliumEndpoint, CiliumNode, CiliumNodeConfig, CiliumLoadBalancerIPPool,
CiliumEnvoyConfig, CiliumClusterwideEnvoyConfig, CiliumExternalWorkload

=head2 Included CRDs (cilium.io/v2alpha1)

CiliumEndpointSlice, CiliumL2AnnouncementPolicy, CiliumBGPPeeringPolicy,
CiliumBGPClusterConfig, CiliumBGPPeerConfig, CiliumBGPAdvertisement,
CiliumBGPNodeConfig, CiliumBGPNodeConfigOverride, CiliumGatewayClassConfig,
CiliumCIDRGroup, CiliumPodIPPool

=head1 SEE ALSO

L<IO::K8s>

L<Cilium documentation|https://docs.cilium.io/>

L<Cilium CRD reference|https://docs.cilium.io/en/stable/network/kubernetes/policy/>

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
