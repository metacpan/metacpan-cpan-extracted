package IO::K8s::Cilium::V2::ENI;
# ABSTRACT: ENI represents an AWS Elastic Network Interface More details: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s addresses           => [Str];
k8s 'availability-zone' => Str;
k8s description         => Str;
k8s id                  => Str;
k8s ip                  => Str;
k8s 'ipv6-prefixes'     => [Str];
k8s mac                 => Str;
k8s number              => Int;
k8s prefixes            => [Str];
k8s 'public-ip'         => Str;
k8s 'security-groups'   => [Str];
k8s subnet              => '+IO::K8s::Cilium::V2::AwsSubnet';
k8s tags                => { Str => 1 };
k8s vpc                 => '+IO::K8s::Cilium::V2::AwsVPC';















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ENI - ENI represents an AWS Elastic Network Interface More details: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html

=head1 VERSION

version 1.108

=head2 addresses

Addresses is the list of all secondary IPs associated with the ENI

=head2 availability-zone

AvailabilityZone is the availability zone of the ENI

=head2 description

Description is the description field of the ENI

=head2 id

ID is the ENI ID

=head2 ip

IP is the primary IP of the ENI

=head2 ipv6-prefixes

IPv6Prefixes is the list of all IPv6 /80 delegated prefixes associated with the ENI

=head2 mac

MAC is the mac address of the ENI

=head2 number

Number is the interface index, it used in combination with
FirstInterfaceIndex

=head2 prefixes

Prefixes is the list of all IPv4 /28 delegated prefixes associated with the ENI

=head2 public-ip

PublicIP is the public IP associated with the ENI

=head2 security-groups

SecurityGroups are the security groups associated with the ENI

=head2 subnet

Subnet is the subnet the ENI is associated with

=head2 tags

Tags is the set of tags of the ENI. Used to detect ENIs which should
not be managed by Cilium

=head2 vpc

VPC is the VPC information to which the ENI is attached to

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
