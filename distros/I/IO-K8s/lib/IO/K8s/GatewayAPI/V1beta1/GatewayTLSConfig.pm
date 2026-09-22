package IO::K8s::GatewayAPI::V1beta1::GatewayTLSConfig;
# ABSTRACT: TLS specifies frontend and backend tls configuration for entire gateway.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s backend  => '+IO::K8s::GatewayAPI::V1beta1::GatewayBackendTLS';
k8s frontend => '+IO::K8s::GatewayAPI::V1beta1::FrontendTLSConfig';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::GatewayTLSConfig - TLS specifies frontend and backend tls configuration for entire gateway.

=head1 VERSION

version 1.108

=head2 backend

Backend describes TLS configuration for gateway when connecting
to backends.

Note that this contains only details for the Gateway as a TLS client,
and does _not_ imply behavior about how to choose which backend should
get a TLS connection. That is determined by the presence of a BackendTLSPolicy.

Support: Core

=head2 frontend

Frontend describes TLS config when client connects to Gateway.
Support: Core

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
