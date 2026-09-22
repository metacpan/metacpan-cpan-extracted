package IO::K8s::CertManager::V1::CertificateRequestStatus;
# ABSTRACT: Status of the CertificateRequest.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ca          => Str;
k8s certificate => Str;
k8s conditions  => ['+IO::K8s::CertManager::V1::CertificateRequestCondition'];
k8s failureTime => Time;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::CertificateRequestStatus - Status of the CertificateRequest.

=head1 VERSION

version 1.108

=head2 ca

The PEM encoded X.509 certificate of the signer, also known as the CA
(Certificate Authority).
This is set on a best-effort basis by different issuers.
If not set, the CA is assumed to be unknown/not available.

=head2 certificate

The PEM encoded X.509 certificate resulting from the certificate
signing request.
If not set, the CertificateRequest has either not been completed or has
failed. More information on failure can be found by checking the
`conditions` field.

=head2 conditions

List of status conditions to indicate the status of a CertificateRequest.
Known condition types are `Ready`, `InvalidRequest`, `Approved` and `Denied`.

=head2 failureTime

FailureTime stores the time that this CertificateRequest failed. This is
used to influence garbage collection and back-off.

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
