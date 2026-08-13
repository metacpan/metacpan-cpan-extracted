package IO::K8s::Api::Core::V1::VolumeProjection;
# ABSTRACT: Projection that may be projected along with other supported volume types. Exactly one of these fields must be set.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s clusterTrustBundle => 'Core::V1::ClusterTrustBundleProjection';


k8s configMap => 'Core::V1::ConfigMapProjection';


k8s downwardAPI => 'Core::V1::DownwardAPIProjection';


k8s podCertificate => 'Core::V1::PodCertificateProjection';


k8s secret => 'Core::V1::SecretProjection';


k8s serviceAccountToken => 'Core::V1::ServiceAccountTokenProjection';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::VolumeProjection - Projection that may be projected along with other supported volume types. Exactly one of these fields must be set.

=head1 VERSION

version 1.106

=head2 clusterTrustBundle

ClusterTrustBundle allows a pod to access the `.spec.trustBundle` field of ClusterTrustBundle objects in an auto-updating file.

Alpha, gated by the ClusterTrustBundleProjection feature gate.

ClusterTrustBundle objects can either be selected by name, or by the combination of signer name and a label selector.

Kubelet performs aggressive normalization of the PEM contents written into the pod filesystem.  Esoteric PEM features such as inter-block comments and block headers are stripped.  Certificates are deduplicated. The ordering of certificates within the file is arbitrary, and Kubelet may change the order over time.

=head2 configMap

configMap information about the configMap data to project

=head2 downwardAPI

downwardAPI information about the downwardAPI data to project

=head2 podCertificate

Projects an auto-rotating credential bundle (private key and certificate chain) that the pod can use either as a TLS client or server.

Kubelet generates a private key and uses it to send a PodCertificateRequest to the named signer.  Once the signer approves the request and issues a certificate chain, Kubelet writes the key and certificate chain to the pod filesystem.  The pod does not start until certificates have been issued for each podCertificate projected volume source in its spec.

Kubelet will begin trying to rotate the certificate at the time indicated by the signer using the PodCertificateRequest.Status.BeginRefreshAt timestamp.

Kubelet can write a single file, indicated by the credentialBundlePath field, or separate files, indicated by the keyPath and certificateChainPath fields.

The credential bundle is a single file in PEM format.  The first PEM entry is the private key (in PKCS#8 format), and the remaining PEM entries are the certificate chain issued by the signer (typically, signers will return their certificate chain in leaf-to-root order).

Prefer using the credential bundle format, since your application code can read it atomically.  If you use keyPath and certificateChainPath, your application must make two separate file reads. If these coincide with a certificate rotation, it is possible that the private key and leaf certificate you read may not correspond to each other.  Your application will need to check for this condition, and re-read until they are consistent.

The named signer controls chooses the format of the certificate it issues; consult the signer implementation's documentation to learn how to use the certificates it issues.

=head2 secret

secret information about the secret data to project

=head2 serviceAccountToken

serviceAccountToken is information about the serviceAccountToken data to project

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
