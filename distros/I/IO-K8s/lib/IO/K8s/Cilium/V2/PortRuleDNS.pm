package IO::K8s::Cilium::V2::PortRuleDNS;
# ABSTRACT: PortRuleDNS is a list of allowed DNS lookups.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s matchName    => Str, { pattern => qr/^([-a-zA-Z0-9_]+[.]?)+$/ };
k8s matchPattern => Str, { pattern => qr/^([-a-zA-Z0-9_*]+[.]?)+$/ };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::PortRuleDNS - PortRuleDNS is a list of allowed DNS lookups.

=head1 VERSION

version 1.108

=head2 matchName

MatchName matches literal DNS names. A trailing "." is automatically added
when missing.

=head2 matchPattern

MatchPattern allows using wildcards to match DNS names. All wildcards are
case insensitive. The wildcards are:
- "*" matches 0 or more DNS valid characters, and may occur anywhere in
the pattern. As a special case a "*" as the leftmost character, without a
following "." matches all subdomains as well as the name to the right.
A trailing "." is automatically added when missing.
- "**." is a special prefix which matches all multilevel subdomains in the prefix.

Examples:
1. `*.cilium.io` matches subdomains of cilium at that level
  www.cilium.io and blog.cilium.io match, cilium.io and google.com do not
2. `*cilium.io` matches cilium.io and all subdomains ends with "cilium.io"
  except those containing "." separator, subcilium.io and sub-cilium.io match,
  www.cilium.io and blog.cilium.io does not
3. `sub*.cilium.io` matches subdomains of cilium where the subdomain component
  begins with "sub". sub.cilium.io and subdomain.cilium.io match while www.cilium.io,
  blog.cilium.io, cilium.io and google.com do not
4. `**.cilium.io` matches all multilevel subdomains of cilium.io.
  "app.cilium.io" and "test.app.cilium.io" match but not "cilium.io"

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
