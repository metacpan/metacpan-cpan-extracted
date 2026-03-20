package IO::K8s::Cilium::V2::CiliumNode;
# ABSTRACT: Cilium node configuration and status
our $VERSION = '1.009';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2',
    resource_plural => 'ciliumnodes';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumNode - Cilium node configuration and status

=head1 VERSION

version 1.009

=head1 DESCRIPTION

This cluster-scoped resource stores Cilium-specific node configuration and status, including IPAM allocations, encryption keys, and health information. It uses API version C<cilium.io/v2>. The C<spec> and C<status> fields contain opaque CRD-specific data structures managed by the Cilium agent running on each node.

=head1 SEE ALSO

=over

=item * L<IO::K8s::Cilium> - Main Cilium CRD namespace

=item * L<https://docs.cilium.io/en/stable/network/concepts/ipam/> - Upstream Cilium IPAM and node management documentation

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
