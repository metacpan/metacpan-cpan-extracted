package IO::K8s::GatewayAPI::V1beta1::HTTPRouteTimeouts;
# ABSTRACT: Timeouts defines the timeouts that can be configured for an HTTP request.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backendRequest => Str, { pattern => qr/^([0-9]{1,5}(h|m|s|ms)){1,4}$/ };
k8s request        => Str, { pattern => qr/^([0-9]{1,5}(h|m|s|ms)){1,4}$/ };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPRouteTimeouts - Timeouts defines the timeouts that can be configured for an HTTP request.

=head1 VERSION

version 1.108

=head2 backendRequest

BackendRequest specifies a timeout for an individual request from the gateway
to a backend. This covers the time from when the request first starts being
sent from the gateway to when the full response has been received from the backend.

Setting a timeout to the zero duration (e.g. "0s") SHOULD disable the timeout
completely. Implementations that cannot completely disable the timeout MUST
instead interpret the zero duration as the longest possible value to which
the timeout can be set.

An entire client HTTP transaction with a gateway, covered by the Request timeout,
may result in more than one call from the gateway to the destination backend,
for example, if automatic retries are supported.

The value of BackendRequest must be a Gateway API Duration string as defined by
GEP-2257.  When this field is unspecified, its behavior is implementation-specific;
when specified, the value of BackendRequest must be no more than the value of the
Request timeout (since the Request timeout encompasses the BackendRequest timeout).

Support: Extended

=head2 request

Request specifies the maximum duration for a gateway to respond to an HTTP request.
If the gateway has not been able to respond before this deadline is met, the gateway
MUST return a timeout error.

For example, setting the `rules.timeouts.request` field to the value `10s` in an
`HTTPRoute` will cause a timeout if a client request is taking longer than 10 seconds
to complete.

Setting a timeout to the zero duration (e.g. "0s") SHOULD disable the timeout
completely. Implementations that cannot completely disable the timeout MUST
instead interpret the zero duration as the longest possible value to which
the timeout can be set.

This timeout is intended to cover as close to the whole request-response transaction
as possible although an implementation MAY choose to start the timeout after the entire
request stream has been received instead of immediately after the transaction is
initiated by the client.

The value of Request is a Gateway API Duration string as defined by GEP-2257. When this
field is unspecified, request timeout behavior is implementation-specific.

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
