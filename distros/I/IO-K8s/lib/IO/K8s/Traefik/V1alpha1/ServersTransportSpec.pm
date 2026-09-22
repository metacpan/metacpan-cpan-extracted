package IO::K8s::Traefik::V1alpha1::ServersTransportSpec;
# ABSTRACT: ServersTransportSpec defines the desired state of a ServersTransport.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s certificatesSecrets => [Str];
k8s cipherSuites        => [Str];
k8s disableHTTP2        => Bool;
k8s forwardingTimeouts  => '+IO::K8s::Traefik::V1alpha1::ForwardingTimeouts';
k8s insecureSkipVerify  => Bool;
k8s maxIdleConnsPerHost => Int, { minimum => -1 };
k8s maxVersion          => Str;
k8s minVersion          => Str;
k8s peerCertURI         => Str;
k8s rootCAs             => ['+IO::K8s::Traefik::V1alpha1::RootCA'];
k8s rootCAsSecrets      => [Str];
k8s serverName          => Str;
k8s spiffe              => '+IO::K8s::Traefik::V1alpha1::Spiffe';














1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ServersTransportSpec - ServersTransportSpec defines the desired state of a ServersTransport.

=head1 VERSION

version 1.108

=head2 certificatesSecrets

CertificatesSecrets defines a list of secret storing client certificates for mTLS.

=head2 cipherSuites

CipherSuites defines the cipher suites to use when contacting backend servers.

=head2 disableHTTP2

DisableHTTP2 disables HTTP/2 for connections with backend servers.

=head2 forwardingTimeouts

ForwardingTimeouts defines the timeouts for requests forwarded to the backend servers.

=head2 insecureSkipVerify

InsecureSkipVerify disables SSL certificate verification.

=head2 maxIdleConnsPerHost

MaxIdleConnsPerHost controls the maximum idle (keep-alive) to keep per-host.

=head2 maxVersion

MaxVersion defines the maximum TLS version to use when contacting backend servers.

=head2 minVersion

MinVersion defines the minimum TLS version to use when contacting backend servers.

=head2 peerCertURI

PeerCertURI defines the peer cert URI used to match against SAN URI during the peer certificate verification.

=head2 rootCAs

RootCAs defines a list of CA certificate Secrets or ConfigMaps used to validate server certificates.

=head2 rootCAsSecrets

RootCAsSecrets defines a list of CA secret used to validate self-signed certificate.

Deprecated: RootCAsSecrets is deprecated, please use the RootCAs option instead.

=head2 serverName

ServerName defines the server name used to contact the server.

=head2 spiffe

Spiffe defines the SPIFFE configuration.

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
