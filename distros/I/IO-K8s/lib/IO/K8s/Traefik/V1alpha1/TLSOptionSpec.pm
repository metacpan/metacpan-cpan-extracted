package IO::K8s::Traefik::V1alpha1::TLSOptionSpec;
# ABSTRACT: TLSOptionSpec defines the desired state of a TLSOption.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s alpnProtocols            => [Str];
k8s cipherSuites             => [Str];
k8s clientAuth               => '+IO::K8s::Traefik::V1alpha1::ClientAuth';
k8s curvePreferences         => [Str];
k8s disableSessionTickets    => Bool;
k8s maxVersion               => Str;
k8s minVersion               => Str;
k8s preferServerCipherSuites => Bool;
k8s sniStrict                => Bool;










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TLSOptionSpec - TLSOptionSpec defines the desired state of a TLSOption.

=head1 VERSION

version 1.108

=head2 alpnProtocols

ALPNProtocols defines the list of supported application level protocols for the TLS handshake, in order of preference.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#alpn-protocols

=head2 cipherSuites

CipherSuites defines the list of supported cipher suites for TLS versions up to TLS 1.2.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#cipher-suites

=head2 clientAuth

ClientAuth defines the server's policy for TLS Client Authentication.

=head2 curvePreferences

CurvePreferences defines the preferred elliptic curves.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/tls/tls-certificates/#certificates-stores#curve-preferences

=head2 disableSessionTickets

DisableSessionTickets disables TLS session resumption via session tickets.

=head2 maxVersion

MaxVersion defines the maximum TLS version that Traefik will accept.
Possible values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13.
Default: None.

=head2 minVersion

MinVersion defines the minimum TLS version that Traefik will accept.
Possible values: VersionTLS10, VersionTLS11, VersionTLS12, VersionTLS13.
Default: VersionTLS10.

=head2 preferServerCipherSuites

PreferServerCipherSuites defines whether the server chooses a cipher suite among his own instead of among the client's.
It is enabled automatically when minVersion or maxVersion is set.

Deprecated: https://github.com/golang/go/issues/45430

=head2 sniStrict

SniStrict defines whether Traefik allows connections from clients connections that do not specify a server_name extension.

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
