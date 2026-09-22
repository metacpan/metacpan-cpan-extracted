package IO::K8s::PrometheusOperator::V1::HTTPConfigWithProxy;
# ABSTRACT: httpConfig defines the default HTTP configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorization        => '+IO::K8s::PrometheusOperator::V1::SafeAuthorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1::BasicAuth';
k8s bearerTokenSecret    => 'Core::V1::ConfigMapKeySelector';
k8s enableHttp2          => Bool;
k8s followRedirects      => Bool;
k8s noProxy              => Str;
k8s oauth2               => '+IO::K8s::PrometheusOperator::V1::OAuth2';
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1::SafeTLSConfig';












1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::HTTPConfigWithProxy - httpConfig defines the default HTTP configuration.

=head1 VERSION

version 1.108

=head2 authorization

authorization configures the Authorization header credentials used by
the client.

Cannot be set at the same time as `basicAuth`, `bearerTokenSecret` or `oauth2`.

=head2 basicAuth

basicAuth defines the Basic Authentication credentials used by the
client.

Cannot be set at the same time as `authorization`, `bearerTokenSecret` or `oauth2`.

=head2 bearerTokenSecret

bearerTokenSecret defines a key of a Secret containing the bearer token
used by the client for authentication. The secret needs to be in the
same namespace as the custom resource and readable by the Prometheus
Operator.

Cannot be set at the same time as `authorization`, `basicAuth` or `oauth2`.

Deprecated: use `authorization` instead.

=head2 enableHttp2

enableHttp2 can be used to disable HTTP2.

=head2 followRedirects

followRedirects defines whether the client should follow HTTP 3xx
redirects.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 oauth2

oauth2 defines the OAuth2 settings used by the client.

It requires Prometheus >= 2.27.0.

Cannot be set at the same time as `authorization`, `basicAuth` or `bearerTokenSecret`.

=head2 proxyConnectHeader

proxyConnectHeader optionally specifies headers to send to
proxies during CONNECT requests.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyFromEnvironment

proxyFromEnvironment defines whether to use the proxy configuration defined by environment variables (HTTP_PROXY, HTTPS_PROXY, and NO_PROXY).

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

=head2 proxyUrl

proxyUrl defines the HTTP proxy server to use.

=head2 tlsConfig

tlsConfig defines the TLS configuration used by the client.

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
