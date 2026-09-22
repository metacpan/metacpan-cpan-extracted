package IO::K8s::PrometheusOperator::V1alpha1::KubernetesSDConfig;
# ABSTRACT: KubernetesSDConfig allows retrieving scrape targets from Kubernetes' REST API.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiServer            => Str;
k8s attachMetadata       => '+IO::K8s::PrometheusOperator::V1alpha1::AttachMetadata';
k8s authorization        => '+IO::K8s::PrometheusOperator::V1alpha1::SafeAuthorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1alpha1::BasicAuth';
k8s enableHTTP2          => Bool;
k8s followRedirects      => Bool;
k8s namespaces           => '+IO::K8s::PrometheusOperator::V1alpha1::NamespaceDiscovery';
k8s noProxy              => Str;
k8s oauth2               => '+IO::K8s::PrometheusOperator::V1alpha1::OAuth2';
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s role                 => Str, { required => 'schema', enum => [qw(Pod Endpoints Ingress Service Node EndpointSlice)] };
k8s selectors            => ['+IO::K8s::PrometheusOperator::V1alpha1::K8SSelectorConfig'];
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig';
















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::KubernetesSDConfig - KubernetesSDConfig allows retrieving scrape targets from Kubernetes' REST API.

=head1 VERSION

version 1.108

=head2 apiServer

apiServer defines the API server address consisting of a hostname or IP address followed
by an optional port number.
If left empty, Prometheus is assumed to run inside
of the cluster. It will discover API servers automatically and use the pod's
CA certificate and bearer token file at /var/run/secrets/kubernetes.io/serviceaccount/.

=head2 attachMetadata

attachMetadata defines the metadata to attach to discovered targets.
It requires Prometheus >= v2.35.0 when using the `Pod` role and
Prometheus >= v2.37.0 for `Endpoints` and `Endpointslice` roles.

=head2 authorization

authorization defines the authorization header to use on every scrape request.
Cannot be set at the same time as `basicAuth`, or `oauth2`.

=head2 basicAuth

basicAuth defines information to use on every scrape request.
Cannot be set at the same time as `authorization`, or `oauth2`.

=head2 enableHTTP2

enableHTTP2 defines whether to enable HTTP2.

=head2 followRedirects

followRedirects defines whether HTTP requests follow HTTP 3xx redirects.

=head2 namespaces

namespaces defines the namespace discovery. If omitted, Prometheus discovers targets across all namespaces.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 oauth2

oauth2 defines the optional OAuth 2.0 configuration to authenticate against the target HTTP endpoint.
Cannot be set at the same time as `authorization`, or `basicAuth`.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 role

role defines the Kubernetes role of the entities that should be discovered.
Role `Endpointslice` requires Prometheus >= v2.21.0

=head2 selectors

selectors defines the selector to select objects.
It requires Prometheus >= v2.17.0

=head2 tlsConfig

tlsConfig defines the TLS configuration to connect to the Kubernetes API.

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
