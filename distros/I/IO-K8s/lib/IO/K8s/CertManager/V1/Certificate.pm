package IO::K8s::CertManager::V1::Certificate;
# ABSTRACT: cert-manager X.509 certificate
our $VERSION = '1.008';
use IO::K8s::APIObject
    api_version     => 'cert-manager.io/v1',
    resource_plural => 'certificates';
with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::CertManaged';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::Certificate - cert-manager X.509 certificate

=head1 VERSION

version 1.008

=head1 DESCRIPTION

Certificate represents a request for an X.509 certificate from an Issuer or ClusterIssuer. This is a namespaced resource using the C<cert-manager.io/v1> API version. The resulting certificate and private key are stored in a Kubernetes Secret. The C<spec> and C<status> attributes contain opaque HashRefs whose structure is defined by cert-manager's OpenAPI schema.

=head1 SEE ALSO

=over

=item * L<IO::K8s::CertManager> - cert-manager API classes for Perl

=item * L<https://cert-manager.io/docs/usage/certificate/> - Certificate upstream documentation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
