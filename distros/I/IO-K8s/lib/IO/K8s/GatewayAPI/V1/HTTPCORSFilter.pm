package IO::K8s::GatewayAPI::V1::HTTPCORSFilter;
# ABSTRACT: CORS defines a schema for a filter that responds to the cross-origin request based on HTTP response header.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowCredentials => Bool;
k8s allowHeaders     => [Str], { pattern => '^[A-Za-z0-9!#$%&\'*+\\-.^_\\x60|~]+$' };
k8s allowMethods     => [Str], { enum => ['GET','HEAD','POST','PUT','DELETE','CONNECT','OPTIONS','TRACE','PATCH','*'] };
k8s allowOrigins     => [Str], { pattern => '(^\\*$)|(^(http(s)?):\\/\\/(((\\*\\.)?([a-zA-Z0-9\\-]+\\.)*[a-zA-Z0-9-]+|\\*)(:([0-9]{1,5}))?)$)' };
k8s exposeHeaders    => [Str], { pattern => '^[A-Za-z0-9!#$%&\'*+\\-.^_\\x60|~]+$' };
k8s maxAge           => Int, { minimum => 1, default => 5 };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPCORSFilter - CORS defines a schema for a filter that responds to the cross-origin request based on HTTP response header.

=head1 VERSION

version 1.108

=head2 allowCredentials

AllowCredentials indicates whether the actual cross-origin request allows
to include credentials.

When set to true, the gateway will include the `Access-Control-Allow-Credentials`
response header with value true (case-sensitive).

When set to false or omitted the gateway will omit the header
`Access-Control-Allow-Credentials` entirely (this is the standard CORS
behavior).

Support: Extended

=head2 allowHeaders

AllowHeaders indicates which HTTP request headers are supported for
accessing the requested resource.

Header names are not case-sensitive.

Multiple header names in the value of the `Access-Control-Allow-Headers`
response header are separated by a comma (",").

When the `allowHeaders` field is configured with one or more headers, the
gateway must return the `Access-Control-Allow-Headers` response header
which value is present in the `allowHeaders` field.

If any header name in the `Access-Control-Request-Headers` request header
is not included in the list of header names specified by the response
header `Access-Control-Allow-Headers`, it will present an error on the
client side.

If any header name in the `Access-Control-Allow-Headers` response header
does not recognize by the client, it will also occur an error on the
client side.

A wildcard indicates that the requests with all HTTP headers are allowed.

If the configuration contains the wildcard `*` in `allowHeaders` and
`allowCredentials` is set to `false`, the `Access-Control-Allow-Headers`
response header may either contain the wildcard `*` or echo the value
of the `Access-Control-Request-Headers` request header.

If the configuration contains the wildcard `*` in `allowHeaders` and
`allowCredentials` is set to `true`, the gateway must not return `*`
in the `Access-Control-Allow-Headers` response header. Instead, it must
return one or more header names matching the value of the
`Access-Control-Request-Headers` request header.
If the `Access-Control-Request-Headers` header is not present in the
request, the gateway must omit the `Access-Control-Allow-Headers`
response header.

Support: Extended

=head2 allowMethods

AllowMethods indicates which HTTP methods are supported for accessing the
requested resource.

Valid values are any method defined by RFC9110, along with the special
value `*`, which represents all HTTP methods are allowed.

Method names are case-sensitive, so these values are also case-sensitive.
(See https://www.rfc-editor.org/rfc/rfc2616#section-5.1.1)

Multiple method names in the value of the `Access-Control-Allow-Methods`
response header are separated by a comma (",").

A CORS-safelisted method is a method that is `GET`, `HEAD`, or `POST`.
(See https://fetch.spec.whatwg.org/#cors-safelisted-method) The
CORS-safelisted methods are always allowed, regardless of whether they
are specified in the `allowMethods` field.

When the `allowMethods` field is configured with one or more methods, the
gateway must return the `Access-Control-Allow-Methods` response header
which value is present in the `allowMethods` field.

If the HTTP method of the `Access-Control-Request-Method` request header
is not included in the list of methods specified by the response header
`Access-Control-Allow-Methods`, it will present an error on the client
side.

If the configuration contains the wildcard `*` in `allowMethods` and
`allowCredentials` is set to `false`, the `Access-Control-Allow-Methods`
response header may either contain the wildcard `*` or echo the value
of the `Access-Control-Request-Method` request header.

If the configuration contains the wildcard `*` in `allowMethods` and
`allowCredentials` is set to `true`, the gateway must not return `*`
in the `Access-Control-Allow-Methods` response header. Instead, it must
return a single HTTP method matching the value of the
`Access-Control-Request-Method` request header.
If the `Access-Control-Request-Method` header is not present in the request,
the gateway must omit the `Access-Control-Allow-Methods` response header.

Support: Extended

=head2 allowOrigins

AllowOrigins indicates whether the response can be shared with requested
resource from the given `Origin`.

The `Origin` consists of a scheme and a host, with an optional port, and
takes the form `<scheme>://<host>(:<port>)`.

Valid values for scheme are: `http` and `https`.

Valid values for port are any integer between 1 and 65535 (the list of
available TCP/UDP ports). Note that, if not included, port `80` is
assumed for `http` scheme origins, and port `443` is assumed for `https`
origins. This may affect origin matching.

The host part of the origin may contain the wildcard character `*`. These
wildcard characters behave as follows:

* `*` is a greedy match to the _left_, including any number of
  DNS labels to the left of its position. This also means that
  `*` will include any number of period `.` characters to the
  left of its position.
* A wildcard by itself matches all hosts.

An origin value that includes _only_ the `*` character indicates requests
from all `Origin`s are allowed.

When the `allowOrigins` field is configured with multiple origins, it
means the server supports clients from multiple origins. If the request
`Origin` matches the configured allowed origins, the gateway must return
the given `Origin` and sets value of the header
`Access-Control-Allow-Origin` same as the `Origin` header provided by the
client.

The status code of a successful response to a "preflight" request is
always an OK status (i.e., 204 or 200).

If the request `Origin` does not match the configured allowed origins,
the gateway returns 204/200 response but doesn't set the relevant
cross-origin response headers. Alternatively, the gateway responds with
403 status to the "preflight" request is denied, coupled with omitting
the CORS headers. The cross-origin request fails on the client side.
Therefore, the client doesn't attempt the actual cross-origin request.

Conversely, if the request `Origin` matches one of the configured
allowed origins, the gateway sets the response header
`Access-Control-Allow-Origin` to the same value as the `Origin`
header provided by the client.

If the configuration contains the wildcard `*` in `allowOrigins` and
`allowCredentials` is set to `false`, the `Access-Control-Allow-Origin`
response header may either contain the wildcard `*` or echo the value
of the `Origin` request header.

If the configuration contains the wildcard `*` in `allowOrigins` and
`allowCredentials` is set to `true`, the gateway must not return `*`
in the `Access-Control-Allow-Origin` response header. Instead, it must
return a single origin matching the value of the `Origin` request header.

Support: Extended

=head2 exposeHeaders

ExposeHeaders indicates which HTTP response headers can be exposed
to client-side scripts in response to a cross-origin request.

A CORS-safelisted response header is an HTTP header in a CORS response
that it is considered safe to expose to the client scripts.
The CORS-safelisted response headers include the following headers:
`Cache-Control`
`Content-Language`
`Content-Length`
`Content-Type`
`Expires`
`Last-Modified`
`Pragma`
(See https://fetch.spec.whatwg.org/#cors-safelisted-response-header-name)
The CORS-safelisted response headers are exposed to client by default.

When an HTTP header name is specified using the `exposeHeaders` field,
this additional header will be exposed as part of the response to the
client.

Header names are not case-sensitive.

Multiple header names in the value of the `Access-Control-Expose-Headers`
response header are separated by a comma (",").

A wildcard indicates that the responses with all HTTP headers are exposed
to clients.

If the configuration contains the wildcard `*` in `exposeHeaders` and
`allowCredentials` is set to `false`, the `Access-Control-Expose-Headers`
response header can contain the wildcard `*`.

If the configuration contains the wildcard `*` in `exposeHeaders` and
`allowCredentials` is set to `true`, the gateway cannot use the `*`
in the `Access-Control-Expose-Headers` response header.

Support: Extended

=head2 maxAge

MaxAge indicates the duration (in seconds) for the client to cache the
results of a "preflight" request.

The information provided by the `Access-Control-Allow-Methods` and
`Access-Control-Allow-Headers` response headers can be cached by the
client until the time specified by `Access-Control-Max-Age` elapses.

The default value of `Access-Control-Max-Age` response header is 5
(seconds).

When the `MaxAge` field is unspecified, the gateway sets the response
header "Access-Control-Max-Age: 5" by default.

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
