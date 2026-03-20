package IO::K8s::Api::Core::V1::PersistentVolumeSpec;
# ABSTRACT: PersistentVolumeSpec is the specification of a persistent volume.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s accessModes => [Str];


k8s awsElasticBlockStore => 'Core::V1::AWSElasticBlockStoreVolumeSource';


k8s azureDisk => 'Core::V1::AzureDiskVolumeSource';


k8s azureFile => 'Core::V1::AzureFilePersistentVolumeSource';


k8s capacity => { Str => 1 };


k8s cephfs => 'Core::V1::CephFSPersistentVolumeSource';


k8s cinder => 'Core::V1::CinderPersistentVolumeSource';


k8s claimRef => 'Core::V1::ObjectReference';


k8s csi => 'Core::V1::CSIPersistentVolumeSource';


k8s fc => 'Core::V1::FCVolumeSource';


k8s flexVolume => 'Core::V1::FlexPersistentVolumeSource';


k8s flocker => 'Core::V1::FlockerVolumeSource';


k8s gcePersistentDisk => 'Core::V1::GCEPersistentDiskVolumeSource';


k8s glusterfs => 'Core::V1::GlusterfsPersistentVolumeSource';


k8s hostPath => 'Core::V1::HostPathVolumeSource';


k8s iscsi => 'Core::V1::ISCSIPersistentVolumeSource';


k8s local => 'Core::V1::LocalVolumeSource';


k8s mountOptions => [Str];


k8s nfs => 'Core::V1::NFSVolumeSource';


k8s nodeAffinity => 'Core::V1::VolumeNodeAffinity';


k8s persistentVolumeReclaimPolicy => Str;


k8s photonPersistentDisk => 'Core::V1::PhotonPersistentDiskVolumeSource';


k8s portworxVolume => 'Core::V1::PortworxVolumeSource';


k8s quobyte => 'Core::V1::QuobyteVolumeSource';


k8s rbd => 'Core::V1::RBDPersistentVolumeSource';


k8s scaleIO => 'Core::V1::ScaleIOPersistentVolumeSource';


k8s storageClassName => Str;


k8s storageos => 'Core::V1::StorageOSPersistentVolumeSource';


k8s volumeAttributesClassName => Str;


k8s volumeMode => Str;


k8s vsphereVolume => 'Core::V1::VsphereVirtualDiskVolumeSource';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PersistentVolumeSpec - PersistentVolumeSpec is the specification of a persistent volume.

=head1 VERSION

version 1.009

=head2 accessModes

accessModes contains all ways the volume can be mounted. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes

=head2 awsElasticBlockStore

awsElasticBlockStore represents an AWS Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore

=head2 azureDisk

azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.

=head2 azureFile

azureFile represents an Azure File Service mount on the host and bind mount to the pod.

=head2 capacity

capacity is the description of the persistent volume's resources and capacity. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#capacity

=head2 cephfs

cephFS represents a Ceph FS mount on the host that shares a pod's lifetime

=head2 cinder

cinder represents a cinder volume attached and mounted on kubelets host machine. More info: https://examples.k8s.io/mysql-cinder-pd/README.md

=head2 claimRef

claimRef is part of a bi-directional binding between PersistentVolume and PersistentVolumeClaim. Expected to be non-nil when bound. claim.VolumeName is the authoritative bind between PV and PVC. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#binding

=head2 csi

csi represents storage that is handled by an external CSI driver (Beta feature).

=head2 fc

fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod.

=head2 flexVolume

flexVolume represents a generic volume resource that is provisioned/attached using an exec based plugin.

=head2 flocker

flocker represents a Flocker volume attached to a kubelet's host machine and exposed to the pod for its usage. This depends on the Flocker control service being running

=head2 gcePersistentDisk

gcePersistentDisk represents a GCE Disk resource that is attached to a kubelet's host machine and then exposed to the pod. Provisioned by an admin. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk

=head2 glusterfs

glusterfs represents a Glusterfs volume that is attached to a host and exposed to the pod. Provisioned by an admin. More info: https://examples.k8s.io/volumes/glusterfs/README.md

=head2 hostPath

hostPath represents a directory on the host. Provisioned by a developer or tester. This is useful for single-node development and testing only! On-host storage is not supported in any way and WILL NOT WORK in a multi-node cluster. More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath

=head2 iscsi

iscsi represents an ISCSI Disk resource that is attached to a kubelet's host machine and then exposed to the pod. Provisioned by an admin.

=head2 local

local represents directly-attached storage with node affinity

=head2 mountOptions

mountOptions is the list of mount options, e.g. ["ro", "soft"]. Not validated - mount will simply fail if one is invalid. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#mount-options

=head2 nfs

nfs represents an NFS mount on the host. Provisioned by an admin. More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs

=head2 nodeAffinity

nodeAffinity defines constraints that limit what nodes this volume can be accessed from. This field influences the scheduling of pods that use this volume.

=head2 persistentVolumeReclaimPolicy

persistentVolumeReclaimPolicy defines what happens to a persistent volume when released from its claim. Valid options are Retain (default for manually created PersistentVolumes), Delete (default for dynamically provisioned PersistentVolumes), and Recycle (deprecated). Recycle must be supported by the volume plugin underlying this PersistentVolume. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#reclaiming

=head2 photonPersistentDisk

photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine

=head2 portworxVolume

portworxVolume represents a portworx volume attached and mounted on kubelets host machine

=head2 quobyte

quobyte represents a Quobyte mount on the host that shares a pod's lifetime

=head2 rbd

rbd represents a Rados Block Device mount on the host that shares a pod's lifetime. More info: https://examples.k8s.io/volumes/rbd/README.md

=head2 scaleIO

scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes.

=head2 storageClassName

storageClassName is the name of StorageClass to which this persistent volume belongs. Empty value means that this volume does not belong to any StorageClass.

=head2 storageos

storageOS represents a StorageOS volume that is attached to the kubelet's host machine and mounted into the pod More info: https://examples.k8s.io/volumes/storageos/README.md

=head2 volumeAttributesClassName

Name of VolumeAttributesClass to which this persistent volume belongs. Empty value is not allowed. When this field is not set, it indicates that this volume does not belong to any VolumeAttributesClass. This field is mutable and can be changed by the CSI driver after a volume has been updated successfully to a new class. For an unbound PersistentVolume, the volumeAttributesClassName will be matched with unbound PersistentVolumeClaims during the binding process. This is a beta field and requires enabling VolumeAttributesClass feature (off by default).

=head2 volumeMode

volumeMode defines if a volume is intended to be used with a formatted filesystem or to remain in raw block state. Value of Filesystem is implied when not included in spec.

=head2 vsphereVolume

vsphereVolume represents a vSphere volume attached and mounted on kubelets host machine

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
