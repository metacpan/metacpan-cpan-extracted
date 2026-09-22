package IO::K8s::GatewayAPI::V1beta1::HTTPRouteFilter;
# ABSTRACT: HTTPRouteFilter defines processing steps that must be completed during the request or response lifecycle.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cors                   => '+IO::K8s::GatewayAPI::V1beta1::HTTPCORSFilter';
k8s extensionRef           => '+IO::K8s::GatewayAPI::V1beta1::LocalObjectReference';
k8s requestHeaderModifier  => '+IO::K8s::GatewayAPI::V1beta1::HTTPHeaderFilter';
k8s requestMirror          => '+IO::K8s::GatewayAPI::V1beta1::HTTPRequestMirrorFilter';
k8s requestRedirect        => '+IO::K8s::GatewayAPI::V1beta1::HTTPRequestRedirectFilter';
k8s responseHeaderModifier => '+IO::K8s::GatewayAPI::V1beta1::HTTPHeaderFilter';
k8s type                   => Str, { required => 'schema', enum => [qw(RequestHeaderModifier ResponseHeaderModifier RequestMirror RequestRedirect URLRewrite ExtensionRef CORS)] };
k8s urlRewrite             => '+IO::K8s::GatewayAPI::V1beta1::HTTPURLRewriteFilter';









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPRouteFilter - HTTPRouteFilter defines processing steps that must be completed during the request or response lifecycle.

=head1 VERSION

version 1.108

=head2 cors

CORS defines a schema for a filter that responds to the
cross-origin request based on HTTP response header.

Support: Extended

=head2 extensionRef

ExtensionRef is an optional, implementation-specific extension to the
"filter" behavior.  For example, resource "myroutefilter" in group
"networking.example.net"). ExtensionRef MUST NOT be used for core and
extended filters.

This filter can be used multiple times within the same rule.

Support: Implementation-specific

=head2 requestHeaderModifier

RequestHeaderModifier defines a schema for a filter that modifies request
headers.

Support: Core

=head2 requestMirror

RequestMirror defines a schema for a filter that mirrors requests.
Requests are sent to the specified destination, but responses from
that destination are ignored.

This filter can be used multiple times within the same rule. Note that
not all implementations will be able to support mirroring to multiple
backends.

Support: Extended

=head2 requestRedirect

RequestRedirect defines a schema for a filter that responds to the
request with an HTTP redirection.

Support: Core

=head2 responseHeaderModifier

ResponseHeaderModifier defines a schema for a filter that modifies response
headers.

Support: Extended

=head2 type

Type identifies the type of filter to apply. As with other API fields,
types are classified into three conformance levels:

- Core: Filter types and their corresponding configuration defined by
  "Support: Core" in this package, e.g. "RequestHeaderModifier". All
  implementations must support core filters.

- Extended: Filter types and their corresponding configuration defined by
  "Support: Extended" in this package, e.g. "RequestMirror". Implementers
  are encouraged to support extended filters.

- Implementation-specific: Filters that are defined and supported by
  specific vendors.
  In the future, filters showing convergence in behavior across multiple
  implementations will be considered for inclusion in extended or core
  conformance levels. Filter-specific configuration for such filters
  is specified using the ExtensionRef field. `Type` should be set to
  "ExtensionRef" for custom filters.

Implementers are encouraged to define custom implementation types to
extend the core API with implementation-specific behavior.

If a reference to a custom filter type cannot be resolved, the filter
MUST NOT be skipped. Instead, requests that would have been processed by
that filter MUST receive a HTTP error response.

Note that values may be added to this enum, implementations
must ensure that unknown values will not cause a crash.

Unknown values here must result in the implementation setting the
Accepted Condition for the Route to `status: False`, with a
Reason of `UnsupportedValue`.

=head2 urlRewrite

URLRewrite defines a schema for a filter that modifies a request during forwarding.

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
