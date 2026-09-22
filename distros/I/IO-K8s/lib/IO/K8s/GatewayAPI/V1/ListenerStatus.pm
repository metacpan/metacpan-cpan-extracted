package IO::K8s::GatewayAPI::V1::ListenerStatus;
# ABSTRACT: ListenerStatus is the status associated with a Listener.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s attachedRoutes => Int, { required => 'schema' };
k8s conditions     => ['Meta::V1::Condition'], { required => 'schema' };
k8s name           => Str, { required => 'schema', pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s supportedKinds => ['+IO::K8s::GatewayAPI::V1::RouteGroupKind'];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::ListenerStatus - ListenerStatus is the status associated with a Listener.

=head1 VERSION

version 1.108

=head2 attachedRoutes

AttachedRoutes represents the total number of Routes that have been
successfully attached to this Listener.

Successful attachment of a Route to a Listener is based solely on the
combination of the AllowedRoutes field on the corresponding Listener
and the Route's ParentRefs field. A Route is successfully attached to
a Listener when it is selected by the Listener's AllowedRoutes field
AND the Route has a valid ParentRef selecting the whole Gateway
resource or a specific Listener as a parent resource (more detail on
attachment semantics can be found in the documentation on the various
Route kinds ParentRefs fields). Listener or Route status does not impact
successful attachment, i.e. the AttachedRoutes field count MUST be set
for Listeners, even if the Accepted condition of an individual Listener is set
to "False". The AttachedRoutes number represents the number of Routes with
the Accepted condition set to "True" that have been attached to this Listener.
Routes with any other value for the Accepted condition MUST NOT be included
in this count.

Uses for this field include troubleshooting Route attachment and
measuring blast radius/impact of changes to a Listener.

=head2 conditions

Conditions describe the current condition of this listener.

=head2 name

Name is the name of the Listener that this status corresponds to.

=head2 supportedKinds

SupportedKinds is the list indicating the Kinds supported by this
listener. This MUST represent the kinds supported by an implementation for
that Listener configuration.

If kinds are specified in Spec that are not supported, they MUST NOT
appear in this list and an implementation MUST set the "ResolvedRefs"
condition to "False" with the "InvalidRouteKinds" reason. If both valid
and invalid Route kinds are specified, the implementation MUST
reference the valid Route kinds that have been specified.

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
