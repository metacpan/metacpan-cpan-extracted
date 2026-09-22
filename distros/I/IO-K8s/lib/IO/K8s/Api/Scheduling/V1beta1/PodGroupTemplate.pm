package IO::K8s::Api::Scheduling::V1beta1::PodGroupTemplate;
# ABSTRACT: PodGroupTemplate represents a template for a set of pods with a scheduling policy.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s disruptionMode => 'Scheduling::V1beta1::DisruptionMode';


k8s name => Str, 'required';


k8s preemptionPolicy => Str;


k8s priority => Int;


k8s priorityClassName => Str;


k8s resourceClaims => ['Scheduling::V1beta1::PodGroupResourceClaim'];


k8s schedulingConstraints => 'Scheduling::V1beta1::PodGroupSchedulingConstraints';


k8s schedulingPolicy => 'Scheduling::V1beta1::PodGroupSchedulingPolicy', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1beta1::PodGroupTemplate - PodGroupTemplate represents a template for a set of pods with a scheduling policy.

=head1 VERSION

version 1.108

=head2 disruptionMode

disruptionMode defines the mode in which a given PodGroup can be disrupted. One of Single, All. This field is immutable.

=head2 name

name is a unique identifier for the PodGroupTemplate within the Workload. It must be a DNS label. This field is immutable.

=head2 preemptionPolicy

preemptionPolicy is the Policy for preempting pods/podgroups with lower priority. One of Never, PreemptLowerPriority. This field is immutable. This field is available only when the PodGroupPreemptionPolicy feature gate is enabled.

=head2 priority

priority is the value of priority of pod groups created from this template. Various system components use this field to find the priority of the pod group. The higher the value, the higher the priority. This field is immutable.

=head2 priorityClassName

priorityClassName indicates the priority that should be considered when scheduling a pod group created from this template. This field is immutable.

=head2 resourceClaims

resourceClaims defines which ResourceClaims may be shared among Pods in the group. Pods consume the devices allocated to a PodGroup's claim by defining a claim in its own Spec.ResourceClaims that matches the PodGroup's claim exactly. The claim must have the same name and refer to the same ResourceClaim or ResourceClaimTemplate.

This is a beta-level field and requires that the DRAWorkloadResourceClaims feature gate is enabled.

This field is immutable.

=head2 schedulingConstraints

schedulingConstraints defines optional scheduling constraints (e.g. topology) for this PodGroupTemplate. This field is only available when the TopologyAwareWorkloadScheduling feature gate is enabled. This field is immutable.

=head2 schedulingPolicy

schedulingPolicy defines the scheduling policy for this PodGroupTemplate.

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
