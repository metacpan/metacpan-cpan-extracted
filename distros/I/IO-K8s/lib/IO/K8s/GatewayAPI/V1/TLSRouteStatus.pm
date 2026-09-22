package IO::K8s::GatewayAPI::V1::TLSRouteStatus;
# ABSTRACT: Status defines the current state of TLSRoute.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s parents => ['+IO::K8s::GatewayAPI::V1::RouteParentStatus'], { required => 'schema' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::TLSRouteStatus - Status defines the current state of TLSRoute.

=head1 VERSION

version 1.108

=head2 parents

Parents is a list of parent resources (usually Gateways) that are
associated with the route, and the status of the route with respect to
each parent. When this route attaches to a parent, the controller that
manages the parent must add an entry to this list when the controller
first sees the route and should update the entry as appropriate when the
route or gateway is modified.

Note that parent references that cannot be resolved by an implementation
of this API will not be added to this list. Implementations of this API
can only populate Route status for the Gateways/parent resources they are
responsible for.

A maximum of 32 Gateways will be represented in this list. An empty list
means the route has not been attached to any Gateway.

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
