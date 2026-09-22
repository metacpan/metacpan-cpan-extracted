package IO::K8s::Api::Lifecycle::V1alpha1::EvictionStatus;
# ABSTRACT: EvictionStatus represents the last observed status of the eviction request.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s observedGeneration => Int;


k8s requesters => ['Lifecycle::V1alpha1::Requester'];


k8s responders => ['Lifecycle::V1alpha1::ResponderStatus'];


k8s targetResponders => ['Lifecycle::V1alpha1::TargetResponder'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Lifecycle::V1alpha1::EvictionStatus - EvictionStatus represents the last observed status of the eviction request.

=head1 VERSION

version 1.108

=head2 conditions

conditions contain information about the eviction request.

Eviction specific conditions are: TargetEvicted or Failed (managed by evictionrequest-controller). - Failed means that the eviction request is no longer being processed
  by any eviction responder. This can happen if the request is canceled or if no responder
  managed to evict the target (e.g. terminate or delete a pod).
- TargetEvicted means that the target has been evicted (e.g. a pod has been terminated or deleted).

	The maximum length of the conditions list is 100.

=head2 observedGeneration

observedGeneration is Eviction's .metadata.generation observed by the evictionrequest-controller. The observed generation value cannot be negative and can only be incremented. The minimum value is 1. This field is managed by evictionrequest-controller.

=head2 requesters

requesters allow you to identify the entities, that requested the eviction of the target. If all the requesters withdraw their eviction intent, the eviction will be canceled.

The maximum length of the requesters list is 100. If this limit is exceeded, requesters with Withdrawn intent should be dropped first.

=head2 responders

responders represents the eviction process status of each declared responder.

The responder list should be the same length and have the same .name fields as .status.targetResponders. Only responders with .name that have Active state in .targetResponders[].state should be updated and can be mutated. First initialization of the list is allowed.

Each ResponderStatus is initialized by evictionrequest-controller and then managed by the designated responder.

=head2 targetResponders

targetResponders reference responders that should eventually respond to this eviction to help with the graceful eviction of a target. These responders are selected sequentially, according to their specified priority by setting the Active state to the TargetResponder .state field. The maximum number of active responders allowed is 1. Eventually each responder can end up in an Interrupted, Canceled or, Completed state. Responders should observe these states in order to navigate their lifecycle.

If the target is a pod, the field is populated from Pod's .spec.evictionResponders. Default responders may be added to the list according to the target.

Default responders: - imperative-eviction.k8s.io/evictor responder with a priority of 100 is added to the list if the
  target is a pod. It will call the imperative Eviction API (pods/<name>/eviction subresource).
  This call may not succeed due to PodDisruptionBudgets, which may block the pod termination.
  It will update the responder message and try again with a backoff.

The maximum length of the responders list is 11. The length and keys of the list cannot change once set. This field is managed by evictionrequest-controller.

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
