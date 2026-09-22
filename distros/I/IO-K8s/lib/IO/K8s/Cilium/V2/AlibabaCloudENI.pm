package IO::K8s::Cilium::V2::AlibabaCloudENI;
# ABSTRACT: ENI represents an AlibabaCloud Elastic Network Interface
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'instance-id'          => Str;
k8s 'mac-address'          => Str;
k8s 'network-interface-id' => Str;
k8s 'primary-ip-address'   => Str;
k8s 'private-ipsets'       => ['+IO::K8s::Cilium::V2::PrivateIPSet'];
k8s 'security-groupids'    => [Str];
k8s tags                   => { Str => 1 };
k8s type                   => Str;
k8s vpc                    => '+IO::K8s::Cilium::V2::VPC';
k8s vswitch                => '+IO::K8s::Cilium::V2::VSwitch';
k8s 'zone-id'              => Str;












1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AlibabaCloudENI - ENI represents an AlibabaCloud Elastic Network Interface

=head1 VERSION

version 1.108

=head2 instance-id

InstanceID is the InstanceID using this ENI

=head2 mac-address

MACAddress is the mac address of the ENI

=head2 network-interface-id

NetworkInterfaceID is the ENI id

=head2 primary-ip-address

PrimaryIPAddress is the primary IP on ENI

=head2 private-ipsets

PrivateIPSets is the list of all IPs on the ENI, including PrimaryIPAddress

=head2 security-groupids

SecurityGroupIDs is the security group ids used by this ENI

=head2 tags

Tags is the tags on this ENI

=head2 type

Type is the ENI type Primary or Secondary

=head2 vpc

VPC is the vpc to which the ENI belongs

=head2 vswitch

VSwitch is the vSwitch the ENI is using

=head2 zone-id

ZoneID is the zone to which the ENI belongs

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
