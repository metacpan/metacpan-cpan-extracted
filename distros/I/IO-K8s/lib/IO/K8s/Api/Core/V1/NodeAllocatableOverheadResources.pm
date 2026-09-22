package IO::K8s::Api::Core::V1::NodeAllocatableOverheadResources;
# ABSTRACT: NodeAllocatableOverheadResources describes auxiliary overhead resource allocations.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s perContainer => Quantity;


k8s perPod => Quantity;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::NodeAllocatableOverheadResources - NodeAllocatableOverheadResources describes auxiliary overhead resource allocations.

=head1 VERSION

version 1.108

=head2 name

Name is the name of the resource (e.g., cpu, memory).

=head2 perContainer

PerContainer is the variable overhead quantity applied for each container referencing the claim. The container references are recorded in `nodeAllocatableResourceClaimStatuses.containers`. The total overhead quantity allocated for the claim is computed as: Quantity = PerPod + (PerContainer * NumReferences) Kubelet accounts for this overhead in cgroups: - Pod-level cgroup (requests and limits): Kubelet adds PerPod + (PerContainer * NumReferences). - Container-level cgroup (limits only): Kubelet adds PerPod + PerContainer for each referencing container. This allows any single container to access the pod-level overhead, while the parent cgroup caps the total usage to account for PerPod exactly once. At least one of PerPod or PerContainer must be specified. Specifying neither is an invalid configuration.

=head2 perPod

PerPod is the flat overhead quantity allocated per pod. Adding to each container limit allows individual containers to utilize the overhead, while the parent pod-level cgroup limit caps the total usage at the pod boundary where the overhead is accounted for exactly once. At least one of PerPod or PerContainer must be specified. Specifying neither is an invalid configuration.

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
