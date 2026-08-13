package IO::K8s::Api::Certificates::V1beta1::PodCertificateRequestStatus;
# ABSTRACT: PodCertificateRequestStatus describes the status of the request, and holds the certificate data if the request is issued.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s beginRefreshAt => Time;


k8s certificateChain => Str;


k8s conditions => ['Meta::V1::Condition'];


k8s notAfter => Time;


k8s notBefore => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Certificates::V1beta1::PodCertificateRequestStatus - PodCertificateRequestStatus describes the status of the request, and holds the certificate data if the request is issued.

=head1 VERSION

version 1.106

=head2 beginRefreshAt

beginRefreshAt is the time at which the kubelet should begin trying to refresh the certificate. This field is set via the /status subresource, and must be set at the same time as certificateChain. Once populated, this field is immutable.

This field is only a hint. Kubelet may start refreshing before or after this time if necessary.

=head2 certificateChain

certificateChain is populated with an issued certificate by the signer. This field is set via the /status subresource. Once populated, this field is immutable.

If the certificate signing request is denied, a condition of type "Denied" is added and this field remains empty. If the signer cannot issue the certificate, a condition of type "Failed" is added and this field remains empty.

Validation requirements:
 1. certificateChain must consist of one or more PEM-formatted certificates.
 2. Each entry must be a valid PEM-wrapped, DER-encoded ASN.1 Certificate as described in section 4 of RFC5280.

If more than one block is present, and the definition of the requested spec.signerName does not indicate otherwise, the first block is the issued certificate, and subsequent blocks should be treated as intermediate certificates and presented in TLS handshakes.

When projecting the chain into a pod volume, kubelet will drop any data in-between the PEM blocks, as well as any PEM block headers.

=head2 conditions

conditions applied to the request. The types "Issued", "Denied", and "Failed" have special handling. At most one of these conditions may be present, and they must have status "True".

If the request is denied with `Reason=UnsupportedKeyType`, the signer may suggest a key type that will work in the message field.

=head2 notAfter

notAfter is the time at which the certificate expires. The value must be the same as the notAfter value in the leaf certificate in certificateChain. This field is set via the /status subresource. Once populated, it is immutable. The signer must set this field at the same time it sets certificateChain.

=head2 notBefore

notBefore is the time at which the certificate becomes valid. The value must be the same as the notBefore value in the leaf certificate in certificateChain. This field is set via the /status subresource. Once populated, it is immutable. The signer must set this field at the same time it sets certificateChain.

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
