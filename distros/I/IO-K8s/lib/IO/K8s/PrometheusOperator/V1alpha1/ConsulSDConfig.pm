package IO::K8s::PrometheusOperator::V1alpha1::ConsulSDConfig;
# ABSTRACT: ConsulSDConfig defines a Consul service discovery configuration See https://prometheus.io/docs/prometheus/latest/configuration/configuration/#consul_sd_config
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowStale           => Bool;
k8s authorization        => '+IO::K8s::PrometheusOperator::V1alpha1::SafeAuthorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1alpha1::BasicAuth';
k8s datacenter           => Str;
k8s enableHTTP2          => Bool;
k8s filter               => Str;
k8s followRedirects      => Bool;
k8s healthFilter         => Str;
k8s namespace            => Str;
k8s noProxy              => Str;
k8s nodeMeta             => { Str => 1 };
k8s oauth2               => '+IO::K8s::PrometheusOperator::V1alpha1::OAuth2';
k8s partition            => Str;
k8s pathPrefix           => Str;
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s refreshInterval      => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s scheme               => Str, { enum => [qw(http https HTTP HTTPS)] };
k8s server               => Str, { required => 'schema' };
k8s services             => [Str];
k8s tagSeparator         => Str;
k8s tags                 => [Str];
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig';
k8s tokenRef             => 'Core::V1::ConfigMapKeySelector';


























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::ConsulSDConfig - ConsulSDConfig defines a Consul service discovery configuration See https://prometheus.io/docs/prometheus/latest/configuration/configuration/#consul_sd_config

=head1 VERSION

version 1.108

=head2 allowStale

allowStale Consul results (see https://www.consul.io/api/features/consistency.html). Will reduce load on Consul.
If unset, Prometheus uses its default value.

=head2 authorization

authorization defines the header configuration to authenticate against the Consul Server.
Cannot be set at the same time as `basicAuth`, or `oauth2`.

=head2 basicAuth

basicAuth defines the information to authenticate against the Consul Server.
More info: https://prometheus.io/docs/operating/configuration/#endpoints
Cannot be set at the same time as `authorization`, or `oauth2`.

=head2 datacenter

datacenter defines the consul Datacenter name, if not provided it will use the local Consul Agent Datacenter.

=head2 enableHTTP2

enableHTTP2 defines whether to enable HTTP2.

=head2 filter

filter defines the filter expression used to filter the catalog results.
See https://developer.hashicorp.com/consul/api-docs/catalog#filtering
It requires Prometheus >= 3.0.0.

=head2 followRedirects

followRedirects defines whether HTTP requests follow HTTP 3xx redirects.

=head2 healthFilter

healthFilter defines the filter expression used to filter the health results.
See https://developer.hashicorp.com/consul/api-docs/health#filtering
It requires Prometheus >= 3.11.2.

=head2 namespace

namespace are only supported in Consul Enterprise.

It requires Prometheus >= 2.28.0.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 nodeMeta

nodeMeta defines the node metadata key/value pairs to filter nodes for a given service.
Starting with Consul 1.14, it is recommended to use `filter` with the `NodeMeta` selector instead.

=head2 oauth2

oauth2 defines the optional OAuth 2.0 configuration to authenticate against the target HTTP endpoint.
Cannot be set at the same time as `authorization`, or `basicAuth`.

=head2 partition

partition defines the admin Partitions are only supported in Consul Enterprise.

=head2 pathPrefix

pathPrefix defines the prefix for URIs for when consul is behind an API gateway (reverse proxy).

It requires Prometheus >= 2.45.0.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

=head2 scheme

scheme defines the HTTP Scheme.

=head2 server

server defines the consul server address. A valid string consisting of a hostname or IP followed by an optional port number.

=head2 services

services defines a list of services for which targets are retrieved. If omitted, all services are scraped.

=head2 tagSeparator

tagSeparator defines the string by which Consul tags are joined into the tag label.
If unset, Prometheus uses its default value.

=head2 tags

tags defines an optional list of tags used to filter nodes for a given service. Services must contain all tags in the list.
Starting with Consul 1.14, it is recommended to use `filter` with the `ServiceTags` selector instead.

=head2 tlsConfig

tlsConfig defines the TLS configuration to connect to the Consul API.

=head2 tokenRef

tokenRef defines the consul ACL TokenRef, if not provided it will use the ACL from the local Consul Agent.

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
