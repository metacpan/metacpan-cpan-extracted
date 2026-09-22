package IO::K8s::Api::Resource::V1::NodeAllocatableMapping;
# ABSTRACT: NodeAllocatableMapping defines how a DRA allocation directly translates into a node allocatable resource quantity. The mapping can be derived from either the count of allocated devices (via deviceMultiplier) or the specific capacity consumed (via capacityKey and capacityMultiplier). These options are mutually exclusive. Kubelet adds this mapped resource quantity from claim to both requests and limits at the pod-level cgroup, and to limits at the container-level cgroup for each container referencing the claim.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s capacityKey => Str;


k8s capacityMultiplier => Quantity;


k8s deviceMultiplier => Quantity;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1::NodeAllocatableMapping - NodeAllocatableMapping defines how a DRA allocation directly translates into a node allocatable resource quantity. The mapping can be derived from either the count of allocated devices (via deviceMultiplier) or the specific capacity consumed (via capacityKey and capacityMultiplier). These options are mutually exclusive. Kubelet adds this mapped resource quantity from claim to both requests and limits at the pod-level cgroup, and to limits at the container-level cgroup for each container referencing the claim.

=head1 VERSION

version 1.108

=head2 capacityKey

CapacityKey references a capacity name defined as a key in the `spec.devices[*].capacity` map. When this field is set, the value associated with this key in the `status.allocation.devices.results[*].consumedCapacity` map (for a specific claim allocation) determines the base quantity for the node allocatable resource. `capacityMultiplier` must also be set and is multiplied with the base quantity. For example, if `spec.devices[*].capacity` has an entry "dra.example.com/memory": "128Gi", and this field is set to "dra.example.com/memory", then for a claim allocation that consumes { "dra.example.com/memory": "4Gi" } the base quantity for the node allocatable resource mapping will be "4Gi". The final node allocatable resource amount is `consumedCapacity[capacityKey]` * `capacityMultiplier`.

=head2 capacityMultiplier

CapacityMultiplier is used as a multiplier for the allocated capacity consumed. It is only valid if `capacityKey` is set. The final node allocatable resource amount is `consumedCapacity[capacityKey]` * `capacityMultiplier`. For example, if a Device's capacity "dra.example.com/cores" is consumed, and each "core" provides 2 "cpu"s, the mapping would be: {ResourceName: "cpu", capacityKey: "dra.example.com/cores", capacityMultiplier: "2"}. If a claim consumes 8 "dra.example.com/cores", the CPU footprint is 8 * 2 = 16.

=head2 deviceMultiplier

DeviceMultiplier is used as a multiplier for the allocated device count in the claim. The final node allocatable resource amount is `deviceCount` * `deviceMultiplier`. For example, a DRA driver representing each cache complex (CCX) as a device would have {ResourceName: "cpu", deviceMultiplier: "8"} in its `nodeAllocatableResources`. If 2 devices (CCX) are allocated to the claim, 2 * 8 = 16 CPUs would be considered as allocated. It is only valid when `capacityKey` and `capacityMultiplier` are not set.

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
