package IO::K8s::Api::Lifecycle::V1alpha1::Requester;
# ABSTRACT: Requester allows you to identify the entity, that requested the eviction of the target.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s intent => Str, 'required';


k8s name => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Lifecycle::V1alpha1::Requester - Requester allows you to identify the entity, that requested the eviction of the target.

=head1 VERSION

version 1.108

=head2 intent

intent specifies the action that should be taken for the specified target.

- Eviction means that the requester is interested in the eviction of the target. - Withdrawn means that the requester is no longer interested in the eviction of the target.
  If all requesters' intents are withdrawn, the eviction will be canceled.
  Cancellation consequences:
  - Inactive responders will never run.
  - Active responders are expected to cancel the eviction.
  - Completed or Interrupted responders should not take any action.

=head2 name

name allows you to identify the entity, that requested the eviction of the target.

It must be a valid domain-prefixed key (such as "acme.io/foo"). This field must be unique for each requester. This field is required.

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
