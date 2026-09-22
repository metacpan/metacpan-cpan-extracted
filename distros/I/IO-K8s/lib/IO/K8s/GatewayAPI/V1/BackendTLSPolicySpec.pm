package IO::K8s::GatewayAPI::V1::BackendTLSPolicySpec;
# ABSTRACT: Spec defines the desired state of BackendTLSPolicy.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s options    => { Str => 1 };
k8s targetRefs => ['+IO::K8s::GatewayAPI::V1::LocalPolicyTargetReferenceWithSectionName'], { required => 'schema' };
k8s validation => '+IO::K8s::GatewayAPI::V1::BackendTLSPolicyValidation', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::BackendTLSPolicySpec - Spec defines the desired state of BackendTLSPolicy.

=head1 VERSION

version 1.108

=head2 options

Options are a list of key/value pairs to enable extended TLS
configuration for each implementation. For example, configuring the
minimum TLS version or supported cipher suites.

A set of common keys MAY be defined by the API in the future. To avoid
any ambiguity, implementation-specific definitions MUST use
domain-prefixed names, such as `example.com/my-custom-option`.
Un-prefixed names are reserved for key names defined by Gateway API.

Support: Implementation-specific

=head2 targetRefs

TargetRefs identifies an API object to apply the policy to.
Note that this config applies to the entire referenced resource
by default, but this default may change in the future to provide
a more granular application of the policy.

TargetRefs must be _distinct_. This means either that:

* They select different targets. If this is the case, then targetRef
  entries are distinct. In terms of fields, this means that the
  multi-part key defined by `group`, `kind`, and `name` must
  be unique across all targetRef entries in the BackendTLSPolicy.
* They select different sectionNames in the same target.

When more than one BackendTLSPolicy selects the same target and
sectionName, implementations MUST determine precedence using the
following criteria, continuing on ties:

* The older policy by creation timestamp takes precedence. For
  example, a policy with a creation timestamp of "2021-07-15
  01:02:03" MUST be given precedence over a policy with a
  creation timestamp of "2021-07-15 01:02:04".
* The policy appearing first in alphabetical order by {namespace}/{name}.
  For example, a policy named `foo/bar` is given precedence over a
  policy named `foo/baz`.

For any BackendTLSPolicy that does not take precedence, the
implementation MUST ensure the `Accepted` Condition is set to
`status: False`, with Reason `Conflicted`.

Implementations SHOULD NOT support more than one targetRef at this
time. Although the API technically allows for this, the current guidance
for conflict resolution and status handling is lacking. Until that can be
clarified in a future release, the safest approach is to support a single
targetRef.

Support Levels:

* Extended: Kubernetes Service referenced by backendRefs used on a Route.
  - HTTPRoute, GRPCRoute, TLSRoute with termination
  - Filters that needs a backend of type Service, like Mirror and External Authorization

* Implementation-Specific: Implementations MAY use BackendTLSPolicy for:
  - Services not referenced by any Route (e.g., infrastructure services)
  - Service mesh workload-to-service communication
  - Other resource types beyond Service

Implementations SHOULD aim to ensure that BackendTLSPolicy behavior is consistent,
even outside of the extended HTTPRoute -(backendRef) -> Service path.
They SHOULD clearly document how BackendTLSPolicy is interpreted in these
scenarios, including:
  - Which resources beyond Service are supported
  - How the policy is discovered and applied
  - Any implementation-specific semantics or restrictions

Note that this config applies to the entire referenced resource
by default, but this default may change in the future to provide
a more granular application of the policy.

=head2 validation

Validation contains backend TLS validation configuration.

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
