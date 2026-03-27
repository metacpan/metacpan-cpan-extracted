package IO::K8s::Api::Resource::V1alpha3::ResourceClaimStatus;
# ABSTRACT: ResourceClaimStatus tracks whether the resource has been allocated and what the result of that was.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s allocation => 'Resource::V1alpha3::AllocationResult';


k8s deallocationRequested => Bool;


k8s reservedFor => ['Resource::V1alpha3::ResourceClaimConsumerReference'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Resource::V1alpha3::ResourceClaimStatus - ResourceClaimStatus tracks whether the resource has been allocated and what the result of that was.

=head1 VERSION

version 1.100

=head2 allocation

Allocation is set once the claim has been allocated successfully.

=head2 deallocationRequested

Indicates that a claim is to be deallocated. While this is set, no new consumers may be added to ReservedFor.

This is only used if the claim needs to be deallocated by a DRA driver. That driver then must deallocate this claim and reset the field together with clearing the Allocation field.

This is an alpha field and requires enabling the DRAControlPlaneController feature gate.

=head2 reservedFor

ReservedFor indicates which entities are currently allowed to use the claim. A Pod which references a ResourceClaim which is not reserved for that Pod will not be started. A claim that is in use or might be in use because it has been reserved must not get deallocated.

In a cluster with multiple scheduler instances, two pods might get scheduled concurrently by different schedulers. When they reference the same ResourceClaim which already has reached its maximum number of consumers, only one pod can be scheduled.

Both schedulers try to add their pod to the claim.status.reservedFor field, but only the update that reaches the API server first gets stored. The other one fails with an error and the scheduler which issued it knows that it must put the pod back into the queue, waiting for the ResourceClaim to become usable again.

There can be at most 32 such reservations. This may get increased in the future, but not reduced.

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
