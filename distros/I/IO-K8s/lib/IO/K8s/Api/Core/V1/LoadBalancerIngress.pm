package IO::K8s::Api::Core::V1::LoadBalancerIngress;
# ABSTRACT: LoadBalancerIngress represents the status of a load-balancer ingress point: traffic intended for the service should be sent to an ingress point.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s hostname => Str;


k8s ip => Str;


k8s ipMode => Str;


k8s ports => ['Core::V1::PortStatus'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::LoadBalancerIngress - LoadBalancerIngress represents the status of a load-balancer ingress point: traffic intended for the service should be sent to an ingress point.

=head1 VERSION

version 1.100

=head2 hostname

Hostname is set for load-balancer ingress points that are DNS based (typically AWS load-balancers)

=head2 ip

IP is set for load-balancer ingress points that are IP based (typically GCE or OpenStack load-balancers)

=head2 ipMode

IPMode specifies how the load-balancer IP behaves, and may only be specified when the ip field is specified. Setting this to "VIP" indicates that traffic is delivered to the node with the destination set to the load-balancer's IP and port. Setting this to "Proxy" indicates that traffic is delivered to the node or pod with the destination set to the node's IP and node port or the pod's IP and port. Service implementations may use this information to adjust traffic routing.

=head2 ports

Ports is a list of records of service ports If used, every port defined in the service should have an entry in it

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
