package IO::K8s::Traefik::V1alpha1::Service;
# ABSTRACT: Service defines an upstream HTTP service to proxy traffic to.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s healthCheck        => '+IO::K8s::Traefik::V1alpha1::ServerHealthCheck';
k8s kind               => Str, { enum => [qw(Service TraefikService)] };
k8s middlewares        => ['Core::V1::SecretReference'];
k8s name               => Str, { required => 'schema' };
k8s namespace          => Str;
k8s nativeLB           => Bool;
k8s nodePortLB         => Bool;
k8s passHostHeader     => Bool;
k8s passiveHealthCheck => '+IO::K8s::Traefik::V1alpha1::PassiveServerHealthCheck';
k8s port               => IntOrStr;
k8s responseForwarding => '+IO::K8s::Traefik::V1alpha1::ResponseForwarding';
k8s scheme             => Str;
k8s serversTransport   => Str;
k8s sticky             => '+IO::K8s::Traefik::V1alpha1::Sticky';
k8s strategy           => Str, { enum => [qw(wrr p2c hrw leasttime RoundRobin)] };
k8s weight             => Int, { minimum => 0 };

















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Service - Service defines an upstream HTTP service to proxy traffic to.

=head1 VERSION

version 1.108

=head2 healthCheck

Healthcheck defines health checks for ExternalName services.

=head2 kind

Kind defines the kind of the Service.

=head2 middlewares

Middlewares defines the list of references to Middleware resources to apply to the service.

=head2 name

Name defines the name of the referenced Kubernetes Service or TraefikService.
The differentiation between the two is specified in the Kind field.

=head2 namespace

Namespace defines the namespace of the referenced Kubernetes Service or TraefikService.

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

=head2 passHostHeader

PassHostHeader defines whether the client Host header is forwarded to the upstream Kubernetes Service.
By default, passHostHeader is true.

=head2 passiveHealthCheck

PassiveHealthCheck defines passive health checks for ExternalName services.

=head2 port

Port defines the port of a Kubernetes Service.
This can be a reference to a named port.

=head2 responseForwarding

ResponseForwarding defines how Traefik forwards the response from the upstream Kubernetes Service to the client.

=head2 scheme

Scheme defines the scheme to use for the request to the upstream Kubernetes Service.
It defaults to https when Kubernetes Service port is 443, http otherwise.

=head2 serversTransport

ServersTransport defines the name of ServersTransport resource to use.
It allows to configure the transport between Traefik and your servers.
Can only be used on a Kubernetes Service.

=head2 sticky

Sticky defines the sticky sessions configuration.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/load-balancing/service/#sticky-sessions

=head2 strategy

Strategy defines the load balancing strategy between the servers.
Supported values are: wrr (Weighed round-robin), p2c (Power of two choices), hrw (Highest Random Weight), and leasttime (Least-Time).
RoundRobin value is deprecated and supported for backward compatibility.

=head2 weight

Weight defines the weight and should only be specified when Name references a TraefikService object
(and to be precise, one that embeds a Weighted Round Robin).

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
