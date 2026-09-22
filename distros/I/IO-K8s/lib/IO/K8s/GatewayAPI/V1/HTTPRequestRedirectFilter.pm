package IO::K8s::GatewayAPI::V1::HTTPRequestRedirectFilter;
# ABSTRACT: RequestRedirect defines a schema for a filter that responds to the request with an HTTP redirection.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s hostname   => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s path       => '+IO::K8s::GatewayAPI::V1::HTTPPathModifier';
k8s port       => Int, { minimum => 1, maximum => 65535 };
k8s scheme     => Str, { enum => [qw(http https)] };
k8s statusCode => Int, { enum => [qw(301 302 303 307 308)], default => 302 };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPRequestRedirectFilter - RequestRedirect defines a schema for a filter that responds to the request with an HTTP redirection.

=head1 VERSION

version 1.108

=head2 hostname

Hostname is the hostname to be used in the value of the `Location`
header in the response.
When empty, the hostname in the `Host` header of the request is used.

Support: Core

=head2 path

Path defines parameters used to modify the path of the incoming request.
The modified path is then used to construct the `Location` header. When
empty, the request path is used as-is.

Support: Extended

=head2 port

Port is the port to be used in the value of the `Location`
header in the response.

If no port is specified, the redirect port MUST be derived using the
following rules:

* If redirect scheme is not-empty, the redirect port MUST be the well-known
  port associated with the redirect scheme. Specifically "http" to port 80
  and "https" to port 443. If the redirect scheme does not have a
  well-known port, the listener port of the Gateway SHOULD be used.
* If redirect scheme is empty, the redirect port MUST be the Gateway
  Listener port.

Implementations SHOULD NOT add the port number in the 'Location'
header in the following cases:

* A Location header that will use HTTP (whether that is determined via
  the Listener protocol or the Scheme field) _and_ use port 80.
* A Location header that will use HTTPS (whether that is determined via
  the Listener protocol or the Scheme field) _and_ use port 443.

Support: Extended

=head2 scheme

Scheme is the scheme to be used in the value of the `Location` header in
the response. When empty, the scheme of the request is used.

Scheme redirects can affect the port of the redirect, for more information,
refer to the documentation for the port field of this filter.

Note that values may be added to this enum, implementations
must ensure that unknown values will not cause a crash.

Unknown values here must result in the implementation setting the
Accepted Condition for the Route to `status: False`, with a
Reason of `UnsupportedValue`.

Support: Extended

=head2 statusCode

StatusCode is the HTTP status code to be used in response.

Note that values may be added to this enum, implementations
must ensure that unknown values will not cause a crash.

Unknown values here must result in the implementation setting the
Accepted Condition for the Route to `status: False`, with a
Reason of `UnsupportedValue`.

Support: Core

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
