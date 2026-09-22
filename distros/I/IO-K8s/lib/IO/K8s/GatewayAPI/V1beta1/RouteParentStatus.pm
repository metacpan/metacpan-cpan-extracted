package IO::K8s::GatewayAPI::V1beta1::RouteParentStatus;
# ABSTRACT: RouteParentStatus describes the status of a route with respect to an associated Parent.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions     => ['Meta::V1::Condition'], { required => 'schema' };
k8s controllerName => Str, { required => 'schema', pattern => '^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\\/[A-Za-z0-9\\/\\-._~%!$&\'()*+,;=:]+$' };
k8s parentRef      => '+IO::K8s::GatewayAPI::V1beta1::ParentReference', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::RouteParentStatus - RouteParentStatus describes the status of a route with respect to an associated Parent.

=head1 VERSION

version 1.108

=head2 conditions

Conditions describes the status of the route with respect to the Gateway.
Note that the route's availability is also subject to the Gateway's own
status conditions and listener status.

If the Route's ParentRef specifies an existing Gateway that supports
Routes of this kind AND that Gateway's controller has sufficient access,
then that Gateway's controller MUST set the "Accepted" condition on the
Route, to indicate whether the route has been accepted or rejected by the
Gateway, and why.

A Route MUST be considered "Accepted" if at least one of the Route's
rules is implemented by the Gateway.

There are a number of cases where the "Accepted" condition may not be set
due to lack of controller visibility, that includes when:

* The Route refers to a nonexistent parent.
* The Route is of a type that the controller does not support.
* The Route is in a namespace to which the controller does not have access.

=head2 controllerName

ControllerName is a domain/path string that indicates the name of the
controller that wrote this status. This corresponds with the
controllerName field on GatewayClass.

Example: "example.net/gateway-controller".

The format of this field is DOMAIN "/" PATH, where DOMAIN and PATH are
valid Kubernetes names
(https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#names).

Controllers MUST populate this field when writing status. Controllers should ensure that
entries to status populated with their ControllerName are cleaned up when they are no
longer necessary.

=head2 parentRef

ParentRef corresponds with a ParentRef in the spec that this
RouteParentStatus struct describes the status of.

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
