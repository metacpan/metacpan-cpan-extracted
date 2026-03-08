package IO::K8s::Api::Core::V1::VolumeProjection;
# ABSTRACT: Projection that may be projected along with other supported volume types. Exactly one of these fields must be set.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s clusterTrustBundle => 'Core::V1::ClusterTrustBundleProjection';


k8s configMap => 'Core::V1::ConfigMapProjection';


k8s downwardAPI => 'Core::V1::DownwardAPIProjection';


k8s secret => 'Core::V1::SecretProjection';


k8s serviceAccountToken => 'Core::V1::ServiceAccountTokenProjection';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::VolumeProjection - Projection that may be projected along with other supported volume types. Exactly one of these fields must be set.

=head1 VERSION

version 1.006

=head2 clusterTrustBundle

ClusterTrustBundle allows a pod to access the `.spec.trustBundle` field of ClusterTrustBundle objects in an auto-updating file.

Alpha, gated by the ClusterTrustBundleProjection feature gate.

ClusterTrustBundle objects can either be selected by name, or by the combination of signer name and a label selector.

Kubelet performs aggressive normalization of the PEM contents written into the pod filesystem.  Esoteric PEM features such as inter-block comments and block headers are stripped.  Certificates are deduplicated. The ordering of certificates within the file is arbitrary, and Kubelet may change the order over time.

=head2 configMap

configMap information about the configMap data to project

=head2 downwardAPI

downwardAPI information about the downwardAPI data to project

=head2 secret

secret information about the secret data to project

=head2 serviceAccountToken

serviceAccountToken is information about the serviceAccountToken data to project

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
