package IO::K8s::Api::Resource::V1::Device;
# ABSTRACT: Device represents one individual hardware instance that can be selected based on its attributes. Besides the name, exactly one field must be set.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s allNodes => Bool;


k8s allowMultipleAllocations => Bool;


k8s attributes => { 'Resource::V1::DeviceAttribute' => 1 };


k8s bindingConditions => [Str];


k8s bindingFailureConditions => [Str];


k8s bindsToNode => Bool;


k8s capacity => { 'Resource::V1::DeviceCapacity' => 1 };


k8s consumesCounters => ['Resource::V1::DeviceCounterConsumption'];


k8s name => Str, 'required';


k8s nodeAllocatableResourceMappings => { 'Resource::V1::NodeAllocatableResourceMapping' => 1 };


k8s nodeName => Str;


k8s nodeSelector => 'Core::V1::NodeSelector';


k8s taints => ['Resource::V1::DeviceTaint'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::Device - Device represents one individual hardware instance that can be selected based on its attributes. Besides the name, exactly one field must be set.

=head1 VERSION

version 1.106

=head2 allNodes

AllNodes indicates that all nodes have access to the device. Must only be set if Spec.PerDeviceNodeSelection is set to true. At most one of NodeName, NodeSelector and AllNodes can be set.

=head2 allowMultipleAllocations

AllowMultipleAllocations marks whether the device is allowed to be allocated to multiple DeviceRequests. If AllowMultipleAllocations is set to true, the device can be allocated more than once, and all of its capacity is consumable, regardless of whether the requestPolicy is defined or not.

=head2 attributes

Attributes defines the set of attributes for this device. The name of each attribute must be unique in that set.

The maximum number of attributes and capacities combined is 32.

=head2 bindingConditions

BindingConditions defines the conditions for proceeding with binding. All of these conditions must be set in the per-device status conditions with a value of True to proceed with binding the pod to the node while scheduling the pod. The maximum number of binding conditions is 4. The conditions must be a valid condition type string. This is a beta field and requires enabling the DRADeviceBindingConditions and DRAResourceClaimDeviceStatus feature gates.

=head2 bindingFailureConditions

BindingFailureConditions defines the conditions for binding failure. They may be set in the per-device status conditions. If any is set to "True", a binding failure occurred. The maximum number of binding failure conditions is 4. The conditions must be a valid condition type string. This is a beta field and requires enabling the DRADeviceBindingConditions and DRAResourceClaimDeviceStatus feature gates.

=head2 bindsToNode

BindsToNode indicates if the usage of an allocation involving this device has to be limited to exactly the node that was chosen when allocating the claim. If set to true, the scheduler will set the ResourceClaim.Status.Allocation.NodeSelector to match the node where the allocation was made. This is a beta field and requires enabling the DRADeviceBindingConditions and DRAResourceClaimDeviceStatus feature gates.

=head2 capacity

Capacity defines the set of capacities for this device. The name of each capacity must be unique in that set.

The maximum number of attributes and capacities combined is 32.

=head2 consumesCounters

ConsumesCounters defines a list of references to sharedCounters and the set of counters that the device will consume from those counter sets. There can only be a single entry per counterSet. The maximum number of device counter consumptions per device is 2.

=head2 name

Name is unique identifier among all devices managed by the driver in the pool. It must be a DNS label.

=head2 nodeAllocatableResourceMappings

NodeAllocatableResourceMappings defines the mapping of node resources that are managed by the DRA driver exposing this device. This includes resources currently reported in v1.Node C<status.allocatable> that are not extended resources. Examples include "cpu", "memory", "ephemeral-storage", and hugepages. In addition to standard requests made through the Pod C<spec>, these resources can also be requested through claims and allocated by the DRA driver.

The keys of this map are the node-allocatable resource names (e.g., "cpu", "memory"). Extended resource names are not permitted as keys.

=head2 nodeName

NodeName identifies the node where the device is available. Must only be set if Spec.PerDeviceNodeSelection is set to true. At most one of NodeName, NodeSelector and AllNodes can be set.

=head2 nodeSelector

NodeSelector defines the nodes where the device is available. Must use exactly one term. Must only be set if Spec.PerDeviceNodeSelection is set to true. At most one of NodeName, NodeSelector and AllNodes can be set.

=head2 taints

If specified, these are the driver-defined taints. The maximum number of taints is 16. If taints are set for any device in a ResourceSlice, then the maximum number of allowed devices per ResourceSlice is 64 instead of 128. This is a beta field and requires enabling the DRADeviceTaints feature gate.

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
