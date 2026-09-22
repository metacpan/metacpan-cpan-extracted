package IO::K8s::GatewayAPI::V1beta1::GatewayClass;
# ABSTRACT: GatewayClass describes a class of Gateways available to the user for creating Gateway resources.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1beta1',
    resource_plural => 'gatewayclasses';

k8s spec   => '+IO::K8s::GatewayAPI::V1beta1::GatewayClassSpec', { required => 'schema' };
k8s status => '+IO::K8s::GatewayAPI::V1beta1::GatewayClassStatus', { default => {'conditions' => [{'lastTransitionTime' => '1970-01-01T00:00:00Z','message' => 'Waiting for controller','reason' => 'Pending','status' => 'Unknown','type' => 'Accepted'}]} };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::GatewayClass - GatewayClass describes a class of Gateways available to the user for creating Gateway resources.

=head1 VERSION

version 1.108

=head2 spec

Spec defines the desired state of GatewayClass.

=head2 status

Status defines the current state of GatewayClass.

Implementations MUST populate status on all GatewayClass resources which
specify their controller name.

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
