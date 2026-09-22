package IO::K8s::Traefik;
# ABSTRACT: Traefik CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v3.7.12' }  # traefik/traefik (CRD set stable across all v3.x)

# Upstream CRD manifests for the pinned upstream_version, consumed by
# maint/crd-drift-check.pl. Data only -- no fetching here. The per-Kind
# reference CRDs (one CustomResourceDefinition per file) live under
# docs/content/reference/dynamic-configuration; `base` + each `files`
# entry is the raw manifest URL, cached under spec/crd/Traefik/.
sub crd_sources {
    my $v = __PACKAGE__->upstream_version;
    return {
        status => 'ok',
        base   => "https://raw.githubusercontent.com/traefik/traefik/$v/docs/content/reference/dynamic-configuration",
        files  => [
            'traefik.io_ingressroutes.yaml',
            'traefik.io_ingressroutetcps.yaml',
            'traefik.io_ingressrouteudps.yaml',
            'traefik.io_middlewares.yaml',
            'traefik.io_middlewaretcps.yaml',
            'traefik.io_serverstransports.yaml',
            'traefik.io_serverstransporttcps.yaml',
            'traefik.io_tlsoptions.yaml',
            'traefik.io_tlsstores.yaml',
            'traefik.io_traefikservices.yaml',
        ],
    };
}

sub resource_map {
    return {
        IngressRoute        => 'Traefik::V1alpha1::IngressRoute',
        IngressRouteTCP     => 'Traefik::V1alpha1::IngressRouteTCP',
        IngressRouteUDP     => 'Traefik::V1alpha1::IngressRouteUDP',
        Middleware          => 'Traefik::V1alpha1::Middleware',
        MiddlewareTCP       => 'Traefik::V1alpha1::MiddlewareTCP',
        ServersTransport    => 'Traefik::V1alpha1::ServersTransport',
        ServersTransportTCP => 'Traefik::V1alpha1::ServersTransportTCP',
        TLSOption           => 'Traefik::V1alpha1::TLSOption',
        TLSStore            => 'Traefik::V1alpha1::TLSStore',
        TraefikService      => 'Traefik::V1alpha1::TraefikService',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik - Traefik CRD resource map provider for IO::K8s

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    my $ir = $k8s->new_object('IngressRoute',
        metadata => { name => 'my-route', namespace => 'default' },
        spec => {
            entryPoints => ['web'],
            routes => [{ match => 'Host(`example.com`)', kind => 'Rule' }],
        },
    );

    print $ir->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<Traefik|https://traefik.io/> Custom Resource
Definitions. Registers 10 CRD classes for C<traefik.io/v1alpha1>, modeled to
full depth: C<spec> (and, where upstream declares one, C<status>) is a typed
object graph of 76 further C<IO::K8s::Traefik::V1alpha1::*> classes, one per
upstream Go structure, named after the upstream Go types
(L<IO::K8s::Traefik::V1alpha1::Middleware|IO::K8s::Traefik::V1alpha1::Middleware>'s
C<rateLimit> is an C<IO::K8s::Traefik::V1alpha1::RateLimit>, and so on down)
rather than an opaque hashref. Embedded core types are referenced, not
re-modeled — a route's C<middlewares>/C<parentRefs> are
L<Core::V1::SecretReference|IO::K8s::Api::Core::V1::SecretReference>. A Go
type used by more than one Kind (C<Service>, C<Sticky>, C<Cookie>,
C<ServerHealthCheck>, C<IPStrategy>, ...) is one shared class, not a copy per
Kind.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::Traefik') >> at runtime.

=head2 Included CRDs (traefik.io/v1alpha1)

All ten Kinds are namespace-scoped.

=over 4

=item * C<IngressRoute> -- the CRD implementation of a Traefik HTTP router: matches
incoming HTTP requests against a set of routes, each attaching optional middlewares and
TLS settings.

=item * C<IngressRouteTCP> -- the CRD implementation of a Traefik TCP router: the TCP
counterpart of C<IngressRoute>.

=item * C<IngressRouteUDP> -- the CRD implementation of a Traefik UDP router: the UDP
counterpart of C<IngressRoute>.

=item * C<Middleware> -- the CRD implementation of a Traefik middleware: a reusable HTTP
request/response transformation (redirect, header rewrite, rate limiting, basic auth,
...) attached to one or more C<IngressRoute>s.

=item * C<MiddlewareTCP> -- the CRD implementation of a Traefik TCP middleware: the TCP
counterpart of C<Middleware> (e.g. C<InFlightConn>, IP allow/deny-listing), attached to
C<IngressRouteTCP> routes.

=item * C<ServersTransport> -- the CRD implementation of a ServersTransport: configures
the HTTP connection between Traefik and its backend servers (TLS trust, timeouts,
certificates).

=item * C<ServersTransportTCP> -- the CRD implementation of a TCPServersTransport: the
TCP counterpart of C<ServersTransport> (proxy protocol, TLS, timeouts for TCP backends).

=item * C<TLSOption> -- the CRD implementation of a Traefik TLS Option: configures
parameters of the TLS connection (protocol versions, cipher suites, client
authentication) on a Traefik entry point.

=item * C<TLSStore> -- the CRD implementation of a Traefik TLS Store: a store of TLS
certificates, in particular the C<default> certificate Traefik falls back to. Traefik
only ever consults the store named C<default>.

=item * C<TraefikService> -- the CRD implementation of a Traefik Service: an
abstraction layered on top of Kubernetes Services for weighted round-robin
load-balancing, mirroring, and failover across one or more backend services.

=back

=head1 SEE ALSO

L<IO::K8s>

L<Traefik documentation|https://doc.traefik.io/traefik/>

L<Traefik Kubernetes CRD reference|https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/>

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
