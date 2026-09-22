package IO::K8s::GatewayAPI::V1beta1::HTTPHeaderMatch;
# ABSTRACT: HTTPHeaderMatch describes how to select a HTTP route by matching HTTP request headers.
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

IO::K8s::GatewayAPI::V1beta1::HTTPHeaderMatch - HTTPHeaderMatch describes how to select a HTTP route by matching HTTP request headers.

=head1 VERSION

version 1.108

=head2 name

Name is the name of the HTTP Header to be matched. Name matching MUST be
case-insensitive. (See https://tools.ietf.org/html/rfc7230#section-3.2).

If multiple entries specify equivalent header names, only the first
entry with an equivalent name MUST be considered for a match. Subsequent
entries with an equivalent header name MUST be ignored. Due to the
case-insensitivity of header names, "foo" and "Foo" are considered
equivalent.

When a header is repeated in an HTTP request, it is
implementation-specific behavior as to how this is represented.
Generally, proxies should follow the guidance from the RFC:
https://www.rfc-editor.org/rfc/rfc7230.html#section-3.2.2 regarding
processing a repeated header, with special handling for "Set-Cookie".

=head2 type

Type specifies how to match against the value of the header.

Support: Core (Exact)

Support: Implementation-specific (RegularExpression)

Since RegularExpression HeaderMatchType has implementation-specific
conformance, implementations can support POSIX, PCRE or any other dialects
of regular expressions. Please read the implementation's documentation to
determine the supported dialect.

=head2 value

Value is the value of HTTP Header to be matched.

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
