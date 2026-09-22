package IO::K8s::Cilium::V2::PortRuleHTTP;
# ABSTRACT: PortRuleHTTP is a list of HTTP protocol constraints.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s headerMatches => ['+IO::K8s::Cilium::V2::HeaderMatch'];
k8s headers       => [Str];
k8s host          => Str;
k8s method        => Str;
k8s path          => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::PortRuleHTTP - PortRuleHTTP is a list of HTTP protocol constraints.

=head1 VERSION

version 1.108

=head2 headerMatches

HeaderMatches is a list of HTTP headers which must be
present and match against the given values. Mismatch field can be used
to specify what to do when there is no match.

=head2 headers

Headers is a list of HTTP headers which must be present in the
request. If omitted or empty, requests are allowed regardless of
headers present.

=head2 host

Host is an extended POSIX regex matched against the host header of a
request. Examples:

- foo.bar.com will match the host fooXbar.com or foo-bar.com
- foo\.bar\.com will only match the host foo.bar.com

If omitted or empty, the value of the host header is ignored.

=head2 method

Method is an extended POSIX regex matched against the method of a
request, e.g. "GET", "POST", "PUT", "PATCH", "DELETE", ...

If omitted or empty, all methods are allowed.

=head2 path

Path is an extended POSIX regex matched against the path of a
request. Currently it can contain characters disallowed from the
conventional "path" part of a URL as defined by RFC 3986.

If omitted or empty, all paths are all allowed.

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
