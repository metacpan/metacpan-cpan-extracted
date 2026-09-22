package IO::K8s::Api::Scheduling::V1beta1::CompositePodGroupTemplate;
# ABSTRACT: CompositePodGroupTemplate represents a template for a CompositePodGroup with a scheduling policy.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s compositePodGroupTemplates => ['Scheduling::V1beta1::CompositePodGroupTemplate'];


k8s disruptionMode => 'Scheduling::V1beta1::CompositeDisruptionMode';


k8s name => Str, 'required';


k8s podGroupTemplates => ['Scheduling::V1beta1::PodGroupTemplate'];


k8s preemptionPolicy => Str;


k8s priority => Int;


k8s priorityClassName => Str;


k8s schedulingConstraints => 'Scheduling::V1beta1::CompositePodGroupSchedulingConstraints';


k8s schedulingPolicy => 'Scheduling::V1beta1::CompositePodGroupSchedulingPolicy', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1beta1::CompositePodGroupTemplate - CompositePodGroupTemplate represents a template for a CompositePodGroup with a scheduling policy.

=head1 VERSION

version 1.108

=head2 compositePodGroupTemplates

compositePodGroupTemplates is the list of templates for children CompositePodGroups. The maximum number of templates is 8. At least one entry in CompositePodGroupTemplates or PodGroupTemplates must be set.

=head2 disruptionMode

disruptionMode defines the mode in which a given CompositePodGroup can be disrupted. One of Single, All. This field is immutable.

=head2 name

name is a unique identifier for the CompositePodGroupTemplate within the Workload. It must be a DNS label. This field is required.

=head2 podGroupTemplates

podGroupTemplates is the list of templates for children PodGroups. The maximum number of templates is 8. At least one entry in CompositePodGroupTemplates or PodGroupTemplates must be set.

=head2 preemptionPolicy

preemptionPolicy is the Policy for preempting pods/podgroups with lower priority. One of Never, PreemptLowerPriority. This field is immutable. This field is available only when the PodGroupPreemptionPolicy feature gate is enabled.

=head2 priority

priority is the value of priority of composite pod groups created from this template. Various system components use this field to find the priority of the composite pod group. When Priority Admission Controller is enabled, it prevents users from setting this field. The admission controller populates this field from PriorityClassName. The higher the value, the higher the priority. This field is immutable.

=head2 priorityClassName

priorityClassName indicates the priority that should be considered when scheduling a composite pod group created from this template. If no priority class is specified, admission control can set this to the global default priority class if it exists. Otherwise, composite pod groups created from this template will have the priority set to zero. This field is immutable.

=head2 schedulingConstraints

schedulingConstraints defines optional scheduling constraints (e.g. topology) for this CompositePodGroupTemplate. This field is immutable.

=head2 schedulingPolicy

schedulingPolicy defines the scheduling policy for this template.

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
