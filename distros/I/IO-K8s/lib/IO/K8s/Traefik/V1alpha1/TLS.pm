package IO::K8s::Traefik::V1alpha1::TLS;
# ABSTRACT: TLS defines the TLS configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s certResolver => Str;
k8s domains      => ['+IO::K8s::Traefik::V1alpha1::Domain'];
k8s options      => 'Core::V1::SecretReference';
k8s secretName   => Str;
k8s store        => 'Core::V1::SecretReference';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TLS - TLS defines the TLS configuration.

=head1 VERSION

version 1.108

=head2 certResolver

CertResolver defines the name of the certificate resolver to use.
Cert resolvers have to be configured in the static configuration.
More info: https://doc.traefik.io/traefik/v3.7/reference/install-configuration/tls/certificate-resolvers/acme/

=head2 domains

Domains defines the list of domains that will be used to issue certificates.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/tls/tls-certificates/#domains

=head2 options

Options defines the reference to a TLSOption, that specifies the parameters of the TLS connection.
If not defined, the `default` TLSOption is used.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/tls/tls-options/

=head2 secretName

SecretName is the name of the referenced Kubernetes Secret to specify the certificate details.

=head2 store

Store defines the reference to the TLSStore, that will be used to store certificates.
Please note that only `default` TLSStore can be used.

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
