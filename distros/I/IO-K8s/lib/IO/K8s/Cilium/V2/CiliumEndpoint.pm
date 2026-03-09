package IO::K8s::Cilium::V2::CiliumEndpoint;
# ABSTRACT: Cilium endpoint representing a pod's network state
our $VERSION = '1.008';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2',
    resource_plural => 'ciliumendpoints';
with 'IO::K8s::Role::Namespaced';

k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumEndpoint - Cilium endpoint representing a pod's network state

=head1 VERSION

version 1.008

=head1 DESCRIPTION

This namespace-scoped resource represents a Cilium-managed endpoint, typically a Pod's network interface. It tracks the endpoint's networking state, security identity, and policy enforcement status, using API version C<cilium.io/v2>. The C<status> field contains opaque CRD-specific data structures managed by the Cilium agent.

=head1 SEE ALSO

=over

=item * L<IO::K8s::Cilium> - Main Cilium CRD namespace

=item * L<https://docs.cilium.io/en/stable/internals/cilium-operator/> - Upstream Cilium operator and endpoint management documentation

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
