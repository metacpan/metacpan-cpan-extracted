package IO::K8s::Cilium::V2alpha1::CiliumBGPPeerConfigSpec;
# ABSTRACT: Spec is the specification of the desired behavior of the CiliumBGPPeerConfig.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authSecretRef   => Str;
k8s ebgpMultihop    => Int, { minimum => 1, maximum => 255, default => 1 };
k8s families        => ['+IO::K8s::Cilium::V2alpha1::CiliumBGPFamilyWithAdverts'];
k8s gracefulRestart => '+IO::K8s::Cilium::V2alpha1::CiliumBGPNeighborGracefulRestart';
k8s timers          => '+IO::K8s::Cilium::V2alpha1::CiliumBGPTimers';
k8s transport       => '+IO::K8s::Cilium::V2alpha1::CiliumBGPTransport';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumBGPPeerConfigSpec - Spec is the specification of the desired behavior of the CiliumBGPPeerConfig.

=head1 VERSION

version 1.108

=head2 authSecretRef

AuthSecretRef is the name of the secret to use to fetch a TCP
authentication password for this peer.

If not specified, no authentication is used.

=head2 ebgpMultihop

EBGPMultihopTTL controls the multi-hop feature for eBGP peers.
Its value defines the Time To Live (TTL) value used in BGP
packets sent to the peer.

If not specified, EBGP multihop is disabled. This field is ignored for iBGP neighbors.

=head2 families

Families, if provided, defines a set of AFI/SAFIs the speaker will
negotiate with it's peer.

If not specified, the default families of IPv6/unicast and IPv4/unicast will be created.

=head2 gracefulRestart

GracefulRestart defines graceful restart parameters which are negotiated
with this peer.

If not specified, the graceful restart capability is disabled.

=head2 timers

Timers defines the BGP timers for the peer.

If not specified, the default timers are used.

=head2 transport

Transport defines the BGP transport parameters for the peer.

If not specified, the default transport parameters are used.

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
