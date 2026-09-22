package IO::K8s::PrometheusOperator::V1::APIServerConfig;
# ABSTRACT: apiserverConfig allows specifying a host and auth methods to access the Kuberntees API server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authorization        => '+IO::K8s::PrometheusOperator::V1::Authorization';
k8s basicAuth            => '+IO::K8s::PrometheusOperator::V1::BasicAuth';
k8s bearerToken          => Str;
k8s bearerTokenFile      => Str;
k8s host                 => Str, { required => 'schema' };
k8s noProxy              => Str;
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1::TLSConfig';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::APIServerConfig - apiserverConfig allows specifying a host and auth methods to access the Kuberntees API server.

=head1 VERSION

version 1.108

=head2 authorization

authorization section for the API server.

Cannot be set at the same time as `basicAuth`, `bearerToken`, or
`bearerTokenFile`.

=head2 basicAuth

basicAuth configuration for the API server.

Cannot be set at the same time as `authorization`, `bearerToken`, or
`bearerTokenFile`.

=head2 bearerToken

bearerToken is deprecated: this will be removed in a future release.
 *Warning: this field shouldn't be used because the token value appears
in clear-text. Prefer using `authorization`.*

=head2 bearerTokenFile

bearerTokenFile defines the file to read bearer token for accessing apiserver.

Cannot be set at the same time as `basicAuth`, `authorization`, or `bearerToken`.

Deprecated: this will be removed in a future release. Prefer using `authorization`.

=head2 host

host defines the Kubernetes API address consisting of a hostname or IP address followed
by an optional port number.

=head2 noProxy

noProxy defines a comma-separated string that can contain IPs, CIDR notation, domain names
that should be excluded from proxying. IP and domain names can
contain port numbers.

It requires Prometheus >= v2.43.0, Alertmanager >= v0.25.0 or Thanos >= v0.32.0.

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

tlsConfig to use for the API server.

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
