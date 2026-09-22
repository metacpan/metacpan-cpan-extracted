package IO::K8s::GatewayAPI::V1::TLSRouteRule;
# ABSTRACT: TLSRouteRule is the configuration for a given rule.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backendRefs => ['+IO::K8s::GatewayAPI::V1::BackendRef'], { required => 'schema' };
k8s name        => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::TLSRouteRule - TLSRouteRule is the configuration for a given rule.

=head1 VERSION

version 1.108

=head2 backendRefs

BackendRefs defines the backend(s) where matching requests should be
sent. If unspecified or invalid (refers to a nonexistent resource or
a Service with no endpoints), the rule performs no forwarding; if no
filters are specified that would result in a response being sent, the
underlying implementation must actively reject request attempts to this
backend, by rejecting the connection. Request rejections must respect
weight; if an invalid backend is requested to have 80% of requests, then
80% of requests must be rejected instead.

When a TLSRoute is attached to a listener in Terminate mode, a BackendTLSPolicy
can be used to enable re-encryption of the traffic to the backends.

Support: Core for Kubernetes Service

Support: Extended for Kubernetes ServiceImport

Support: Implementation-specific for any other resource

Support for weight: Extended

Support for BackendTLSPolicy: Extended

=head2 name

Name is the name of the route rule. This name MUST be unique within a Route if it is set.

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
