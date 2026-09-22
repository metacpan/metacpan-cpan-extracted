package IO::K8s::Api::Lifecycle::V1alpha1::EvictionRequestStatus;
# ABSTRACT: EvictionRequestStatus represents the last observed status of the eviction request.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions => ['Meta::V1::Condition'];


k8s observedGeneration => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Lifecycle::V1alpha1::EvictionRequestStatus - EvictionRequestStatus represents the last observed status of the eviction request.

=head1 VERSION

version 1.108

=head2 conditions

conditions contain information about the eviction request.

EvictionRequest specific conditions are: TargetEvicted or Failed (managed by evictionrequest-controller). - Failed means that the eviction request is no longer being processed
  by any eviction responder. This can happen if the request is canceled or if no responder
  managed to evict the target (e.g. terminate or delete a pod).
- TargetEvicted means that the target has been evicted (e.g. a pod has been terminated or deleted).

These conditions can be reset if the eviction was unsuccessful and a new Eviction intent has been submitted.

The maximum length of the conditions list is 100.

=head2 observedGeneration

observedGeneration is EvictionRequest's .metadata.generation observed by the evictionrequest-controller. The observed generation value cannot be negative and can only be incremented. The minimum value is 1. This field is managed by evictionrequest-controller.

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
