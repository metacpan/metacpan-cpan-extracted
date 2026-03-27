package IO::K8s::Api::Batch::V1::JobStatus;
# ABSTRACT: JobStatus represents the current state of a Job.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s active => Int;


k8s completedIndexes => Str;


k8s completionTime => Time;


k8s conditions => ['Batch::V1::JobCondition'];


k8s failed => Int;


k8s failedIndexes => Str;


k8s ready => Int;


k8s startTime => Time;


k8s succeeded => Int;


k8s terminating => Int;


k8s uncountedTerminatedPods => 'Batch::V1::UncountedTerminatedPods';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Batch::V1::JobStatus - JobStatus represents the current state of a Job.

=head1 VERSION

version 1.100

=head2 active

The number of pending and running pods which are not terminating (without a deletionTimestamp). The value is zero for finished jobs.

=head2 completedIndexes

completedIndexes holds the completed indexes when .spec.completionMode = "Indexed" in a text format. The indexes are represented as decimal integers separated by commas. The numbers are listed in increasing order. Three or more consecutive numbers are compressed and represented by the first and last element of the series, separated by a hyphen. For example, if the completed indexes are 1, 3, 4, 5 and 7, they are represented as "1,3-5,7".

=head2 completionTime

Represents time when the job was completed. It is not guaranteed to be set in happens-before order across separate operations. It is represented in RFC3339 form and is in UTC. The completion time is set when the job finishes successfully, and only then. The value cannot be updated or removed. The value indicates the same or later point in time as the startTime field.

=head2 conditions

The latest available observations of an object's current state. When a Job fails, one of the conditions will have type "Failed" and status true. When a Job is suspended, one of the conditions will have type "Suspended" and status true; when the Job is resumed, the status of this condition will become false. When a Job is completed, one of the conditions will have type "Complete" and status true.

A job is considered finished when it is in a terminal condition, either "Complete" or "Failed". A Job cannot have both the "Complete" and "Failed" conditions. Additionally, it cannot be in the "Complete" and "FailureTarget" conditions. The "Complete", "Failed" and "FailureTarget" conditions cannot be disabled.

More info: https://kubernetes.io/docs/concepts/workloads/controllers/jobs-run-to-completion/

=head2 failed

The number of pods which reached phase Failed. The value increases monotonically.

=head2 failedIndexes

FailedIndexes holds the failed indexes when spec.backoffLimitPerIndex is set. The indexes are represented in the text format analogous as for the `completedIndexes` field, ie. they are kept as decimal integers separated by commas. The numbers are listed in increasing order. Three or more consecutive numbers are compressed and represented by the first and last element of the series, separated by a hyphen. For example, if the failed indexes are 1, 3, 4, 5 and 7, they are represented as "1,3-5,7". The set of failed indexes cannot overlap with the set of completed indexes.

This field is beta-level. It can be used when the `JobBackoffLimitPerIndex` feature gate is enabled (enabled by default).

=head2 ready

The number of active pods which have a Ready condition and are not terminating (without a deletionTimestamp).

=head2 startTime

Represents time when the job controller started processing a job. When a Job is created in the suspended state, this field is not set until the first time it is resumed. This field is reset every time a Job is resumed from suspension. It is represented in RFC3339 form and is in UTC.

Once set, the field can only be removed when the job is suspended. The field cannot be modified while the job is unsuspended or finished.

=head2 succeeded

The number of pods which reached phase Succeeded. The value increases monotonically for a given spec. However, it may decrease in reaction to scale down of elastic indexed jobs.

=head2 terminating

The number of pods which are terminating (in phase Pending or Running and have a deletionTimestamp).

This field is beta-level. The job controller populates the field when the feature gate JobPodReplacementPolicy is enabled (enabled by default).

=head2 uncountedTerminatedPods

uncountedTerminatedPods holds the UIDs of Pods that have terminated but the job controller hasn't yet accounted for in the status counters.

The job controller creates pods with a finalizer. When a pod terminates (succeeded or failed), the controller does three steps to account for it in the job status:

1. Add the pod UID to the arrays in this field. 2. Remove the pod finalizer. 3. Remove the pod UID from the arrays while increasing the corresponding counter.

Old jobs might not be tracked using this field, in which case the field remains null. The structure is empty for finished jobs.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
