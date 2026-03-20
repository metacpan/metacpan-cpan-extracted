package IO::K8s::GatewayAPI::V1::HTTPRoute;
# ABSTRACT: Gateway API HTTP routing rules
our $VERSION = '1.009';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1',
    resource_plural => 'httproutes';
with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::Routable';

sub _route_format { 'gateway' }

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::HTTPRoute - Gateway API HTTP routing rules

=head1 VERSION

version 1.009

=head1 DESCRIPTION

Represents an HTTPRoute resource from the Kubernetes Gateway API (C<gateway.networking.k8s.io/v1>). An HTTPRoute defines HTTP routing rules including host matching, path matching, header manipulation, and backend service references. HTTPRoute is a namespaced resource that attaches to Gateway listeners. The C<spec> and C<status> fields are opaque hashrefs containing the Gateway API structure.

=head1 SEE ALSO

=over

=item * L<IO::K8s::GatewayAPI> - Gateway API module namespace

=item * L<https://gateway-api.sigs.k8s.io/api-types/httproute/> - Upstream HTTPRoute documentation

=item * L<IO::K8s::GatewayAPI::V1::Gateway> - Gateway that serves this route

=item * L<IO::K8s::GatewayAPI::V1::GRPCRoute> - gRPC routing alternative

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
