package IO::K8s::GatewayAPI::V1::FrontendTLSConfig;
# ABSTRACT: Frontend describes TLS config when client connects to Gateway.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s default => '+IO::K8s::GatewayAPI::V1::TLSConfig', { required => 'schema' };
k8s perPort => ['+IO::K8s::GatewayAPI::V1::TLSPortConfig'];



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::FrontendTLSConfig - Frontend describes TLS config when client connects to Gateway.

=head1 VERSION

version 1.108

=head2 default

Default specifies the default client certificate validation configuration
for all Listeners handling HTTPS traffic, unless a per-port configuration
is defined.

support: Core

=head2 perPort

PerPort specifies tls configuration assigned per port.
Per port configuration is optional. Once set this configuration overrides
the default configuration for all Listeners handling HTTPS traffic
that match this port.
Each override port requires a unique TLS configuration.

support: Core

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
