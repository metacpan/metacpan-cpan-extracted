package IO::K8s::Api::Lifecycle::V1alpha1::EvictionRequest;
# ABSTRACT: EvictionRequest defines a request that should ideally result in a graceful eviction of a .spec.target (e.g. termination of a pod). The evictionrequest-controller observes intents of all EvictionRequests and transforms them into Evictions. - .spec.requester is set as a label on the Eviction for easier lookup. - Each target can have a set of responders assigned to it. Eviction objects are observed by these responders, who implement the eviction logic and update the Eviction's status with progress. There is many-to-many relationship between EvictionRequests and Evictions in general. And many-to-one if the target is a pod. If all requesters withdraw their eviction intent for a common target, the eviction will be canceled. Deleting an EvictionRequest also counts as a withdrawal. Once all EvictionRequest of a target are removed, the corresponding Evictions are eventually garbage collected.
our $VERSION = '1.108';
use IO::K8s::APIObject;
with 'IO::K8s::Role::Namespaced';


k8s spec => 'Lifecycle::V1alpha1::EvictionRequestSpec', 'required';


k8s status => 'Lifecycle::V1alpha1::EvictionRequestStatus';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Lifecycle::V1alpha1::EvictionRequest - EvictionRequest defines a request that should ideally result in a graceful eviction of a .spec.target (e.g. termination of a pod). The evictionrequest-controller observes intents of all EvictionRequests and transforms them into Evictions. - .spec.requester is set as a label on the Eviction for easier lookup. - Each target can have a set of responders assigned to it. Eviction objects are observed by these responders, who implement the eviction logic and update the Eviction's status with progress. There is many-to-many relationship between EvictionRequests and Evictions in general. And many-to-one if the target is a pod. If all requesters withdraw their eviction intent for a common target, the eviction will be canceled. Deleting an EvictionRequest also counts as a withdrawal. Once all EvictionRequest of a target are removed, the corresponding Evictions are eventually garbage collected.

=head1 VERSION

version 1.108

=head1 DESCRIPTION

EvictionRequest defines a request that should ideally result in a graceful eviction of a .spec.target (e.g. termination of a pod).

The evictionrequest-controller observes intents of all EvictionRequests and transforms them into Evictions.
  - .spec.requester is set as a label on the Eviction for easier lookup.
  - Each target can have a set of responders assigned to it. Eviction objects are observed by
    these responders, who implement the eviction logic and update the Eviction's status with
    progress.

There is many-to-many relationship between EvictionRequests and Evictions in general. And many-to-one if the target is a  pod.

If all requesters withdraw their eviction intent for a common target, the eviction will be canceled. Deleting an EvictionRequest also counts as a withdrawal. Once all EvictionRequest of a target are removed, the corresponding Evictions are eventually garbage collected.

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 spec

spec defines the eviction request specification. https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head2 status

status represents the most recently observed status of the eviction request. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.37/#evictionrequest-v1alpha1-lifecycle.k8s.io>

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
