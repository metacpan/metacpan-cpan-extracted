package IO::K8s::GatewayAPI::V1::HTTPRouteMatch;
# ABSTRACT: HTTPRouteMatch defines the predicate used to match requests to a given action.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s headers     => ['+IO::K8s::GatewayAPI::V1::HTTPHeaderMatch'];
k8s method      => Str, { enum => [qw(GET HEAD POST PUT DELETE CONNECT OPTIONS TRACE PATCH)] };
k8s path        => '+IO::K8s::GatewayAPI::V1::HTTPPathMatch', { default => {'type' => 'PathPrefix','value' => '/'} };
k8s queryParams => ['+IO::K8s::GatewayAPI::V1::HTTPQueryParamMatch'];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPRouteMatch - HTTPRouteMatch defines the predicate used to match requests to a given action.

=head1 VERSION

version 1.108

=head2 headers

Headers specifies HTTP request header matchers. Multiple match values are
ANDed together, meaning, a request must match all the specified headers
to select the route.

=head2 method

Method specifies HTTP method matcher.
When specified, this route will be matched only if the request has the
specified method.

Support: Extended

=head2 path

Path specifies a HTTP request path matcher. If this field is not
specified, a default prefix match on the "/" path is provided.

=head2 queryParams

QueryParams specifies HTTP query parameter matchers. Multiple match
values are ANDed together, meaning, a request must match all the
specified query parameters to select the route.

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
