package IO::K8s::Cilium::V2::VPC;
# ABSTRACT: VPC is the vpc to which the ENI belongs
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cidr              => Str;
k8s 'ipv6-cidr'       => Str;
k8s 'secondary-cidrs' => [Str];
k8s 'vpc-id'          => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::VPC - VPC is the vpc to which the ENI belongs

=head1 VERSION

version 1.108

=head2 cidr

CIDRBlock is the VPC IPv4 CIDR

=head2 ipv6-cidr

IPv6CIDRBlock is the VPC IPv6 CIDR

=head2 secondary-cidrs

SecondaryCIDRs is the list of Secondary CIDRs associated with the VPC

=head2 vpc-id

VPCID is the vpc to which the ENI belongs

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
