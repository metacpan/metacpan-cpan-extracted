package IO::K8s::CertManager::V1::Order;
# ABSTRACT: cert-manager ACME order
our $VERSION = '1.009';
use IO::K8s::APIObject
    api_version     => 'acme.cert-manager.io/v1',
    resource_plural => 'orders';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::Order - cert-manager ACME order

=head1 VERSION

version 1.009

=head1 DESCRIPTION

Order represents an ACME order for a certificate. This is a namespaced resource using the C<acme.cert-manager.io/v1> API version. It is created automatically when using an ACME issuer and tracks the overall certificate request process. The C<spec> and C<status> attributes contain opaque HashRefs whose structure is defined by cert-manager's OpenAPI schema.

=head1 SEE ALSO

=over

=item * L<IO::K8s::CertManager> - cert-manager API classes for Perl

=item * L<https://cert-manager.io/docs/reference/api-docs/#acme.cert-manager.io/v1.Order> - Order upstream documentation

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
