package IO::K8s::Api::Core::V1::Volume;
# ABSTRACT: Volume represents a named volume in a pod that may be accessed by any container in the pod.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s awsElasticBlockStore => 'Core::V1::AWSElasticBlockStoreVolumeSource';


k8s azureDisk => 'Core::V1::AzureDiskVolumeSource';


k8s azureFile => 'Core::V1::AzureFileVolumeSource';


k8s cephfs => 'Core::V1::CephFSVolumeSource';


k8s cinder => 'Core::V1::CinderVolumeSource';


k8s configMap => 'Core::V1::ConfigMapVolumeSource';


k8s csi => 'Core::V1::CSIVolumeSource';


k8s downwardAPI => 'Core::V1::DownwardAPIVolumeSource';


k8s emptyDir => 'Core::V1::EmptyDirVolumeSource';


k8s ephemeral => 'Core::V1::EphemeralVolumeSource';


k8s fc => 'Core::V1::FCVolumeSource';


k8s flexVolume => 'Core::V1::FlexVolumeSource';


k8s flocker => 'Core::V1::FlockerVolumeSource';


k8s gcePersistentDisk => 'Core::V1::GCEPersistentDiskVolumeSource';


k8s gitRepo => 'Core::V1::GitRepoVolumeSource';


k8s glusterfs => 'Core::V1::GlusterfsVolumeSource';


k8s hostPath => 'Core::V1::HostPathVolumeSource';


k8s image => 'Core::V1::ImageVolumeSource';


k8s iscsi => 'Core::V1::ISCSIVolumeSource';


k8s name => Str, 'required';


k8s nfs => 'Core::V1::NFSVolumeSource';


k8s persistentVolumeClaim => 'Core::V1::PersistentVolumeClaimVolumeSource';


k8s photonPersistentDisk => 'Core::V1::PhotonPersistentDiskVolumeSource';


k8s portworxVolume => 'Core::V1::PortworxVolumeSource';


k8s projected => 'Core::V1::ProjectedVolumeSource';


k8s quobyte => 'Core::V1::QuobyteVolumeSource';


k8s rbd => 'Core::V1::RBDVolumeSource';


k8s scaleIO => 'Core::V1::ScaleIOVolumeSource';


k8s secret => 'Core::V1::SecretVolumeSource';


k8s storageos => 'Core::V1::StorageOSVolumeSource';


k8s vsphereVolume => 'Core::V1::VsphereVirtualDiskVolumeSource';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::Volume - Volume represents a named volume in a pod that may be accessed by any container in the pod.

=head1 VERSION

version 1.008

=head2 awsElasticBlockStore

awsElasticBlockStore represents an AWS Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes#awselasticblockstore

=head2 azureDisk

azureDisk represents an Azure Data Disk mount on the host and bind mount to the pod.

=head2 azureFile

azureFile represents an Azure File Service mount on the host and bind mount to the pod.

=head2 cephfs

cephFS represents a Ceph FS mount on the host that shares a pod's lifetime

=head2 cinder

cinder represents a cinder volume attached and mounted on kubelets host machine. More info: https://examples.k8s.io/mysql-cinder-pd/README.md

=head2 configMap

configMap represents a configMap that should populate this volume

=head2 csi

csi (Container Storage Interface) represents ephemeral storage that is handled by certain external CSI drivers (Beta feature).

=head2 downwardAPI

downwardAPI represents downward API about the pod that should populate this volume

=head2 emptyDir

emptyDir represents a temporary directory that shares a pod's lifetime. More info: https://kubernetes.io/docs/concepts/storage/volumes#emptydir

=head2 ephemeral

ephemeral represents a volume that is handled by a cluster storage driver. The volume's lifecycle is tied to the pod that defines it - it will be created before the pod starts, and deleted when the pod is removed.

Use this if: a) the volume is only needed while the pod runs, b) features of normal volumes like restoring from snapshot or capacity
   tracking are needed,
c) the storage driver is specified through a storage class, and d) the storage driver supports dynamic volume provisioning through
   a PersistentVolumeClaim (see EphemeralVolumeSource for more
   information on the connection between this volume type
   and PersistentVolumeClaim).

Use PersistentVolumeClaim or one of the vendor-specific APIs for volumes that persist for longer than the lifecycle of an individual pod.

Use CSI for light-weight local ephemeral volumes if the CSI driver is meant to be used that way - see the documentation of the driver for more information.

A pod can use both types of ephemeral volumes and persistent volumes at the same time.

=head2 fc

fc represents a Fibre Channel resource that is attached to a kubelet's host machine and then exposed to the pod.

=head2 flexVolume

flexVolume represents a generic volume resource that is provisioned/attached using an exec based plugin.

=head2 flocker

flocker represents a Flocker volume attached to a kubelet's host machine. This depends on the Flocker control service being running

=head2 gcePersistentDisk

gcePersistentDisk represents a GCE Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://kubernetes.io/docs/concepts/storage/volumes#gcepersistentdisk

=head2 gitRepo

gitRepo represents a git repository at a particular revision. DEPRECATED: GitRepo is deprecated. To provision a container with a git repo, mount an EmptyDir into an InitContainer that clones the repo using git, then mount the EmptyDir into the Pod's container.

=head2 glusterfs

glusterfs represents a Glusterfs mount on the host that shares a pod's lifetime. More info: https://examples.k8s.io/volumes/glusterfs/README.md

=head2 hostPath

hostPath represents a pre-existing file or directory on the host machine that is directly exposed to the container. This is generally used for system agents or other privileged things that are allowed to see the host machine. Most containers will NOT need this. More info: https://kubernetes.io/docs/concepts/storage/volumes#hostpath

=head2 image

image represents an OCI object (a container image or artifact) pulled and mounted on the kubelet's host machine. The volume is resolved at pod startup depending on which PullPolicy value is provided:

- Always: the kubelet always attempts to pull the reference. Container creation will fail If the pull fails. - Never: the kubelet never pulls the reference and only uses a local image or artifact. Container creation will fail if the reference isn't present. - IfNotPresent: the kubelet pulls if the reference isn't already present on disk. Container creation will fail if the reference isn't present and the pull fails.

The volume gets re-resolved if the pod gets deleted and recreated, which means that new remote content will become available on pod recreation. A failure to resolve or pull the image during pod startup will block containers from starting and may add significant latency. Failures will be retried using normal volume backoff and will be reported on the pod reason and message. The types of objects that may be mounted by this volume are defined by the container runtime implementation on a host machine and at minimum must include all valid types supported by the container image field. The OCI object gets mounted in a single directory (spec.containers[*].volumeMounts.mountPath) by merging the manifest layers in the same way as for container images. The volume will be mounted read-only (ro) and non-executable files (noexec). Sub path mounts for containers are not supported (spec.containers[*].volumeMounts.subpath). The field spec.securityContext.fsGroupChangePolicy has no effect on this volume type.

=head2 iscsi

iscsi represents an ISCSI Disk resource that is attached to a kubelet's host machine and then exposed to the pod. More info: https://examples.k8s.io/volumes/iscsi/README.md

=head2 name

name of the volume. Must be a DNS_LABEL and unique within the pod. More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names

=head2 nfs

nfs represents an NFS mount on the host that shares a pod's lifetime More info: https://kubernetes.io/docs/concepts/storage/volumes#nfs

=head2 persistentVolumeClaim

persistentVolumeClaimVolumeSource represents a reference to a PersistentVolumeClaim in the same namespace. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#persistentvolumeclaims

=head2 photonPersistentDisk

photonPersistentDisk represents a PhotonController persistent disk attached and mounted on kubelets host machine

=head2 portworxVolume

portworxVolume represents a portworx volume attached and mounted on kubelets host machine

=head2 projected

projected items for all in one resources secrets, configmaps, and downward API

=head2 quobyte

quobyte represents a Quobyte mount on the host that shares a pod's lifetime

=head2 rbd

rbd represents a Rados Block Device mount on the host that shares a pod's lifetime. More info: https://examples.k8s.io/volumes/rbd/README.md

=head2 scaleIO

scaleIO represents a ScaleIO persistent volume attached and mounted on Kubernetes nodes.

=head2 secret

secret represents a secret that should populate this volume. More info: https://kubernetes.io/docs/concepts/storage/volumes#secret

=head2 storageos

storageOS represents a StorageOS volume attached and mounted on Kubernetes nodes.

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
