package IO::K8s::Traefik::V1alpha1::MiddlewareSpec;
# ABSTRACT: MiddlewareSpec defines the desired state of a Middleware.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addPrefix         => '+IO::K8s::Traefik::V1alpha1::AddPrefix';
k8s basicAuth         => '+IO::K8s::Traefik::V1alpha1::BasicAuth';
k8s buffering         => '+IO::K8s::Traefik::V1alpha1::Buffering';
k8s chain             => '+IO::K8s::Traefik::V1alpha1::Chain';
k8s circuitBreaker    => '+IO::K8s::Traefik::V1alpha1::CircuitBreaker';
k8s compress          => '+IO::K8s::Traefik::V1alpha1::Compress';
k8s contentType       => '+IO::K8s::Traefik::V1alpha1::ContentType';
k8s digestAuth        => '+IO::K8s::Traefik::V1alpha1::DigestAuth';
k8s encodedCharacters => '+IO::K8s::Traefik::V1alpha1::EncodedCharacters';
k8s errors            => '+IO::K8s::Traefik::V1alpha1::ErrorPage';
k8s forwardAuth       => '+IO::K8s::Traefik::V1alpha1::ForwardAuth';
k8s grpcWeb           => '+IO::K8s::Traefik::V1alpha1::GrpcWeb';
k8s headers           => '+IO::K8s::Traefik::V1alpha1::Headers';
k8s inFlightReq       => '+IO::K8s::Traefik::V1alpha1::InFlightReq';
k8s ipAllowList       => '+IO::K8s::Traefik::V1alpha1::IPAllowList';
k8s ipWhiteList       => '+IO::K8s::Traefik::V1alpha1::IPWhiteList';
k8s passTLSClientCert => '+IO::K8s::Traefik::V1alpha1::PassTLSClientCert';
k8s plugin            => { Str => 1 };
k8s rateLimit         => '+IO::K8s::Traefik::V1alpha1::RateLimit';
k8s redirectRegex     => '+IO::K8s::Traefik::V1alpha1::RedirectRegex';
k8s redirectScheme    => '+IO::K8s::Traefik::V1alpha1::RedirectScheme';
k8s replacePath       => '+IO::K8s::Traefik::V1alpha1::ReplacePath';
k8s replacePathRegex  => '+IO::K8s::Traefik::V1alpha1::ReplacePathRegex';
k8s retry             => '+IO::K8s::Traefik::V1alpha1::Retry';
k8s stripPrefix       => '+IO::K8s::Traefik::V1alpha1::StripPrefix';
k8s stripPrefixRegex  => '+IO::K8s::Traefik::V1alpha1::StripPrefixRegex';



























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::MiddlewareSpec - MiddlewareSpec defines the desired state of a Middleware.

=head1 VERSION

version 1.108

=head2 addPrefix

AddPrefix holds the add prefix middleware configuration.
This middleware updates the path of a request before forwarding it.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/addprefix/

=head2 basicAuth

BasicAuth holds the basic auth middleware configuration.
This middleware restricts access to your services to known users.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/basicauth/

=head2 buffering

Buffering holds the buffering middleware configuration.
This middleware retries or limits the size of requests that can be forwarded to backends.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/buffering/#maxrequestbodybytes

=head2 chain

Chain holds the configuration of the chain middleware.
This middleware enables to define reusable combinations of other pieces of middleware.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/chain/

=head2 circuitBreaker

CircuitBreaker holds the circuit breaker configuration.

=head2 compress

Compress holds the compress middleware configuration.
This middleware compresses responses before sending them to the client, using gzip, brotli, or zstd compression.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/compress/

=head2 contentType

ContentType holds the content-type middleware configuration.
This middleware exists to enable the correct behavior until at least the default one can be changed in a future version.

=head2 digestAuth

DigestAuth holds the digest auth middleware configuration.
This middleware restricts access to your services to known users.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/digestauth/

=head2 encodedCharacters

EncodedCharacters configures which encoded characters are allowed in the request path.

=head2 errors

ErrorPage holds the custom error middleware configuration.
This middleware returns a custom page in lieu of the default, according to configured ranges of HTTP Status codes.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/errorpages/

=head2 forwardAuth

ForwardAuth holds the forward auth middleware configuration.
This middleware delegates the request authentication to a Service.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/forwardauth/

=head2 grpcWeb

GrpcWeb holds the gRPC web middleware configuration.
This middleware converts a gRPC web request to an HTTP/2 gRPC request.

=head2 headers

Headers holds the headers middleware configuration.
This middleware manages the requests and responses headers.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/headers/#customrequestheaders

=head2 inFlightReq

InFlightReq holds the in-flight request middleware configuration.
This middleware limits the number of requests being processed and served concurrently.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/inflightreq/

=head2 ipAllowList

IPAllowList holds the IP allowlist middleware configuration.
This middleware limits allowed requests based on the client IP.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/ipallowlist/

=head2 ipWhiteList

Deprecated: please use IPAllowList instead.

=head2 passTLSClientCert

PassTLSClientCert holds the pass TLS client cert middleware configuration.
This middleware adds the selected data from the passed client TLS certificate to a header.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/passtlsclientcert/

=head2 plugin

Plugin defines the middleware plugin configuration.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/overview/#community-middlewares

=head2 rateLimit

RateLimit holds the rate limit configuration.
This middleware ensures that services will receive a fair amount of requests, and allows one to define what fair is.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/ratelimit/

=head2 redirectRegex

RedirectRegex holds the redirect regex middleware configuration.
This middleware redirects a request using regex matching and replacement.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/redirectregex/#regex

=head2 redirectScheme

RedirectScheme holds the redirect scheme middleware configuration.
This middleware redirects requests from a scheme/port to another.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/redirectscheme/

=head2 replacePath

ReplacePath holds the replace path middleware configuration.
This middleware replaces the path of the request URL and store the original path in an X-Replaced-Path header.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/replacepath/

=head2 replacePathRegex

ReplacePathRegex holds the replace path regex middleware configuration.
This middleware replaces the path of a URL using regex matching and replacement.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/replacepathregex/

=head2 retry

Retry holds the retry middleware configuration.
This middleware reissues requests a given number of times to a backend server if that server does not reply.
As soon as the server answers, the middleware stops retrying, regardless of the response status.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/http/middlewares/retry/

=head2 stripPrefix

StripPrefix holds the strip prefix middleware configuration.
This middleware removes the specified prefixes from the URL path.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/stripprefix/

=head2 stripPrefixRegex

StripPrefixRegex holds the strip prefix regex middleware configuration.
This middleware removes the matching prefixes from the URL path.
More info: https://doc.traefik.io/traefik/v3.7/middlewares/http/stripprefixregex/

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
