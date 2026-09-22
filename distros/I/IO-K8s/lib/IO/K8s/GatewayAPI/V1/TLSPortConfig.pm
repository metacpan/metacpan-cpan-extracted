package IO::K8s::GatewayAPI::V1::TLSPortConfig;
# ABSTRACT: TLSPortConfig
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s port => Int, { required => 'schema', minimum => 1, maximum => 65535 };
k8s tls  => '+IO::K8s::GatewayAPI::V1::TLSConfig', { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::TLSPortConfig - TLSPortConfig

=head1 VERSION

version 1.108

=head2 port

The Port indicates the Port Number to which the TLS configuration will be
applied. This configuration will be applied to all Listeners handling HTTPS
traffic that match this port.

Support: Core

=head2 tls

TLS store the configuration that will be applied to all Listeners handling
HTTPS traffic and matching given port.

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
