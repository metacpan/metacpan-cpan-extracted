package IO::K8s::GatewayAPI::V1beta1::Gateway;
# ABSTRACT: Gateway represents an instance of a service-traffic handling infrastructure by binding Listeners to a set of IP addresses.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1beta1',
    resource_plural => 'gateways';
with 'IO::K8s::Role::Namespaced';

k8s spec   => '+IO::K8s::GatewayAPI::V1beta1::GatewaySpec', { required => 'schema' };
k8s status => '+IO::K8s::GatewayAPI::V1beta1::GatewayStatus', { default => {'conditions' => [{'lastTransitionTime' => '1970-01-01T00:00:00Z','message' => 'Waiting for controller','reason' => 'Pending','status' => 'Unknown','type' => 'Accepted'},{'lastTransitionTime' => '1970-01-01T00:00:00Z','message' => 'Waiting for controller','reason' => 'Pending','status' => 'Unknown','type' => 'Programmed'}]} };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::Gateway - Gateway represents an instance of a service-traffic handling infrastructure by binding Listeners to a set of IP addresses.

=head1 VERSION

version 1.108

=head2 spec

Spec defines the desired state of Gateway.

=head2 status

Status defines the current state of Gateway.

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
