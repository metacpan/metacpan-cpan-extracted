package IO::K8s::Api::Resource::V1beta1::NodeAllocatableResourceMapping;
# ABSTRACT: NodeAllocatableResourceMapping defines the translation between the DRA device/capacity units requested to the corresponding quantity of the node allocatable resource.
our $VERSION = '1.107';
use IO::K8s::Resource;

k8s allocationMultiplier => Quantity;


k8s capacityKey => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1beta1::NodeAllocatableResourceMapping - NodeAllocatableResourceMapping defines the translation between the DRA device/capacity units requested to the corresponding quantity of the node allocatable resource.

=head1 VERSION

version 1.107

=head2 allocationMultiplier

AllocationMultiplier is used as a multiplier for the allocated device count or the allocated capacity in the claim. It defaults to 1 if not specified. How the field is used also depends on whether `capacityKey` is set. 1.  If `capacityKey` is NOT set: `allocationMultiplier` multiplies the device count allocated to the claim. 	   a. A DRA driver representing each CPU core as a device would have        {ResourceName: "cpu", allocationMultiplier: "2"} in its        `nodeAllocatableResourceMappings`. If 4 devices are allocated to the claim, 		  4 * 2 CPUs would be considered as allocated and subtracted from the node's capacity.     b. A GPU device that needs additional node memory per GPU allocation would        have {ResourceName: "memory", allocationMultiplier: "2Gi"}.  Each allocated 		  GPU device instance of this type will account for 2Gi of memory.  2.  If `capacityKey` IS set: `allocationMultiplier` is multiplied by the amount of that capacity consumed. 	   The final node allocatable resource amount is `consumedCapacity[capacityKey]` * `allocationMultiplier`.     For example, if a Device's capacity "dra.example.com/cores" is consumed,     and each "core" provides 2 "cpu"s, the mapping would be:     {ResourceName: "cpu", capacityKey: "dra.example.com/cores", allocationMultiplier: "2"}.     If a claim consumes 8 "dra.example.com/cores", the CPU footprint is 8 * 2 = 16.

=head2 capacityKey

CapacityKey references a capacity name defined as a key in the `spec.devices[*].capacity` map. When this field is set, the value associated with this key in the `status.allocation.devices.results[*].consumedCapacity` map (for a specific claim allocation) determines the base quantity for the node allocatable resource. If `allocationMultiplier` is also set, it is multiplied with the base quantity. For example, if `spec.devices[*].capacity` has an entry "dra.example.com/memory": "128Gi", and this field is set to "dra.example.com/memory", then for a claim allocation that consumes { "dra.example.com/memory": "4Gi" } the base quantity for the node allocatable resource mapping will be "4Gi", and `allocationMultiplier` should be omitted or set to "1".

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
