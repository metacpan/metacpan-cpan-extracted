package IO::K8s::Api::Scheduling::V1alpha3::PodGroupSpec;
# ABSTRACT: PodGroupSpec defines the desired state of a PodGroup.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s disruptionMode => 'Scheduling::V1alpha3::DisruptionMode';


k8s parentCompositePodGroupName => Str;


k8s preemptionPolicy => Str;


k8s priority => Int;


k8s priorityClassName => Str;


k8s resourceClaims => ['Scheduling::V1alpha3::PodGroupResourceClaim'];


k8s schedulingConstraints => 'Scheduling::V1alpha3::PodGroupSchedulingConstraints';


k8s schedulingPolicy => 'Scheduling::V1alpha3::PodGroupSchedulingPolicy', 'required';


k8s workloadRef => 'Scheduling::V1alpha3::WorkloadReference';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha3::PodGroupSpec - PodGroupSpec defines the desired state of a PodGroup.

=head1 VERSION

version 1.108

=head2 disruptionMode

disruptionMode defines the mode in which a given PodGroup can be disrupted. Controllers are expected to fill this field by copying it from a PodGroupTemplate. One of Single, All. Defaults to Single if unset. This field is immutable.

=head2 parentCompositePodGroupName

parentCompositePodGroupName contains the name of the parent composite pod group within the same namespace as this pod group. If it's nil, then this pod group is a root of a workload's hierarchy. This field is used only when the CompositePodGroup feature gate is enabled. This field is immutable.

=head2 preemptionPolicy

preemptionPolicy is the Policy for preempting pods/podgroups with lower priority. One of Never, PreemptLowerPriority. Defaults to PreemptLowerPriority if unset. When Priority Admission Controller is enabled, it populates this field from PriorityClassName, and defaults to PreemptLowerPriority if value is unset in PriorityClass. This field is immutable. This field is available only when the PodGroupPreemptionPolicy feature gate is enabled.

=head2 priority

priority is the value of priority of this pod group. Various system components use this field to find the priority of the pod group. When Priority Admission Controller is enabled, it prevents users from setting this field. The admission controller populates this field from PriorityClassName. The higher the value, the higher the priority. This field is immutable.

=head2 priorityClassName

priorityClassName defines the priority that should be considered when scheduling this pod group. Controllers are expected to fill this field by copying it from a PodGroupTemplate. Otherwise, it is validated and resolved similarly to the PriorityClassName on PodGroupTemplate (i.e. if no priority class is specified, admission control can set this to the global default priority class if it exists. Otherwise, the pod group's priority will be zero). This field is immutable.

=head2 resourceClaims

resourceClaims defines which ResourceClaims may be shared among Pods in the group. Pods consume the devices allocated to a PodGroup's claim by defining a claim in its own Spec.ResourceClaims that matches the PodGroup's claim exactly. The claim must have the same name and refer to the same ResourceClaim or ResourceClaimTemplate.

This is a beta-level field and requires that the DRAWorkloadResourceClaims feature gate is enabled.

This field is immutable.

=head2 schedulingConstraints

schedulingConstraints defines optional scheduling constraints (e.g. topology) for this PodGroup. Controllers are expected to fill this field by copying it from a PodGroupTemplate. This field is immutable. This field is only available when the TopologyAwareWorkloadScheduling feature gate is enabled.

=head2 schedulingPolicy

schedulingPolicy defines the scheduling policy for this instance of the PodGroup. Controllers are expected to fill this field by copying it from a PodGroupTemplate.

=head2 workloadRef

workloadRef references an optional PodGroup template within the Workload object that was used to create the PodGroup. This field is immutable.

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
