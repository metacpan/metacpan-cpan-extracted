package IO::K8s::Api::Certificates::V1beta1::PodCertificateRequest;
# ABSTRACT: PodCertificateRequest encapsulates a pod's request for a certificate from a signer, as well as the signer's response, if any.
our $VERSION = '1.106';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Certificates::V1beta1::PodCertificateRequestSpec', 'required';


k8s status => 'Certificates::V1beta1::PodCertificateRequestStatus';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Certificates::V1beta1::PodCertificateRequest - PodCertificateRequest encapsulates a pod's request for a certificate from a signer, as well as the signer's response, if any.

=head1 VERSION

version 1.106

=head1 DESCRIPTION

PodCertificateRequest encapsulates a pod's request for a certificate from a signer, as well as the signer's response, if any.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

spec contains the details about the certificate being requested.

=head2 status

status contains the issued certificate, and a standard set of conditions.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.36/#podcertificaterequest-v1beta1-certificates.k8s.io>

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
