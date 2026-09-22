package IO::K8s::PrometheusOperator::V1::AlertmanagerEndpoints;
# ABSTRACT: AlertmanagerEndpoints defines a selection of a single Endpoints object containing Alertmanager IPs to fire alerts against.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s alertRelabelings     => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s apiVersion           => Str, { enum => [qw(v1 V1 v2 V2)] };
k8s authorization        => '+IO::K8s::PrometheusOperator::V1::SafeAuthorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1::BasicAuth';
k8s bearerTokenFile      => Str;
k8s enableHttp2          => Bool;
k8s name                 => Str, { required => 'schema' };
k8s namespace            => Str;
k8s noProxy              => Str;
k8s pathPrefix           => Str;
k8s port                 => IntOrStr, { required => 'schema' };
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s relabelings          => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s scheme               => Str, { enum => [qw(http https HTTP HTTPS)] };
k8s sigv4                => '+IO::K8s::PrometheusOperator::V1::Sigv4';
k8s timeout              => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1::TLSConfig';




















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AlertmanagerEndpoints - AlertmanagerEndpoints defines a selection of a single Endpoints object containing Alertmanager IPs to fire alerts against.

=head1 VERSION

version 1.108

=head2 alertRelabelings

alertRelabelings defines the relabeling configs applied before sending alerts to a specific Alertmanager.
It requires Prometheus >= v2.51.0.

=head2 apiVersion

apiVersion defines the version of the Alertmanager API that Prometheus uses to send alerts.
It can be "V1" or "V2".
The field has no effect for Prometheus >= v3.0.0 because only the v2 API is supported.

=head2 authorization

authorization section for Alertmanager.

Cannot be set at the same time as `basicAuth`, `bearerTokenFile` or `sigv4`.

=head2 basicAuth

basicAuth configuration for Alertmanager.

Cannot be set at the same time as `bearerTokenFile`, `authorization` or `sigv4`.

=head2 bearerTokenFile

bearerTokenFile defines the file to read bearer token for Alertmanager.

Cannot be set at the same time as `basicAuth`, `authorization`, or `sigv4`.

Deprecated: this will be removed in a future release. Prefer using `authorization`.

=head2 enableHttp2

enableHttp2 defines whether to enable HTTP2.

=head2 name

name of the Endpoints object in the namespace.

=head2 namespace

namespace of the Endpoints object.

If not set, the object will be discovered in the namespace of the
Prometheus object.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 pathPrefix

pathPrefix defines the prefix for the HTTP path alerts are pushed to.

=head2 port

port on which the Alertmanager API is exposed.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 relabelings

relabelings defines the relabel configuration applied to the discovered Alertmanagers.

=head2 scheme

scheme defines the HTTP scheme to use when sending alerts.

=head2 sigv4

sigv4 defines AWS's Signature Verification 4 for the URL.

It requires Prometheus >= v2.48.0.

Cannot be set at the same time as `basicAuth`, `bearerTokenFile` or `authorization`.

=head2 timeout

timeout defines a per-target Alertmanager timeout when pushing alerts.

=head2 tlsConfig

tlsConfig to use for Alertmanager.

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
