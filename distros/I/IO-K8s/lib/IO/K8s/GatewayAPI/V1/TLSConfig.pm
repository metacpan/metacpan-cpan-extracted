package IO::K8s::GatewayAPI::V1::TLSConfig;
# ABSTRACT: TLS store the configuration that will be applied to all Listeners handling HTTPS traffic and matching given port.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s validation => '+IO::K8s::GatewayAPI::V1::FrontendTLSValidation';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::TLSConfig - TLS store the configuration that will be applied to all Listeners handling HTTPS traffic and matching given port.

=head1 VERSION

version 1.108

=head2 validation

Validation holds configuration information for validating the frontend (client).
Setting this field will result in mutual authentication when connecting to the gateway.
In browsers this may result in a dialog appearing
that requests a user to specify the client certificate.
The maximum depth of a certificate chain accepted in verification is Implementation specific.

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
