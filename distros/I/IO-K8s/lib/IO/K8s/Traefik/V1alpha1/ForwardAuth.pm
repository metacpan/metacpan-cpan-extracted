package IO::K8s::Traefik::V1alpha1::ForwardAuth;
# ABSTRACT: ForwardAuth holds the forward auth middleware configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addAuthCookiesToResponse => [Str];
k8s address                  => Str;
k8s authRequestHeaders       => [Str];
k8s authResponseHeaders      => [Str];
k8s authResponseHeadersRegex => Str;
k8s authSigninURL            => Str;
k8s forwardBody              => Bool;
k8s headerField              => Str;
k8s maxBodySize              => Int;
k8s maxResponseBodySize      => Int;
k8s preserveLocationHeader   => Bool;
k8s preserveRequestMethod    => Bool;
k8s tls                      => '+IO::K8s::Traefik::V1alpha1::ClientTLSWithCAOptional';
k8s trustForwardHeader       => Bool;















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::ForwardAuth - ForwardAuth holds the forward auth middleware configuration.

=head1 VERSION

version 1.108

=head2 addAuthCookiesToResponse

AddAuthCookiesToResponse defines the list of cookies to copy from the authentication server response to the response.

=head2 address

Address defines the authentication server address.

=head2 authRequestHeaders

AuthRequestHeaders defines the list of the headers to copy from the request to the authentication server.
If not set or empty then all request headers are passed.

=head2 authResponseHeaders

AuthResponseHeaders defines the list of headers to copy from the authentication server response and set on forwarded request, replacing any existing conflicting headers.

=head2 authResponseHeadersRegex

AuthResponseHeadersRegex defines the regex to match headers to copy from the authentication server response and set on forwarded request, after stripping all headers that match the regex.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/forwardauth/#authresponseheadersregex

=head2 authSigninURL

AuthSigninURL specifies the URL to redirect to when the authentication server returns 401 Unauthorized.

=head2 forwardBody

ForwardBody defines whether to send the request body to the authentication server.

=head2 headerField

HeaderField defines a header field to store the authenticated user.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/forwardauth/#headerfield

=head2 maxBodySize

MaxBodySize defines the maximum body size in bytes allowed to be forwarded to the authentication server.

=head2 maxResponseBodySize

MaxResponseBodySize defines the maximum body size in bytes allowed in the response from the authentication server.

=head2 preserveLocationHeader

PreserveLocationHeader defines whether to forward the Location header to the client as is or prefix it with the domain name of the authentication server.

=head2 preserveRequestMethod

PreserveRequestMethod defines whether to preserve the original request method while forwarding the request to the authentication server.

=head2 tls

TLS defines the configuration used to secure the connection to the authentication server.

=head2 trustForwardHeader

TrustForwardHeader defines whether to trust (ie: forward) all X-Forwarded-* headers.

Deprecated: Use forwardedHeaders.trustedIPs at the EntryPoint level instead, and set trustForwardHeader to true on this middleware.

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
