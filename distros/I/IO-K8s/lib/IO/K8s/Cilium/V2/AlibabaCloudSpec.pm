package IO::K8s::Cilium::V2::AlibabaCloudSpec;
# ABSTRACT: AlibabaCloud is the AlibabaCloud IPAM specific configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'availability-zone'   => Str;
k8s 'cidr-block'          => Str;
k8s 'instance-type'       => Str;
k8s 'security-group-tags' => { Str => 1 };
k8s 'security-groups'     => [Str];
k8s 'vpc-id'              => Str;
k8s 'vswitch-tags'        => { Str => 1 };
k8s vswitches             => [Str];









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::AlibabaCloudSpec - AlibabaCloud is the AlibabaCloud IPAM specific configuration.

=head1 VERSION

version 1.108

=head2 availability-zone

AvailabilityZone is the availability zone to use when allocating
ENIs.

=head2 cidr-block

CIDRBlock is vpc ipv4 CIDR

=head2 instance-type

InstanceType is the ECS instance type, e.g. "ecs.g6.2xlarge"

=head2 security-group-tags

SecurityGroupTags is the list of tags to use when evaluating which
security groups to use for the ENI.

=head2 security-groups

SecurityGroups is the list of security groups to attach to any ENI
that is created and attached to the instance.

=head2 vpc-id

VPCID is the VPC ID to use when allocating ENIs.

=head2 vswitch-tags

VSwitchTags is the list of tags to use when evaluating which
vSwitch to use for the ENI.

=head2 vswitches

VSwitches is the ID of vSwitch available for ENI

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
