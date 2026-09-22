package IO::K8s::PrometheusOperator::V1::OAuth2;
# ABSTRACT: oauth2 defines the OAuth2 settings used by the client.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientId             => '+IO::K8s::PrometheusOperator::V1::SecretOrConfigMap', { required => 'schema' };
k8s clientSecret         => 'Core::V1::ConfigMapKeySelector', { required => 'schema' };
k8s endpointParams       => { Str => 1 };
k8s noProxy              => Str;
k8s proxyConnectHeader   => { Str => 1 };
k8s proxyFromEnvironment => Bool;
k8s proxyUrl             => Str, { pattern => qr/^(http|https|socks5):\/\/.+$/ };
k8s scopes               => [Str];
k8s tlsConfig            => '+IO::K8s::PrometheusOperator::V1::SafeTLSConfig';
k8s tokenUrl             => Str, { required => 'schema', pattern => qr/^(http|https):\/\/.+$/ };











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::OAuth2 - oauth2 defines the OAuth2 settings used by the client.

=head1 VERSION

version 1.108

=head2 clientId

clientId defines a key of a Secret or ConfigMap containing the
OAuth2 client's ID.

=head2 clientSecret

clientSecret defines a key of a Secret containing the OAuth2
client's secret.

=head2 endpointParams

endpointParams configures the HTTP parameters to append to the token
URL.

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

=head2 scopes

scopes defines the OAuth2 scopes used for the token request.

=head2 tlsConfig

tlsConfig defines the TLS configuration to use when connecting to the OAuth2 server.
It requires Prometheus >= v2.43.0.

=head2 tokenUrl

tokenUrl defines the URL to fetch the token from.

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
