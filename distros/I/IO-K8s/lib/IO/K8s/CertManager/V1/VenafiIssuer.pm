package IO::K8s::CertManager::V1::VenafiIssuer;
# ABSTRACT: Venafi configures this issuer to sign certificates using a CyberArk Certificate Manager Self-Hosted or SaaS policy zone.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cloud => '+IO::K8s::CertManager::V1::VenafiCloud';
k8s ngts  => '+IO::K8s::CertManager::V1::VenafiNGTS';
k8s tpp   => '+IO::K8s::CertManager::V1::VenafiTPP';
k8s zone  => Str, { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VenafiIssuer - Venafi configures this issuer to sign certificates using a CyberArk Certificate Manager Self-Hosted or SaaS policy zone.

=head1 VERSION

version 1.108

=head2 cloud

Cloud specifies the CyberArk Certificate Manager SaaS configuration settings.
Only one of CyberArk Certificate Manager may be specified.

=head2 ngts

NGTS specifies Palo Alto Networks Next Generation Trust Services (NGTS) configuration
using OAuth 2.0 Client Credentials. Only one of tpp, cloud, or ngts may be specified.

=head2 tpp

TPP specifies CyberArk Certificate Manager Self-Hosted configuration settings.
Only one of CyberArk Certificate Manager may be specified.

=head2 zone

Zone is the Certificate Manager Policy Zone to use for this issuer.
All requests made to the Certificate Manager platform will be restricted by the named
zone policy.
This field is required.

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
