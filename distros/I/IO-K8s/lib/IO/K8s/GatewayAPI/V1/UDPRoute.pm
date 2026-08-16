package IO::K8s::GatewayAPI::V1::UDPRoute;
# ABSTRACT: Gateway API raw UDP routing rules
our $VERSION = '1.107';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1',
    resource_plural => 'udproutes';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::UDPRoute - Gateway API raw UDP routing rules

=head1 VERSION

version 1.107

=head1 DESCRIPTION

Represents a UDPRoute resource from the Kubernetes Gateway API (C<gateway.networking.k8s.io/v1>). A UDPRoute routes raw L4 UDP traffic purely by C<parentRef> and listener port, forwarding to backends via C<rules[].backendRefs>. Like TCPRoute, it has no hostname field to match on, so it does not consume L<IO::K8s::Role::Routable> (whose C<add_hostname> assumes a C<spec.hostnames> field). UDPRoute is a namespaced resource that attaches to Gateway listeners. The C<spec> and C<status> fields are opaque hashrefs containing the Gateway API structure.

=head1 SEE ALSO

=over

=item * L<IO::K8s::GatewayAPI> - Gateway API module namespace

=item * L<https://gateway-api.sigs.k8s.io/api-types/udproute/> - Upstream UDPRoute documentation

=item * L<IO::K8s::GatewayAPI::V1::Gateway> - Gateway that serves this route

=item * L<IO::K8s::GatewayAPI::V1::TCPRoute> - Raw TCP routing counterpart

=back

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
