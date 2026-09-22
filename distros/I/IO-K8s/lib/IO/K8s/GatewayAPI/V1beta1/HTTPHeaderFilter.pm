package IO::K8s::GatewayAPI::V1beta1::HTTPHeaderFilter;
# ABSTRACT: ResponseHeaderModifier defines a schema for a filter that modifies response headers.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s add    => ['Core::V1::HTTPHeader'];
k8s remove => [Str];
k8s set    => ['Core::V1::HTTPHeader'];




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::HTTPHeaderFilter - ResponseHeaderModifier defines a schema for a filter that modifies response headers.

=head1 VERSION

version 1.108

=head2 add

Add adds the given header(s) (name, value) to the request
before the action. It appends to any existing values associated
with the header name.

Input:
  GET /foo HTTP/1.1
  my-header: foo

Config:
  add:
  - name: "my-header"
    value: "bar,baz"

Output:
  GET /foo HTTP/1.1
  my-header: foo,bar,baz

=head2 remove

Remove the given header(s) from the HTTP request before the action. The
value of Remove is a list of HTTP header names. Note that the header
names are case-insensitive (see
https://datatracker.ietf.org/doc/html/rfc2616#section-4.2).

Input:
  GET /foo HTTP/1.1
  my-header1: foo
  my-header2: bar
  my-header3: baz

Config:
  remove: ["my-header1", "my-header3"]

Output:
  GET /foo HTTP/1.1
  my-header2: bar

=head2 set

Set overwrites the request with the given header (name, value)
before the action.

Input:
  GET /foo HTTP/1.1
  my-header: foo

Config:
  set:
  - name: "my-header"
    value: "bar"

Output:
  GET /foo HTTP/1.1
  my-header: bar

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
