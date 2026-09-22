package IO::K8s::GatewayAPI::V1::ListenerSetSpec;
# ABSTRACT: Spec defines the desired state of ListenerSet.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s listeners => ['+IO::K8s::GatewayAPI::V1::ListenerEntry'], { required => 'schema' };
k8s parentRef => '+IO::K8s::GatewayAPI::V1::ParentGatewayReference', { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::ListenerSetSpec - Spec defines the desired state of ListenerSet.

=head1 VERSION

version 1.108

=head2 listeners

Listeners associated with this ListenerSet. Listeners define
logical endpoints that are bound on this referenced parent Gateway's addresses.

Listeners in a `Gateway` and their attached `ListenerSets` are concatenated
as a list when programming the underlying infrastructure. Each listener
name does not need to be unique across the Gateway and ListenerSets.
See ListenerEntry.Name for more details.

Implementations MUST treat the parent Gateway as having the merged
list of all listeners from itself and attached ListenerSets using
the following precedence:

1. "parent" Gateway
2. ListenerSet ordered by creation time (oldest first)
3. ListenerSet ordered alphabetically by "{namespace}/{name}".

An implementation MAY reject listeners by setting the ListenerEntryStatus
`Accepted` condition to False with the Reason `TooManyListeners`

If a listener has a conflict, this will be reported in the
Status.ListenerEntryStatus setting the `Conflicted` condition to True.

Implementations SHOULD be cautious about what information from the
parent or siblings are reported to avoid accidentally leaking
sensitive information that the child would not otherwise have access
to. This can include contents of secrets etc.

=head2 parentRef

ParentRef references the Gateway that the listeners are attached to.

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
