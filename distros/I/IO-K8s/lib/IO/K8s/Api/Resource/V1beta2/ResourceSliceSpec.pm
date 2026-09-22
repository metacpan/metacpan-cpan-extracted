package IO::K8s::Api::Resource::V1beta2::ResourceSliceSpec;
# ABSTRACT: ResourceSliceSpec contains the information published by the driver in one ResourceSlice.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allNodes => Bool;


k8s devices => ['Resource::V1beta2::Device'];


k8s driver => Str, 'required';


k8s nodeName => Str;


k8s nodeSelector => 'Core::V1::NodeSelector';


k8s partitionTypeAttribute => Str;


k8s perDeviceNodeSelection => Bool;


k8s pool => 'Resource::V1beta2::ResourcePool', 'required';


k8s sharedCounters => ['Resource::V1beta2::CounterSet'];


k8s skipNodeOperations => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta2::ResourceSliceSpec - ResourceSliceSpec contains the information published by the driver in one ResourceSlice.

=head1 VERSION

version 1.108

=head2 allNodes

AllNodes indicates that all nodes have access to the resources in the pool.  Exactly one of NodeName, NodeSelector, AllNodes, and PerDeviceNodeSelection must be set.

=head2 devices

Devices lists some or all of the devices in this pool.  Must not have more than 128 entries. If any device uses taints or consumes counters the limit is 64.  Only one of Devices and SharedCounters can be set in a ResourceSlice.

=head2 driver

Driver identifies the DRA driver providing the capacity information. A field selector can be used to list only ResourceSlice objects with a certain driver name.  Must be a DNS subdomain and should end with a DNS domain owned by the vendor of the driver. It should use only lower case characters. This field is immutable.

=head2 nodeName

NodeName identifies the node which provides the resources in this pool. A field selector can be used to list only ResourceSlice objects belonging to a certain node.  This field can be used to limit access from nodes to ResourceSlices with the same node name. It also indicates to autoscalers that adding new nodes of the same type as some old node might also make new resources available.  Exactly one of NodeName, NodeSelector, AllNodes, and PerDeviceNodeSelection must be set. This field is immutable.

=head2 nodeSelector

NodeSelector defines which nodes have access to the resources in the pool, when that pool is not limited to a single node.  Must use exactly one term.  Exactly one of NodeName, NodeSelector, AllNodes, and PerDeviceNodeSelection must be set.

=head2 partitionTypeAttribute

PartitionTypeAttribute names a string device attribute (by fully qualified name, e.g. "gpu.example.com/profile") whose value labels each device with its partition type, such as "Full" or "Half" for a MIG-style GPU.

When set, every partitionable device in the slice must carry the attribute and devices sharing a value must share the same ConsumesCounters cost.

=head2 perDeviceNodeSelection

PerDeviceNodeSelection defines whether the access from nodes to resources in the pool is set on the ResourceSlice level or on each device. If it is set to true, every device defined the ResourceSlice must specify this individually.  Exactly one of NodeName, NodeSelector, AllNodes, and PerDeviceNodeSelection must be set.

=head2 pool

Pool describes the pool that this ResourceSlice belongs to.

=head2 sharedCounters

SharedCounters defines a list of counter sets, each of which has a name and a list of counters available.  The names of the counter sets must be unique in the ResourcePool.  Only one of Devices and SharedCounters can be set in a ResourceSlice.  The maximum number of counter sets is 8.

=head2 skipNodeOperations

SkipNodeOperations lists node-local resource operations (gRPC calls) that will be skipped for the devices in this slice when determining whether operations are necessary on the node. If all allocated devices for a driver in a claim skip an operation, that gRPC call will be skipped. Valid values are:

- "NodePrepareResources": NodePrepareResources gRPC calls are skipped. This
  value cannot be specified unless "NodeUnprepareResources" is also listed
  (or "*" is specified).
- "NodeUnprepareResources": NodeUnprepareResources gRPC calls are skipped. - "*": All node-local resource operations are skipped.

Other values may be added in the future. The kubelet must ignore unknown values.

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
