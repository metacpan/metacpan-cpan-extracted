package IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolSpec;
# ABSTRACT: Spec is a human readable description for a BGP load balancer ip pool.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowFirstLastIPs => Str, { enum => [qw(Yes No)] };
k8s blocks            => ['+IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolIPBlock'];
k8s disabled          => Bool, { default => 0 };
k8s serviceSelector   => 'Meta::V1::LabelSelector';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumLoadBalancerIPPoolSpec - Spec is a human readable description for a BGP load balancer ip pool.

=head1 VERSION

version 1.108

=head2 allowFirstLastIPs

AllowFirstLastIPs, if set to `Yes` or undefined means that the first and last IPs of each CIDR will be allocatable.
If `No`, these IPs will be reserved. This field is ignored for /{31,32} and /{127,128} CIDRs since
reserving the first and last IPs would make the CIDRs unusable.

=head2 blocks

Blocks is a list of CIDRs comprising this IP Pool

=head2 disabled

Disabled, if set to true means that no new IPs will be allocated from this pool.
Existing allocations will not be removed from services.

=head2 serviceSelector

ServiceSelector selects a set of services which are eligible to receive IPs from this

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
