package IO::K8s::PrometheusOperator::V1::WebTLSConfig;
# ABSTRACT: tlsConfig defines the TLS parameters for HTTPS.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cert                     => '+IO::K8s::PrometheusOperator::V1::SecretOrConfigMap';
k8s certFile                 => Str;
k8s cipherSuites             => [Str];
k8s clientAuthType           => Str;
k8s clientCAFile             => Str;
k8s client_ca                => '+IO::K8s::PrometheusOperator::V1::SecretOrConfigMap';
k8s curvePreferences         => [Str];
k8s keyFile                  => Str;
k8s keySecret                => 'Core::V1::ConfigMapKeySelector';
k8s maxVersion               => Str;
k8s minVersion               => Str;
k8s preferServerCipherSuites => Bool;













1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::WebTLSConfig - tlsConfig defines the TLS parameters for HTTPS.

=head1 VERSION

version 1.108

=head2 cert

cert defines the Secret or ConfigMap containing the TLS certificate for the web server.

Either `keySecret` or `keyFile` must be defined.

It is mutually exclusive with `certFile`.

=head2 certFile

certFile defines the path to the TLS certificate file in the container for the web server.

Either `keySecret` or `keyFile` must be defined.

It is mutually exclusive with `cert`.

=head2 cipherSuites

cipherSuites defines the list of supported cipher suites for TLS versions up to TLS 1.2.

If not defined, the Go default cipher suites are used.
Available cipher suites are documented in the Go documentation:
https://golang.org/pkg/crypto/tls/#pkg-constants

=head2 clientAuthType

clientAuthType defines the server policy for client TLS authentication.

For more detail on clientAuth options:
https://golang.org/pkg/crypto/tls/#ClientAuthType

=head2 clientCAFile

clientCAFile defines the path to the CA certificate file for client certificate authentication to
the server.

It is mutually exclusive with `client_ca`.

=head2 client_ca

client_ca defines the Secret or ConfigMap containing the CA certificate for client certificate
authentication to the server.

It is mutually exclusive with `clientCAFile`.

=head2 curvePreferences

curvePreferences defines elliptic curves that will be used in an ECDHE handshake, in preference
order.

Available curves are documented in the Go documentation:
https://golang.org/pkg/crypto/tls/#CurveID

=head2 keyFile

keyFile defines the path to the TLS private key file in the container for the web server.

If defined, either `cert` or `certFile` must be defined.

It is mutually exclusive with `keySecret`.

=head2 keySecret

keySecret defines the secret containing the TLS private key for the web server.

Either `cert` or `certFile` must be defined.

It is mutually exclusive with `keyFile`.

=head2 maxVersion

maxVersion defines the Maximum TLS version that is acceptable.

=head2 minVersion

minVersion defines the minimum TLS version that is acceptable.

=head2 preferServerCipherSuites

preferServerCipherSuites defines whether the server selects the client's most preferred cipher
suite, or the server's most preferred cipher suite.

If true then the server's preference, as expressed in
the order of elements in cipherSuites, is used.

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
