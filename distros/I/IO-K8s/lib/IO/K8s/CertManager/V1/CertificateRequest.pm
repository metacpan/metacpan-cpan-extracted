package IO::K8s::CertManager::V1::CertificateRequest;
# ABSTRACT: A CertificateRequest is used to request a signed certificate from one of the configured issuers.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'cert-manager.io/v1',
    resource_plural => 'certificaterequests';
with 'IO::K8s::Role::Namespaced';

k8s spec   => '+IO::K8s::CertManager::V1::CertificateRequestSpec';
k8s status => '+IO::K8s::CertManager::V1::CertificateRequestStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateRequest - A CertificateRequest is used to request a signed certificate from one of the configured issuers.

=head1 VERSION

version 1.108

=head2 spec

Specification of the desired state of the CertificateRequest resource.
https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head2 status

Status of the CertificateRequest.
This is set and managed automatically.
Read-only.
More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

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
