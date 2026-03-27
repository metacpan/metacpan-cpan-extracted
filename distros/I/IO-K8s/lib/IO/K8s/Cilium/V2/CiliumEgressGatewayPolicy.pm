package IO::K8s::Cilium::V2::CiliumEgressGatewayPolicy;
# ABSTRACT: Cilium egress gateway policy
our $VERSION = '1.100';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2',
    resource_plural => 'ciliumegressgatewaypolicies';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumEgressGatewayPolicy - Cilium egress gateway policy

=head1 VERSION

version 1.100

=head1 DESCRIPTION

This cluster-scoped resource routes pod egress traffic through specific gateway nodes with stable source IPs, enabling external services to whitelist known IP addresses. It uses API version C<cilium.io/v2>. The C<spec> and C<status> fields contain opaque CRD-specific data structures managed by the Cilium controller.

=head1 SEE ALSO

=over

=item * L<IO::K8s::Cilium> - Main Cilium CRD namespace

=item * L<https://docs.cilium.io/en/stable/network/egress-gateway/> - Upstream Cilium egress gateway policy documentation

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
