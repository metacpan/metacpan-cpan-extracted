package IO::K8s::GatewayAPI::V1beta1::HTTPRouteRule;
# ABSTRACT: HTTPRouteRule defines semantics for matching an HTTP request based on conditions (matches), processing it (filters), and forwarding the request to an API object (backendRefs).
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backendRefs => ['+IO::K8s::GatewayAPI::V1beta1::HTTPBackendRef'];
k8s filters     => ['+IO::K8s::GatewayAPI::V1beta1::HTTPRouteFilter'];
k8s matches     => ['+IO::K8s::GatewayAPI::V1beta1::HTTPRouteMatch'], { default => [{'path' => {'type' => 'PathPrefix','value' => '/'}}] };
k8s name        => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s timeouts    => '+IO::K8s::GatewayAPI::V1beta1::HTTPRouteTimeouts';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPRouteRule - HTTPRouteRule defines semantics for matching an HTTP request based on conditions (matches), processing it (filters), and forwarding the request to an API object (backendRefs).

=head1 VERSION

version 1.108

=head2 backendRefs

BackendRefs defines the backend(s) where matching requests should be
sent.

Failure behavior here depends on how many BackendRefs are specified and
how many are invalid.

If *all* entries in BackendRefs are invalid, and there are also no filters
specified in this route rule, *all* traffic which matches this rule MUST
receive a 500 status code.

See the HTTPBackendRef definition for the rules about what makes a single
HTTPBackendRef invalid.

When a HTTPBackendRef is invalid, 500 status codes MUST be returned for
requests that would have otherwise been routed to an invalid backend. If
multiple backends are specified, and some are invalid, the proportion of
requests that would otherwise have been routed to an invalid backend
MUST receive a 500 status code.

For example, if two backends are specified with equal weights, and one is
invalid, 50 percent of traffic must receive a 500. Implementations may
choose how that 50 percent is determined.

When a HTTPBackendRef refers to a Service that has no ready endpoints,
implementations SHOULD return a 503 for requests to that backend instead.
If an implementation chooses to do this, all of the above rules for 500 responses
MUST also apply for responses that return a 503.

Support: Core for Kubernetes Service

Support: Extended for Kubernetes ServiceImport

Support: Implementation-specific for any other resource

Support for weight: Core

=head2 filters

Filters define the filters that are applied to requests that match
this rule.

Wherever possible, implementations SHOULD implement filters in the order
they are specified.

Implementations MAY choose to implement this ordering strictly, rejecting
any combination or order of filters that cannot be supported. If implementations
choose a strict interpretation of filter ordering, they MUST clearly document
that behavior.

To reject an invalid combination or order of filters, implementations SHOULD
consider the Route Rules with this configuration invalid. If all Route Rules
in a Route are invalid, the entire Route would be considered invalid. If only
a portion of Route Rules are invalid, implementations MUST set the
"PartiallyInvalid" condition for the Route.

Conformance-levels at this level are defined based on the type of filter:

- ALL core filters MUST be supported by all implementations.
- Implementers are encouraged to support extended filters.
- Implementation-specific custom filters have no API guarantees across
  implementations.

Specifying the same filter multiple times is not supported unless explicitly
indicated in the filter.

All filters are expected to be compatible with each other except for the
URLRewrite and RequestRedirect filters, which may not be combined. If an
implementation cannot support other combinations of filters, they must clearly
document that limitation. In cases where incompatible or unsupported
filters are specified and cause the `Accepted` condition to be set to status
`False`, implementations may use the `IncompatibleFilters` reason to specify
this configuration error.

Support: Core

=head2 matches

Matches define conditions used for matching the rule against incoming
HTTP requests. Each match is independent, i.e. this rule will be matched
if **any** one of the matches is satisfied.

For example, take the following matches configuration:

```
matches:
- path:
    value: "/foo"
  headers:
  - name: "version"
    value: "v2"
- path:
    value: "/v2/foo"
```

For a request to match against this rule, a request must satisfy
EITHER of the two conditions:

- path prefixed with `/foo` AND contains the header `version: v2`
- path prefix of `/v2/foo`

See the documentation for HTTPRouteMatch on how to specify multiple
match conditions that should be ANDed together.

If no matches are specified, the default is a prefix
path match on "/", which has the effect of matching every
HTTP request.

Proxy or Load Balancer routing configuration generated from HTTPRoutes
MUST prioritize matches based on the following criteria, continuing on
ties. Across all rules specified on applicable Routes, precedence must be
given to the match having:

* "Exact" path match.
* "Prefix" path match with largest number of characters.
* Method match.
* Largest number of header matches.
* Largest number of query param matches.

Note: The precedence of RegularExpression path matches are implementation-specific.

If ties still exist across multiple Routes, matching precedence MUST be
determined in order of the following criteria, continuing on ties:

* The oldest Route based on creation timestamp.
* The Route appearing first in alphabetical order by
  "{namespace}/{name}".

If ties still exist within an HTTPRoute, matching precedence MUST be granted
to the FIRST matching rule (in list order) with a match meeting the above
criteria.

When no rules matching a request have been successfully attached to the
parent a request is coming from, a HTTP 404 status code MUST be returned.

=head2 name

Name is the name of the route rule. This name MUST be unique within a Route if it is set.

Support: Extended

=head2 timeouts

Timeouts defines the timeouts that can be configured for an HTTP request.

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
