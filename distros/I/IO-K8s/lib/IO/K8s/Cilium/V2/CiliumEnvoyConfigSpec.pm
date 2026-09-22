package IO::K8s::Cilium::V2::CiliumEnvoyConfigSpec;
# ABSTRACT: CiliumEnvoyConfigSpec
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backendServices => ['+IO::K8s::Cilium::V2::EnvoyConfigService'];
k8s nodeSelector    => 'Meta::V1::LabelSelector';
k8s resources       => [ {} ], { required => 'schema' };
k8s services        => ['+IO::K8s::Cilium::V2::ServiceListener'];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumEnvoyConfigSpec - CiliumEnvoyConfigSpec

=head1 VERSION

version 1.108

=head2 backendServices

BackendServices specifies Kubernetes services whose backends
are automatically synced to Envoy using EDS.  Traffic for these
services is not forwarded to an Envoy listener. This allows an
Envoy listener load balance traffic to these backends while
normal Cilium service load balancing takes care of balancing
traffic for these services at the same time.

=head2 nodeSelector

NodeSelector is a label selector that determines to which nodes
this configuration applies.
If nil, then this config applies to all nodes.

=head2 resources

Envoy xDS resources, a list of the following Envoy resource types:
type.googleapis.com/envoy.config.listener.v3.Listener,
type.googleapis.com/envoy.config.route.v3.RouteConfiguration,
type.googleapis.com/envoy.config.cluster.v3.Cluster,
type.googleapis.com/envoy.config.endpoint.v3.ClusterLoadAssignment, and
type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.Secret.

=head2 services

Services specifies Kubernetes services for which traffic is
forwarded to an Envoy listener for L7 load balancing. Backends
of these services are automatically synced to Envoy usign EDS.

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
