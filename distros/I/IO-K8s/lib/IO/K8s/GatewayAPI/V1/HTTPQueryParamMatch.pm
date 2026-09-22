package IO::K8s::GatewayAPI::V1::HTTPQueryParamMatch;
# ABSTRACT: HTTPQueryParamMatch describes how to select a HTTP route by matching HTTP query parameters.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s name  => Str, { required => 'schema', pattern => '^[A-Za-z0-9!#$%&\'*+\\-.^_\\x60|~]+$' };
k8s type  => Str, { enum => [qw(Exact RegularExpression)], default => 'Exact' };
k8s value => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPQueryParamMatch - HTTPQueryParamMatch describes how to select a HTTP route by matching HTTP query parameters.

=head1 VERSION

version 1.108

=head2 name

Name is the name of the HTTP query param to be matched. This must be an
exact string match. (See
https://tools.ietf.org/html/rfc7230#section-2.7.3).

If multiple entries specify equivalent query param names, only the first
entry with an equivalent name MUST be considered for a match. Subsequent
entries with an equivalent query param name MUST be ignored.

If a query param is repeated in an HTTP request, the behavior is
purposely left undefined, since different data planes have different
capabilities. However, it is *recommended* that implementations should
match against the first value of the param if the data plane supports it,
as this behavior is expected in other load balancing contexts outside of
the Gateway API.

Users SHOULD NOT route traffic based on repeated query params to guard
themselves against potential differences in the implementations.

=head2 type

Type specifies how to match against the value of the query parameter.

Support: Extended (Exact)

Support: Implementation-specific (RegularExpression)

Since RegularExpression QueryParamMatchType has Implementation-specific
conformance, implementations can support POSIX, PCRE or any other
dialects of regular expressions. Please read the implementation's
documentation to determine the supported dialect.

=head2 value

Value is the value of HTTP query param to be matched.

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
