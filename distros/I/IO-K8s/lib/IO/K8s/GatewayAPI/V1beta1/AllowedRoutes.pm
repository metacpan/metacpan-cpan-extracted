package IO::K8s::GatewayAPI::V1beta1::AllowedRoutes;
# ABSTRACT: AllowedRoutes defines the types of routes that MAY be attached to a Listener and the trusted namespaces where those Route resources MAY be present.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s kinds      => ['+IO::K8s::GatewayAPI::V1beta1::RouteGroupKind'];
k8s namespaces => '+IO::K8s::GatewayAPI::V1beta1::RouteNamespaces', { default => {'from' => 'Same'} };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::AllowedRoutes - AllowedRoutes defines the types of routes that MAY be attached to a Listener and the trusted namespaces where those Route resources MAY be present.

=head1 VERSION

version 1.108

=head2 kinds

Kinds specifies the groups and kinds of Routes that are allowed to bind
to this Gateway Listener. When unspecified or empty, the kinds of Routes
selected are determined using the Listener protocol.

A RouteGroupKind MUST correspond to kinds of Routes that are compatible
with the application protocol specified in the Listener's Protocol field.
If an implementation does not support or recognize this resource type, it
MUST set the "ResolvedRefs" condition to False for this Listener with the
"InvalidRouteKinds" reason.

Support: Core

=head2 namespaces

Namespaces indicates namespaces from which Routes may be attached to this
Listener. This is restricted to the namespace of this Gateway by default.

Support: Core

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
