package IO::K8s::PrometheusOperator::V1::EmbeddedPersistentVolumeClaim;
# ABSTRACT: volumeClaimTemplate defines the PVC spec to be used by the Prometheus StatefulSets.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiVersion => Str;
k8s kind       => Str;
k8s metadata   => '+IO::K8s::PrometheusOperator::V1::EmbeddedObjectMetadata';
k8s spec       => 'Core::V1::PersistentVolumeClaimSpec';
k8s status     => '+IO::K8s::PrometheusOperator::V1::PersistentVolumeClaimStatus';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::EmbeddedPersistentVolumeClaim - volumeClaimTemplate defines the PVC spec to be used by the Prometheus StatefulSets.

=head1 VERSION

version 1.108

=head2 apiVersion

APIVersion defines the versioned schema of this representation of an object.
Servers should convert recognized schemas to the latest internal value, and
may reject unrecognized values.
More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources

=head2 kind

Kind is a string value representing the REST resource this object represents.
Servers may infer this from the endpoint the client submits requests to.
Cannot be updated.
In CamelCase.
More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds

=head2 metadata

metadata defines EmbeddedMetadata contains metadata relevant to an EmbeddedResource.

=head2 spec

spec defines the specification of the  characteristics of a volume requested by a pod author.
More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims

=head2 status

status is deprecated: this field is never set.

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
