package IO::K8s::PrometheusOperator::V1::RemoteReadSpec;
# ABSTRACT: RemoteReadSpec defines the configuration for Prometheus to read back samples from a remote endpoint.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorization        => '+IO::K8s::PrometheusOperator::V1::Authorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1::BasicAuth';
k8s bearerToken          => Str;
k8s bearerTokenFile      => Str;
k8s filterExternalLabels => Bool;
k8s followRedirects      => Bool;
k8s headers              => { Str => 1 };
k8s name                 => Str;
k8s noProxy              => Str;
k8s oauth2               => '+IO::K8s::PrometheusOperator::V1::OAuth2';
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s readRecent           => Bool;
k8s remoteTimeout        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s requiredMatchers     => { Str => 1 };
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1::TLSConfig';
k8s url                  => Str, { required => 'schema', pattern => qr/^(http|https):\/\/.+$/ };



















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::RemoteReadSpec - RemoteReadSpec defines the configuration for Prometheus to read back samples from a remote endpoint.

=head1 VERSION

version 1.108

=head2 authorization

authorization section for the URL.

It requires Prometheus >= v2.26.0.

Cannot be set at the same time as `basicAuth`, or `oauth2`.

=head2 basicAuth

basicAuth configuration for the URL.

Cannot be set at the same time as `authorization`, or `oauth2`.

=head2 bearerToken

bearerToken is deprecated: this will be removed in a future release.
*Warning: this field shouldn't be used because the token value appears
in clear-text. Prefer using `authorization`.*

=head2 bearerTokenFile

bearerTokenFile defines the file from which to read the bearer token for the URL.

Deprecated: this will be removed in a future release. Prefer using `authorization`.

=head2 filterExternalLabels

filterExternalLabels defines whether to use the external labels as selectors for the remote read endpoint.

It requires Prometheus >= v2.34.0.

=head2 followRedirects

followRedirects defines whether HTTP requests follow HTTP 3xx redirects.

It requires Prometheus >= v2.26.0.

=head2 headers

headers defines the custom HTTP headers to be sent along with each remote read request.
Be aware that headers that are set by Prometheus itself can't be overwritten.
Only valid in Prometheus versions 2.26.0 and newer.

=head2 name

name of the remote read queue, it must be unique if specified. The
name is used in metrics and logging in order to differentiate read
configurations.

It requires Prometheus >= v2.15.0.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 oauth2

oauth2 configuration for the URL.

It requires Prometheus >= v2.27.0.

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

=head2 readRecent

readRecent defines whether reads should be made for queries for time ranges that
the local storage should have complete data for.

=head2 remoteTimeout

remoteTimeout defines the timeout for requests to the remote read endpoint.

=head2 requiredMatchers

requiredMatchers defines an optional list of equality matchers which have to be present
in a selector to query the remote read endpoint.

=head2 tlsConfig

tlsConfig to use for the URL.

=head2 url

url defines the URL of the endpoint to query from.

It must use the HTTP or HTTPS scheme.

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
