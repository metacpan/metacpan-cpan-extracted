package IO::K8s::GatewayAPI::V1::ListenerEntry;
# ABSTRACT: ListenerEntry
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowedRoutes => '+IO::K8s::GatewayAPI::V1::AllowedRoutes', { default => {'namespaces' => {'from' => 'Same'}} };
k8s hostname      => Str, { pattern => qr/^(\*\.)?[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s name          => Str, { required => 'schema', pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s port          => Int, { required => 'schema', minimum => 1, maximum => 65535 };
k8s protocol      => Str, { required => 'schema', pattern => '^[a-zA-Z0-9]([-a-zA-Z0-9]*[a-zA-Z0-9])?$|[a-z0-9]([-a-z0-9]*[a-z0-9])?(\\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\\/[A-Za-z0-9]+$' };
k8s tls           => '+IO::K8s::GatewayAPI::V1::ListenerTLSConfig';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::ListenerEntry - ListenerEntry

=head1 VERSION

version 1.108

=head2 allowedRoutes

AllowedRoutes defines the types of routes that MAY be attached to a
Listener and the trusted namespaces where those Route resources MAY be
present.

Although a client request may match multiple route rules, only one rule
may ultimately receive the request. Matching precedence MUST be
determined in order of the following criteria:

* The most specific match as defined by the Route type.
* The oldest Route based on creation timestamp. For example, a Route with
  a creation timestamp of "2020-09-08 01:02:03" is given precedence over
  a Route with a creation timestamp of "2020-09-08 01:02:04".
* If everything else is equivalent, the Route appearing first in
  alphabetical order (namespace/name) should be given precedence. For
  example, foo/bar is given precedence over foo/baz.

All valid rules within a Route attached to this Listener should be
implemented. Invalid Route rules can be ignored (sometimes that will mean
the full Route). If a Route rule transitions from valid to invalid,
support for that Route rule should be dropped to ensure consistency. For
example, even if a filter specified by a Route rule is invalid, the rest
of the rules within that Route should still be supported.

=head2 hostname

Hostname specifies the virtual hostname to match for protocol types that
define this concept. When unspecified, all hostnames are matched. This
field is ignored for protocols that don't require hostname based
matching.

Implementations MUST apply Hostname matching appropriately for each of
the following protocols:

* TLS: The Listener Hostname MUST match the SNI.
* HTTP: The Listener Hostname MUST match the Host header of the request.
* HTTPS: The Listener Hostname SHOULD match at both the TLS and HTTP
  protocol layers as described above. If an implementation does not
  ensure that both the SNI and Host header match the Listener hostname,
  it MUST clearly document that.

For HTTPRoute and TLSRoute resources, there is an interaction with the
`spec.hostnames` array. When both listener and route specify hostnames,
there MUST be an intersection between the values for a Route to be
accepted. For more information, refer to the Route specific Hostnames
documentation.

Hostnames that are prefixed with a wildcard label (`*.`) are interpreted
as a suffix match. That means that a match for `*.example.com` would match
both `test.example.com`, and `foo.test.example.com`, but not `example.com`.

=head2 name

Name is the name of the Listener. This name MUST be unique within a
ListenerSet.

Name is not required to be unique across a Gateway and ListenerSets.
Routes can attach to a Listener by having a ListenerSet as a parentRef
and setting the SectionName

=head2 port

Port is the network port. Multiple listeners may use the
same port, subject to the Listener compatibility rules.

=head2 protocol

Protocol specifies the network protocol this listener expects to receive.

=head2 tls

TLS is the TLS configuration for the Listener. This field is required if
the Protocol field is "HTTPS" or "TLS". It is invalid to set this field
if the Protocol field is "HTTP", "TCP", or "UDP".

The association of SNIs to Certificate defined in ListenerTLSConfig is
defined based on the Hostname field for this listener.

The GatewayClass MUST use the longest matching SNI out of all
available certificates for any TLS handshake.

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
