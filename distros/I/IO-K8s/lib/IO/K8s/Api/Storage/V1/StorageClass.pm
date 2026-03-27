package IO::K8s::Api::Storage::V1::StorageClass;
# ABSTRACT: StorageClass describes the parameters for a class of storage for which PersistentVolumes can be dynamically provisioned. StorageClasses are non-namespaced; the name of the storage class according to etcd is in ObjectMeta.Name.
our $VERSION = '1.100';
use IO::K8s::APIObject;


k8s allowVolumeExpansion => Bool;


k8s allowedTopologies => ['Core::V1::TopologySelectorTerm'];


k8s mountOptions => [Str];


k8s parameters => { Str => 1 };


k8s provisioner => Str, 'required';


k8s reclaimPolicy => Str;


k8s volumeBindingMode => Str;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Storage::V1::StorageClass - StorageClass describes the parameters for a class of storage for which PersistentVolumes can be dynamically provisioned. StorageClasses are non-namespaced; the name of the storage class according to etcd is in ObjectMeta.Name.

=head1 VERSION

version 1.100

=head1 DESCRIPTION

StorageClass describes the parameters for a class of storage for which PersistentVolumes can be dynamically provisioned.

StorageClasses are non-namespaced; the name of the storage class according to etcd is in ObjectMeta.Name.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 allowVolumeExpansion

allowVolumeExpansion shows whether the storage class allow volume expand.

=head2 allowedTopologies

allowedTopologies restrict the node topologies where volumes can be dynamically provisioned. Each volume plugin defines its own supported topology specifications. An empty TopologySelectorTerm list means there is no topology restriction. This field is only honored by servers that enable the VolumeScheduling feature.

=head2 mountOptions

mountOptions controls the mountOptions for dynamically provisioned PersistentVolumes of this storage class. e.g. ["ro", "soft"]. Not validated - mount of the PVs will simply fail if one is invalid.

=head2 parameters

parameters holds the parameters for the provisioner that should create volumes of this storage class.

=head2 provisioner

provisioner indicates the type of the provisioner.

=head2 reclaimPolicy

reclaimPolicy controls the reclaimPolicy for dynamically provisioned PersistentVolumes of this storage class. Defaults to Delete.

=head2 volumeBindingMode

volumeBindingMode indicates how PersistentVolumeClaims should be provisioned and bound. When unset, VolumeBindingImmediate is used. This field is only honored by servers that enable the VolumeScheduling feature.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#storageclass-v1-storage.k8s.io>

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
