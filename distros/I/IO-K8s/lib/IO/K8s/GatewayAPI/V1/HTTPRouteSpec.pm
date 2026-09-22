package IO::K8s::GatewayAPI::V1::HTTPRouteSpec;
# ABSTRACT: Spec defines the desired state of HTTPRoute.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s hostnames  => [Str], { pattern => qr/^(\*\.)?[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s parentRefs => ['+IO::K8s::GatewayAPI::V1::ParentReference'];
k8s rules      => ['+IO::K8s::GatewayAPI::V1::HTTPRouteRule'], { default => [{'matches' => [{'path' => {'type' => 'PathPrefix','value' => '/'}}]}] };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPRouteSpec - Spec defines the desired state of HTTPRoute.

=head1 VERSION

version 1.108

=head2 hostnames

Hostnames defines a set of hostnames that should match against the HTTP Host
header to select a HTTPRoute used to process the request. Implementations
MUST ignore any port value specified in the HTTP Host header while
performing a match and (absent of any applicable header modification
configuration) MUST forward this header unmodified to the backend.

Valid values for Hostnames are determined by RFC 1123 definition of a
hostname with 2 notable exceptions:

1. IPs are not allowed.
2. A hostname may be prefixed with a wildcard label (`*.`). The wildcard
   label must appear by itself as the first label.

If a hostname is specified by both the Listener and HTTPRoute, there
must be at least one intersecting hostname for the HTTPRoute to be
attached to the Listener. For example:

* A Listener with `test.example.com` as the hostname matches HTTPRoutes
  that have either not specified any hostnames, or have specified at
  least one of `test.example.com` or `*.example.com`.
* A Listener with `*.example.com` as the hostname matches HTTPRoutes
  that have either not specified any hostnames or have specified at least
  one hostname that matches the Listener hostname. For example,
  `*.example.com`, `test.example.com`, and `foo.test.example.com` would
  all match. On the other hand, `example.com` and `test.example.net` would
  not match.

Hostnames that are prefixed with a wildcard label (`*.`) are interpreted
as a suffix match. That means that a match for `*.example.com` would match
both `test.example.com`, and `foo.test.example.com`, but not `example.com`.

If both the Listener and HTTPRoute have specified hostnames, any
HTTPRoute hostnames that do not match the Listener hostname MUST be
ignored. For example, if a Listener specified `*.example.com`, and the
HTTPRoute specified `test.example.com` and `test.example.net`,
`test.example.net` must not be considered for a match.

If both the Listener and HTTPRoute have specified hostnames, and none
match with the criteria above, then the HTTPRoute is not accepted. The
implementation must raise an 'Accepted' Condition with a status of
`False` in the corresponding RouteParentStatus.

In the event that multiple HTTPRoutes specify intersecting hostnames (e.g.
overlapping wildcard matching and exact matching hostnames), precedence must
be given to rules from the HTTPRoute with the largest number of:

* Characters in a matching non-wildcard hostname.
* Characters in a matching hostname.

If ties exist across multiple Routes, the matching precedence rules for
HTTPRouteMatches takes over.

Support: Core

=head2 parentRefs

ParentRefs references the resources (usually Gateways) that a Route wants
to be attached to. Note that the referenced parent resource needs to
allow this for the attachment to be complete. For Gateways, that means
the Gateway needs to allow attachment from Routes of this kind and
namespace. For Services, that means the Service must either be in the same
namespace for a "producer" route, or the mesh implementation must support
and allow "consumer" routes for the referenced Service. ReferenceGrant is
not applicable for governing ParentRefs to Services - it is not possible to
create a "producer" route for a Service in a different namespace from the
Route.

There are two kinds of parent resources with "Core" support:

* Gateway (Gateway conformance profile)
* Service (Mesh conformance profile, ClusterIP Services only)

This API may be extended in the future to support additional kinds of parent
resources.

ParentRefs must be _distinct_. This means either that:

* They select different objects.  If this is the case, then parentRef
  entries are distinct. In terms of fields, this means that the
  multi-part key defined by `group`, `kind`, `namespace`, and `name` must
  be unique across all parentRef entries in the Route.
* They do not select different objects, but for each optional field used,
  each ParentRef that selects the same object must set the same set of
  optional fields to different values. If one ParentRef sets a
  combination of optional fields, all must set the same combination.

Some examples:

* If one ParentRef sets `sectionName`, all ParentRefs referencing the
  same object must also set `sectionName`.
* If one ParentRef sets `port`, all ParentRefs referencing the same
  object must also set `port`.
* If one ParentRef sets `sectionName` and `port`, all ParentRefs
  referencing the same object must also set `sectionName` and `port`.

It is possible to separately reference multiple distinct objects that may
be collapsed by an implementation. For example, some implementations may
choose to merge compatible Gateway Listeners together. If that is the
case, the list of routes attached to those resources should also be
merged.

Note that for ParentRefs that cross namespace boundaries, there are specific
rules. Cross-namespace references are only valid if they are explicitly
allowed by something in the namespace they are referring to. For example,
Gateway has the AllowedRoutes field, and ReferenceGrant provides a
generic way to enable other kinds of cross-namespace reference.

=head2 rules

Rules are a list of HTTP matchers, filters and actions.

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
