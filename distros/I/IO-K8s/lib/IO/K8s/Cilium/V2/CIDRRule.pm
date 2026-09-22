package IO::K8s::Cilium::V2::CIDRRule;
# ABSTRACT: CIDRRule is a rule that specifies a CIDR prefix to/from which outside communication is allowed, along with an optional list of subnets within that CIDR prefix to/from which outside communication is not allowed.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cidr              => Str;
k8s cidrGroupRef      => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s cidrGroupSelector => 'Meta::V1::LabelSelector';
k8s except            => [Str];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CIDRRule - CIDRRule is a rule that specifies a CIDR prefix to/from which outside communication is allowed, along with an optional list of subnets within that CIDR prefix to/from which outside communication is not allowed.

=head1 VERSION

version 1.108

=head2 cidr

CIDR is a CIDR prefix / IP Block.

=head2 cidrGroupRef

CIDRGroupRef is a reference to a CiliumCIDRGroup object.
A CiliumCIDRGroup contains a list of CIDRs that the endpoint, subject to
the rule, can (Ingress/Egress) or cannot (IngressDeny/EgressDeny) receive
connections from.

=head2 cidrGroupSelector

CIDRGroupSelector selects CiliumCIDRGroups by their labels,
rather than by name.

=head2 except

ExceptCIDRs is a list of IP blocks which the endpoint subject to the rule
is not allowed to initiate connections to. These CIDR prefixes should be
contained within Cidr, using ExceptCIDRs together with CIDRGroupRef is not
supported yet.
These exceptions are only applied to the Cidr in this CIDRRule, and do not
apply to any other CIDR prefixes in any other CIDRRules.

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
