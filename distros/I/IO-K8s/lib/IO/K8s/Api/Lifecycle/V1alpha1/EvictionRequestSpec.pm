package IO::K8s::Api::Lifecycle::V1alpha1::EvictionRequestSpec;
# ABSTRACT: EvictionRequestSpec is a specification of an EvictionRequest.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s intent => Str, 'required';


k8s requester => Str, 'required';


k8s target => 'Lifecycle::V1alpha1::EvictionRequestTarget', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Lifecycle::V1alpha1::EvictionRequestSpec - EvictionRequestSpec is a specification of an EvictionRequest.

=head1 VERSION

version 1.108

=head2 intent

intent specifies the action that should be taken for the specified target.

- Eviction means that the requester is interested in the eviction of the target. - Withdrawn means that the requester is no longer interested in the eviction of the target.
  If all requesters' intents are withdrawn for a common target, the eviction will be canceled.
  Cancellation consequences:
  - Inactive responders will never run.
  - Active responders are expected to cancel the eviction.
  - Completed or Interrupted responders should not take any action.

=head2 requester

requester allows you to identify the entity, that requested the eviction of the target.

It must be a valid domain-prefixed key (such as "acme.io/foo"). Domain names *.k8s.io and *.kubernetes.io are reserved. This field is required and immutable.

=head2 target

target contains a reference to an object (e.g. a pod) that should be evicted. This field is required and immutable.

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
