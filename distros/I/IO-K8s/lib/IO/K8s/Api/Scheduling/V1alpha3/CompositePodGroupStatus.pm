package IO::K8s::Api::Scheduling::V1alpha3::CompositePodGroupStatus;
# ABSTRACT: CompositePodGroupStatus represents information about the status of a composite pod group.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha3::CompositePodGroupStatus - CompositePodGroupStatus represents information about the status of a composite pod group.

=head1 VERSION

version 1.108

=head2 conditions

conditions represent the latest observations of the CompositePodGroup's state.

Known condition types: - "CompositePodGroupInitiallyScheduled": Indicates whether the overall scheduling requirement
  for the subtree under this CompositePodGroup has been satisfied. Once this condition
  transitions to True, it serves as a terminal state and will never revert to False,
  even if pods are subsequently deleted and group constraints are no longer met.
- "DisruptionTarget": Indicates whether the CompositePodGroup is about to be terminated
  due to disruption such as preemption.

Known reasons for the CompositePodGroupInitiallyScheduled condition: - "Unschedulable": The CompositePodGroup's subtree could not be placed due to resource constraints,
  affinity/anti-affinity, or topological constraints.
- "SchedulerError": The CompositePodGroup cannot be scheduled due to some internal error
  that occurred during scheduling.
- "Invalid": Set to True when kube-scheduler detects an invalid group layout during
  runtime validation. The `message` field details the specific layout violation (such as
  a detected cycle, exceeding the maximum depth of 4, or referencing multiple distinct Workloads).

Known reasons for the DisruptionTarget condition: - "PreemptionByScheduler": The CompositePodGroup was targeted by the scheduler's preemption loop
  to free up capacity for higher-priority preemptors.

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
