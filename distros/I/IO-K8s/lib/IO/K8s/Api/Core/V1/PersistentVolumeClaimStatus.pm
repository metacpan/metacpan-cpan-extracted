package IO::K8s::Api::Core::V1::PersistentVolumeClaimStatus;
# ABSTRACT: PersistentVolumeClaimStatus is the current status of a persistent volume claim.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s accessModes => [Str];


k8s allocatedResourceStatuses => { Str => 1 };


k8s allocatedResources => { Str => 1 };


k8s capacity => { Str => 1 };


k8s conditions => ['Core::V1::PersistentVolumeClaimCondition'];


k8s currentVolumeAttributesClassName => Str;


k8s modifyVolumeStatus => 'Core::V1::ModifyVolumeStatus';


k8s phase => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PersistentVolumeClaimStatus - PersistentVolumeClaimStatus is the current status of a persistent volume claim.

=head1 VERSION

version 1.009

=head2 accessModes

accessModes contains the actual access modes the volume backing the PVC has. More info: https://kubernetes.io/docs/concepts/storage/persistent-volumes#access-modes-1

=head2 allocatedResourceStatuses

allocatedResourceStatuses stores status of resource being resized for the given PVC. Key names follow standard Kubernetes label syntax. Valid values are either:
	* Un-prefixed keys:
		- storage - the capacity of the volume.
	* Custom resources must use implementation-defined prefixed names such as "example.com/my-custom-resource"
Apart from above values - keys that are unprefixed or have kubernetes.io prefix are considered reserved and hence may not be used.

ClaimResourceStatus can be in any of following states:
	- ControllerResizeInProgress:
		State set when resize controller starts resizing the volume in control-plane.
	- ControllerResizeFailed:
		State set when resize has failed in resize controller with a terminal error.
	- NodeResizePending:
		State set when resize controller has finished resizing the volume but further resizing of
		volume is needed on the node.
	- NodeResizeInProgress:
		State set when kubelet starts resizing the volume.
	- NodeResizeFailed:
		State set when resizing has failed in kubelet with a terminal error. Transient errors don't set
		NodeResizeFailed.
For example: if expanding a PVC for more capacity - this field can be one of the following states:
	- pvc.status.allocatedResourceStatus['storage'] = "ControllerResizeInProgress"
     - pvc.status.allocatedResourceStatus['storage'] = "ControllerResizeFailed"
     - pvc.status.allocatedResourceStatus['storage'] = "NodeResizePending"
     - pvc.status.allocatedResourceStatus['storage'] = "NodeResizeInProgress"
     - pvc.status.allocatedResourceStatus['storage'] = "NodeResizeFailed"
When this field is not set, it means that no resize operation is in progress for the given PVC.

A controller that receives PVC update with previously unknown resourceName or ClaimResourceStatus should ignore the update for the purpose it was designed. For example - a controller that only is responsible for resizing capacity of the volume, should ignore PVC updates that change other valid resources associated with PVC.

This is an alpha field and requires enabling RecoverVolumeExpansionFailure feature.

=head2 allocatedResources

allocatedResources tracks the resources allocated to a PVC including its capacity. Key names follow standard Kubernetes label syntax. Valid values are either:
	* Un-prefixed keys:
		- storage - the capacity of the volume.
	* Custom resources must use implementation-defined prefixed names such as "example.com/my-custom-resource"
Apart from above values - keys that are unprefixed or have kubernetes.io prefix are considered reserved and hence may not be used.

Capacity reported here may be larger than the actual capacity when a volume expansion operation is requested. For storage quota, the larger value from allocatedResources and PVC.spec.resources is used. If allocatedResources is not set, PVC.spec.resources alone is used for quota calculation. If a volume expansion capacity request is lowered, allocatedResources is only lowered if there are no expansion operations in progress and if the actual volume capacity is equal or lower than the requested capacity.

A controller that receives PVC update with previously unknown resourceName should ignore the update for the purpose it was designed. For example - a controller that only is responsible for resizing capacity of the volume, should ignore PVC updates that change other valid resources associated with PVC.

This is an alpha field and requires enabling RecoverVolumeExpansionFailure feature.

=head2 capacity

capacity represents the actual resources of the underlying volume.

=head2 conditions

conditions is the current Condition of persistent volume claim. If underlying persistent volume is being resized then the Condition will be set to 'Resizing'.

=head2 currentVolumeAttributesClassName

currentVolumeAttributesClassName is the current name of the VolumeAttributesClass the PVC is using. When unset, there is no VolumeAttributeClass applied to this PersistentVolumeClaim This is a beta field and requires enabling VolumeAttributesClass feature (off by default).

=head2 modifyVolumeStatus

ModifyVolumeStatus represents the status object of ControllerModifyVolume operation. When this is unset, there is no ModifyVolume operation being attempted. This is a beta field and requires enabling VolumeAttributesClass feature (off by default).

=head2 phase

phase represents the current phase of PersistentVolumeClaim.

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
