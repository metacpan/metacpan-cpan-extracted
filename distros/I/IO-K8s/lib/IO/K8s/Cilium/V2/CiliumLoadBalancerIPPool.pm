package IO::K8s::Cilium::V2::CiliumLoadBalancerIPPool;
# ABSTRACT: CiliumLoadBalancerIPPool is a Kubernetes third-party resource which is used to defined pools of IPs which the operator can use to allocate and advertise IPs for Services of type LoadBalancer.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2',
    resource_plural => 'ciliumloadbalancerippools';

k8s spec   => '+IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolSpec', { required => 'schema' };
k8s status => '+IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumLoadBalancerIPPool - CiliumLoadBalancerIPPool is a Kubernetes third-party resource which is used to defined pools of IPs which the operator can use to allocate and advertise IPs for Services of type LoadBalancer.

=head1 VERSION

version 1.108

=head2 spec

Spec is a human readable description for a BGP load balancer
ip pool.

=head2 status

Status is the status of the IP Pool.

It might be possible for users to define overlapping IP Pools, we can't validate or enforce non-overlapping pools
during object creation. The Cilium operator will do this validation and update the status to reflect the ability
to allocate IPs from this pool.

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
