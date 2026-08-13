package IO::K8s::Api::Scheduling::V1alpha2::PodGroupSpec;
# ABSTRACT: PodGroupSpec defines the desired state of a PodGroup.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s disruptionMode => Str;


k8s podGroupTemplateRef => 'Scheduling::V1alpha2::PodGroupTemplateReference';


k8s priority => Int;


k8s priorityClassName => Str;


k8s resourceClaims => ['Scheduling::V1alpha2::PodGroupResourceClaim'];


k8s schedulingConstraints => 'Scheduling::V1alpha2::PodGroupSchedulingConstraints';


k8s schedulingPolicy => 'Scheduling::V1alpha2::PodGroupSchedulingPolicy', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha2::PodGroupSpec - PodGroupSpec defines the desired state of a PodGroup.

=head1 VERSION

version 1.106

=head2 disruptionMode

DisruptionMode defines the mode in which a given PodGroup can be disrupted. Controllers are expected to fill this field by copying it from a PodGroupTemplate. One of Pod, PodGroup. Defaults to Pod if unset. This field is immutable. This field is available only when the WorkloadAwarePreemption feature gate is enabled.

Possible enum values:

=over 4

=item * C<"Pod"> means that individual pods can be disrupted or preempted independently. It doesn't depend on exact set of pods currently running in this PodGroup.

=item * C<"PodGroup"> means that the whole PodGroup needs to be disrupted or preempted together.

=back

=head2 podGroupTemplateRef

PodGroupTemplateRef references an optional PodGroup template within other object (e.g. Workload) that was used to create the PodGroup. This field is immutable.

=head2 priority

Priority is the value of priority of this pod group. Various system components use this field to find the priority of the pod group. When Priority Admission Controller is enabled, it prevents users from setting this field. The admission controller populates this field from PriorityClassName. The higher the value, the higher the priority. This field is immutable. This field is available only when the WorkloadAwarePreemption feature gate is enabled.

=head2 priorityClassName

PriorityClassName defines the priority that should be considered when scheduling this pod group. Controllers are expected to fill this field by copying it from a PodGroupTemplate. Otherwise, it is validated and resolved similarly to the PriorityClassName on PodGroupTemplate (i.e. if no priority class is specified, admission control can set this to the global default priority class if it exists. Otherwise, the pod group's priority will be zero). This field is immutable. This field is available only when the WorkloadAwarePreemption feature gate is enabled.

=head2 resourceClaims

ResourceClaims defines which ResourceClaims may be shared among Pods in the group. Pods consume the devices allocated to a PodGroup's claim by defining a claim in its own Spec.ResourceClaims that matches the PodGroup's claim exactly. The claim must have the same name and refer to the same ResourceClaim or ResourceClaimTemplate.

This is an alpha-level field and requires that the DRAWorkloadResourceClaims feature gate is enabled.

This field is immutable.

=head2 schedulingConstraints

SchedulingConstraints defines optional scheduling constraints (e.g. topology) for this PodGroup. Controllers are expected to fill this field by copying it from a PodGroupTemplate. This field is immutable. This field is only available when the TopologyAwareWorkloadScheduling feature gate is enabled.

=head2 schedulingPolicy

SchedulingPolicy defines the scheduling policy for this instance of the PodGroup. Controllers are expected to fill this field by copying it from a PodGroupTemplate. This field is immutable.

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
