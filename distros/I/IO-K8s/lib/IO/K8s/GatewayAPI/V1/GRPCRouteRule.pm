package IO::K8s::GatewayAPI::V1::GRPCRouteRule;
# ABSTRACT: GRPCRouteRule defines the semantics for matching a gRPC request based on conditions (matches), processing it (filters), and forwarding the request to an API object (backendRefs).
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backendRefs => ['+IO::K8s::GatewayAPI::V1::GRPCBackendRef'];
k8s filters     => ['+IO::K8s::GatewayAPI::V1::GRPCRouteFilter'];
k8s matches     => ['+IO::K8s::GatewayAPI::V1::GRPCRouteMatch'];
k8s name        => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GRPCRouteRule - GRPCRouteRule defines the semantics for matching a gRPC request based on conditions (matches), processing it (filters), and forwarding the request to an API object (backendRefs).

=head1 VERSION

version 1.108

=head2 backendRefs

BackendRefs defines the backend(s) where matching requests should be
sent.

Failure behavior here depends on how many BackendRefs are specified and
how many are invalid.

If *all* entries in BackendRefs are invalid, and there are also no filters
specified in this route rule, *all* traffic which matches this rule MUST
receive an `UNAVAILABLE` status.

See the GRPCBackendRef definition for the rules about what makes a single
GRPCBackendRef invalid.

When a GRPCBackendRef is invalid, `UNAVAILABLE` statuses MUST be returned for
requests that would have otherwise been routed to an invalid backend. If
multiple backends are specified, and some are invalid, the proportion of
requests that would otherwise have been routed to an invalid backend
MUST receive an `UNAVAILABLE` status.

For example, if two backends are specified with equal weights, and one is
invalid, 50 percent of traffic MUST receive an `UNAVAILABLE` status.
Implementations may choose how that 50 percent is determined.

Support: Core for Kubernetes Service

Support: Implementation-specific for any other resource

Support for weight: Core

=head2 filters

Filters define the filters that are applied to requests that match
this rule.

The effects of ordering of multiple behaviors are currently unspecified.
This can change in the future based on feedback during the alpha stage.

Conformance-levels at this level are defined based on the type of filter:

- ALL core filters MUST be supported by all implementations that support
  GRPCRoute.
- Implementers are encouraged to support extended filters.
- Implementation-specific custom filters have no API guarantees across
  implementations.

Specifying the same filter multiple times is not supported unless explicitly
indicated in the filter.

If an implementation cannot support a combination of filters, it must clearly
document that limitation. In cases where incompatible or unsupported
filters are specified and cause the `Accepted` condition to be set to status
`False`, implementations may use the `IncompatibleFilters` reason to specify
this configuration error.

Support: Core

=head2 matches

Matches define conditions used for matching the rule against incoming
gRPC requests. Each match is independent, i.e. this rule will be matched
if **any** one of the matches is satisfied.

For example, take the following matches configuration:

```
matches:
- method:
    service: foo.bar
  headers:
    values:
      version: 2
- method:
    service: foo.bar.v2
```

For a request to match against this rule, it MUST satisfy
EITHER of the two conditions:

- service of foo.bar AND contains the header `version: 2`
- service of foo.bar.v2

See the documentation for GRPCRouteMatch on how to specify multiple
match conditions to be ANDed together.

If no matches are specified, the implementation MUST match every gRPC request.

Proxy or Load Balancer routing configuration generated from GRPCRoutes
MUST prioritize rules based on the following criteria, continuing on
ties. Merging MUST not be done between GRPCRoutes and HTTPRoutes.
Precedence MUST be given to the rule with the largest number of:

* Characters in a matching non-wildcard hostname.
* Characters in a matching hostname.
* Characters in a matching service.
* Characters in a matching method.
* Header matches.

If ties still exist across multiple Routes, matching precedence MUST be
determined in order of the following criteria, continuing on ties:

* The oldest Route based on creation timestamp.
* The Route appearing first in alphabetical order by
  "{namespace}/{name}".

If ties still exist within the Route that has been given precedence,
matching precedence MUST be granted to the first matching rule meeting
the above criteria.

=head2 name

Name is the name of the route rule. This name MUST be unique within a Route if it is set.

Support: Extended

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
