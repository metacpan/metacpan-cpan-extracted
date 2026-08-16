package IO::K8s::Api::Core::V1::PodCertificateProjection;
# ABSTRACT: PodCertificateProjection provides a private key and X.509 certificate in the pod filesystem.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s certificateChainPath => Str;


k8s credentialBundlePath => Str;


k8s keyPath => Str;


k8s keyType => Str, 'required';


k8s maxExpirationSeconds => Int;


k8s signerName => Str, 'required';


k8s userAnnotations => { Str => 1 };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodCertificateProjection - PodCertificateProjection provides a private key and X.509 certificate in the pod filesystem.

=head1 VERSION

version 1.107

=head2 certificateChainPath

Write the certificate chain at this path in the projected volume.

Most applications should use credentialBundlePath.  When using keyPath and certificateChainPath, your application needs to check that the key and leaf certificate are consistent, because it is possible to read the files mid-rotation.

=head2 credentialBundlePath

Write the credential bundle at this path in the projected volume.

The credential bundle is a single file that contains multiple PEM blocks. The first PEM block is a PRIVATE KEY block, containing a PKCS#8 private key.

The remaining blocks are CERTIFICATE blocks, containing the issued certificate chain from the signer (leaf and any intermediates).

Using credentialBundlePath lets your Pod's application code make a single atomic read that retrieves a consistent key and certificate chain.  If you project them to separate files, your application code will need to additionally check that the leaf certificate was issued to the key.

=head2 keyPath

Write the key at this path in the projected volume.

Most applications should use credentialBundlePath.  When using keyPath and certificateChainPath, your application needs to check that the key and leaf certificate are consistent, because it is possible to read the files mid-rotation.

=head2 keyType

The type of keypair Kubelet will generate for the pod.

Valid values are "RSA3072", "RSA4096", "ECDSAP256", "ECDSAP384", "ECDSAP521", and "ED25519".

=head2 maxExpirationSeconds

maxExpirationSeconds is the maximum lifetime permitted for the certificate.

Kubelet copies this value verbatim into the PodCertificateRequests it generates for this projection.

If omitted, kube-apiserver will set it to 86400(24 hours). kube-apiserver will reject values shorter than 3600 (1 hour).  The maximum allowable value is 7862400 (91 days).

The signer implementation is then free to issue a certificate with any lifetime *shorter* than MaxExpirationSeconds, but no shorter than 3600 seconds (1 hour).  This constraint is enforced by kube-apiserver. `kubernetes.io` signers will never issue certificates with a lifetime longer than 24 hours.

=head2 signerName

Kubelet's generated CSRs will be addressed to this signer.

=head2 userAnnotations

userAnnotations allow pod authors to pass additional information to the signer implementation.  Kubernetes does not restrict or validate this metadata in any way.

These values are copied verbatim into the `spec.unverifiedUserAnnotations` field of the PodCertificateRequest objects that Kubelet creates.

Entries are subject to the same validation as object metadata annotations, with the addition that all keys must be domain-prefixed. No restrictions are placed on values, except an overall size limitation on the entire field.

Signers should document the keys and values they support. Signers should deny requests that contain keys they do not recognize.

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
