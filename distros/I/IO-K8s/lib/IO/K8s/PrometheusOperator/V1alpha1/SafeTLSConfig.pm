package IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig;
# ABSTRACT: tlsConfig defines the TLS configuration to use when connecting to the OAuth2 server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ca                 => '+IO::K8s::PrometheusOperator::V1alpha1::SecretOrConfigMap';
k8s cert               => '+IO::K8s::PrometheusOperator::V1alpha1::SecretOrConfigMap';
k8s insecureSkipVerify => Bool;
k8s keySecret          => 'Core::V1::ConfigMapKeySelector';
k8s maxVersion         => Str, { enum => [qw(TLS10 TLS11 TLS12 TLS13)] };
k8s minVersion         => Str, { enum => [qw(TLS10 TLS11 TLS12 TLS13)] };
k8s serverName         => Str;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::SafeTLSConfig - tlsConfig defines the TLS configuration to use when connecting to the OAuth2 server.

=head1 VERSION

version 1.108

=head2 ca

ca defines the Certificate authority used when verifying server certificates.

=head2 cert

cert defines the Client certificate to present when doing client-authentication.

=head2 insecureSkipVerify

insecureSkipVerify defines how to disable target certificate validation.

=head2 keySecret

keySecret defines the Secret containing the client key file for the targets.

=head2 maxVersion

maxVersion defines the maximum acceptable TLS version.

It requires Prometheus >= v2.41.0 or Thanos >= v0.31.0.

=head2 minVersion

minVersion defines the minimum acceptable TLS version.

It requires Prometheus >= v2.35.0 or Thanos >= v0.28.0.

=head2 serverName

serverName is used to verify the hostname for the targets.

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
