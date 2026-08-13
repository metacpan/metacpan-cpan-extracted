package IO::K8s::GatewayAPI::V1::BackendTLSPolicy;
# ABSTRACT: Gateway API TLS policy for connections to a backend
our $VERSION = '1.106';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1',
    resource_plural => 'backendtlspolicies';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::BackendTLSPolicy - Gateway API TLS policy for connections to a backend

=head1 VERSION

version 1.106

=head1 DESCRIPTION

Represents a BackendTLSPolicy resource from the Kubernetes Gateway API (C<gateway.networking.k8s.io/v1>). A BackendTLSPolicy configures TLS from a Gateway to a backend, including target references, certificate validation (CA certificates or well-known CA bundles), and the expected hostname or subject alternative names. BackendTLSPolicy is a namespaced resource. The C<spec> and C<status> fields are opaque hashrefs containing the Gateway API structure.

=head1 SEE ALSO

=over

=item * L<IO::K8s::GatewayAPI> - Gateway API module namespace

=item * L<https://gateway-api.sigs.k8s.io/api-types/backendtlspolicy/> - Upstream BackendTLSPolicy documentation

=item * L<IO::K8s::GatewayAPI::V1::Gateway> - Gateway that may enforce this policy

=item * L<IO::K8s::GatewayAPI::V1::HTTPRoute> - Route whose backends this policy secures

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
