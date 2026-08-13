package IO::K8s::Api::Scheduling::V1alpha2::PodGroupStatus;
# ABSTRACT: PodGroupStatus represents information about the status of a pod group.
our $VERSION = '1.106';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s resourceClaimStatuses => ['Scheduling::V1alpha2::PodGroupResourceClaimStatus'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Scheduling::V1alpha2::PodGroupStatus - PodGroupStatus represents information about the status of a pod group.

=head1 VERSION

version 1.106

=head2 conditions

Conditions represent the latest observations of the PodGroup's state.

Known condition types:

=over 4

=item * "PodGroupScheduled": Indicates whether the scheduling requirement has been satisfied.

=item * "DisruptionTarget": Indicates whether the PodGroup is about to be terminated due to disruption such as preemption.

=back

Known reasons for the PodGroupScheduled condition:

=over 4

=item * "Unschedulable": The PodGroup cannot be scheduled due to resource constraints, affinity/anti-affinity rules, or insufficient capacity for the gang.

=item * "SchedulerError": The PodGroup cannot be scheduled due to some internal error that happened during scheduling, for example due to nodeAffinity parsing errors.

=back

Known reasons for the DisruptionTarget condition:

=over 4

=item * "PreemptionByScheduler": The PodGroup was preempted by the scheduler to make room for higher-priority PodGroups or Pods.

=back

=head2 resourceClaimStatuses

Status of resource claims.

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
