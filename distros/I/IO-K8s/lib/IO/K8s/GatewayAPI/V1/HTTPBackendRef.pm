package IO::K8s::GatewayAPI::V1::HTTPBackendRef;
# ABSTRACT: HTTPBackendRef defines how a HTTPRoute forwards a HTTP request.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s filters   => ['+IO::K8s::GatewayAPI::V1::HTTPRouteFilter'];
k8s group     => Str, { pattern => qr/^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/, default => '' };
k8s kind      => Str, { pattern => qr/^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$/, default => 'Service' };
k8s name      => Str, { required => 'schema' };
k8s namespace => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ };
k8s port      => Int, { minimum => 1, maximum => 65535 };
k8s weight    => Int, { minimum => 0, maximum => 1000000, default => 1 };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPBackendRef - HTTPBackendRef defines how a HTTPRoute forwards a HTTP request.

=head1 VERSION

version 1.108

=head2 filters

Filters defined at this level should be executed if and only if the
request is being forwarded to the backend defined here.

Support: Implementation-specific (For broader support of filters, use the
Filters field in HTTPRouteRule.)

=head2 group

Group is the group of the referent. For example, "gateway.networking.k8s.io".
When unspecified or empty string, core API group is inferred.

=head2 kind

Kind is the Kubernetes resource kind of the referent. For example
"Service".

Defaults to "Service" when not specified.

ExternalName services can refer to CNAME DNS records that may live
outside of the cluster and as such are difficult to reason about in
terms of conformance. They also may not be safe to forward to (see
CVE-2021-25740 for more information). Implementations SHOULD NOT
support ExternalName Services.

Support: Core (Services with a type other than ExternalName)

Support: Implementation-specific (Services with type ExternalName)

=head2 name

Name is the name of the referent.

=head2 namespace

Namespace is the namespace of the backend. When unspecified, the local
namespace is inferred.

Note that when a namespace different than the local namespace is specified,
a ReferenceGrant object is required in the referent namespace to allow that
namespace's owner to accept the reference. See the ReferenceGrant
documentation for details.

Support: Core

=head2 port

Port specifies the destination port number to use for this resource.
Port is required when the referent is a Kubernetes Service. In this
case, the port number is the service port number, not the target port.
For other resources, destination port might be derived from the referent
resource or this field.

=head2 weight

Weight specifies the proportion of requests forwarded to the referenced
backend. This is computed as weight/(sum of all weights in this
BackendRefs list). For non-zero values, there may be some epsilon from
the exact proportion defined here depending on the precision an
implementation supports. Weight is not a percentage and the sum of
weights does not need to equal 100.

If only one backend is specified and it has a weight greater than 0, 100%
of the traffic is forwarded to that backend. If weight is set to 0, no
traffic should be forwarded for this entry. If unspecified, weight
defaults to 1.

Support for this field varies based on the context where used.

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
