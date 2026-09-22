package IO::K8s::GatewayAPI::V1beta1::HTTPRequestMirrorFilter;
# ABSTRACT: RequestMirror defines a schema for a filter that mirrors requests.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backendRef => '+IO::K8s::GatewayAPI::V1beta1::BackendObjectReference', { required => 'schema' };
k8s fraction   => '+IO::K8s::GatewayAPI::V1beta1::Fraction';
k8s percent    => Int, { minimum => 0, maximum => 100 };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPRequestMirrorFilter - RequestMirror defines a schema for a filter that mirrors requests.

=head1 VERSION

version 1.108

=head2 backendRef

BackendRef references a resource where mirrored requests are sent.

Mirrored requests must be sent only to a single destination endpoint
within this BackendRef, irrespective of how many endpoints are present
within this BackendRef.

If the referent cannot be found, this BackendRef is invalid and must be
dropped from the Gateway. The controller must ensure the "ResolvedRefs"
condition on the Route status is set to `status: False` and not configure
this backend in the underlying implementation.

If there is a cross-namespace reference to an *existing* object
that is not allowed by a ReferenceGrant, the controller must ensure the
"ResolvedRefs"  condition on the Route is set to `status: False`,
with the "RefNotPermitted" reason and not configure this backend in the
underlying implementation.

In either error case, the Message of the `ResolvedRefs` Condition
should be used to provide more detail about the problem.

Support: Extended for Kubernetes Service

Support: Implementation-specific for any other resource

If the backend service requires TLS, use BackendTLSPolicy to tell the
implementation to supply the TLS details to be used to connect to that
backend.

=head2 fraction

Fraction represents the fraction of requests that should be
mirrored to BackendRef.

Only one of Fraction or Percent may be specified. If neither field
is specified, 100% of requests will be mirrored.

=head2 percent

Percent represents the percentage of requests that should be
mirrored to BackendRef. Its minimum value is 0 (indicating 0% of
requests) and its maximum value is 100 (indicating 100% of requests).

Only one of Fraction or Percent may be specified. If neither field
is specified, 100% of requests will be mirrored.

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
