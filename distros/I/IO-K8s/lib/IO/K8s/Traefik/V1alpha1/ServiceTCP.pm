package IO::K8s::Traefik::V1alpha1::ServiceTCP;
# ABSTRACT: ServiceTCP defines an upstream TCP service to proxy traffic to.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name             => Str, { required => 'schema' };
k8s namespace        => Str;
k8s nativeLB         => Bool;
k8s nodePortLB       => Bool;
k8s port             => IntOrStr, { required => 'schema' };
k8s proxyProtocol    => '+IO::K8s::Traefik::V1alpha1::ProxyProtocol';
k8s serversTransport => Str;
k8s terminationDelay => Int;
k8s tls              => Bool;
k8s weight           => Int, { minimum => 0 };











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ServiceTCP - ServiceTCP defines an upstream TCP service to proxy traffic to.

=head1 VERSION

version 1.108

=head2 name

Name defines the name of the referenced Kubernetes Service.

=head2 namespace

Namespace defines the namespace of the referenced Kubernetes Service.

=head2 nativeLB

NativeLB controls, when creating the load-balancer,
whether the LB's children are directly the pods IPs or if the only child is the Kubernetes Service clusterIP.
The Kubernetes Service itself does load-balance to the pods.
By default, NativeLB is false.

=head2 nodePortLB

NodePortLB controls, when creating the load-balancer,
whether the LB's children are directly the nodes internal IPs using the nodePort when the service type is NodePort.
It allows services to be reachable when Traefik runs externally from the Kubernetes cluster but within the same network of the nodes.
By default, NodePortLB is false.

=head2 port

Port defines the port of a Kubernetes Service.
This can be a reference to a named port.

=head2 proxyProtocol

ProxyProtocol defines the PROXY protocol configuration.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/tcp/service/#proxy-protocol

Deprecated: ProxyProtocol will not be supported in future APIVersions, please use ServersTransport to configure ProxyProtocol instead.

=head2 serversTransport

ServersTransport defines the name of ServersTransportTCP resource to use.
It allows to configure the transport between Traefik and your servers.
Can only be used on a Kubernetes Service.

=head2 terminationDelay

TerminationDelay defines the deadline that the proxy sets, after one of its connected peers indicates
it has closed the writing capability of its connection, to close the reading capability as well,
hence fully terminating the connection.
It is a duration in milliseconds, defaulting to 100.
A negative value means an infinite deadline (i.e. the reading capability is never closed).

Deprecated: TerminationDelay will not be supported in future APIVersions, please use ServersTransport to configure the TerminationDelay instead.

=head2 tls

TLS determines whether to use TLS when dialing with the backend.

=head2 weight

Weight defines the weight used when balancing requests between multiple Kubernetes Service.

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
