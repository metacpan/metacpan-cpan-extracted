package IO::K8s::PrometheusOperator::V1::StorageSpec;
# ABSTRACT: storage defines the storage used by Prometheus.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s disableMountSubPath => Bool;
k8s emptyDir            => '+IO::K8s::PrometheusOperator::V1::EmptyDirVolumeSource';
k8s ephemeral           => '+IO::K8s::PrometheusOperator::V1::EphemeralVolumeSource';
k8s volumeClaimTemplate => '+IO::K8s::PrometheusOperator::V1::EmbeddedPersistentVolumeClaim';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::StorageSpec - storage defines the storage used by Prometheus.

=head1 VERSION

version 1.108

=head2 disableMountSubPath

disableMountSubPath deprecated: subPath usage will be removed in a future release.

=head2 emptyDir

emptyDir to be used by the StatefulSet.
If specified, it takes precedence over `ephemeral` and `volumeClaimTemplate`.
More info: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

=head2 ephemeral

ephemeral to be used by the StatefulSet.
This is a beta field in k8s 1.21 and GA in 1.15.
For lower versions, starting with k8s 1.19, it requires enabling the GenericEphemeralVolume feature gate.
More info: https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes

=head2 volumeClaimTemplate

volumeClaimTemplate defines the PVC spec to be used by the Prometheus StatefulSets.
The easiest way to use a volume that cannot be automatically provisioned
is to use a label selector alongside manually created PersistentVolumes.

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
