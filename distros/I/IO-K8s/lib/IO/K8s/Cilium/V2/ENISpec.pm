package IO::K8s::Cilium::V2::ENISpec;
# ABSTRACT: ENI is the AWS ENI specific configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'availability-zone'         => Str;
k8s 'delete-on-termination'     => Bool;
k8s 'disable-prefix-delegation' => Bool;
k8s 'exclude-interface-tags'    => { Str => 1 };
k8s 'first-interface-index'     => Int, { minimum => 0 };
k8s 'instance-type'             => Str;
k8s 'node-subnet-id'            => Str;
k8s 'security-group-tags'       => { Str => 1 };
k8s 'security-groups'           => [Str];
k8s 'subnet-ids'                => [Str];
k8s 'subnet-tags'               => { Str => 1 };
k8s 'use-primary-address'       => Bool;
k8s 'vpc-id'                    => Str;














1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::ENISpec - ENI is the AWS ENI specific configuration.

=head1 VERSION

version 1.108

=head2 availability-zone

AvailabilityZone is the availability zone to use when allocating
ENIs.

=head2 delete-on-termination

DeleteOnTermination defines that the ENI should be deleted when the
associated instance is terminated. If the parameter is not set the
default behavior is to delete the ENI on instance termination.

=head2 disable-prefix-delegation

DisablePrefixDelegation determines whether ENI prefix delegation should be
disabled on this node.

=head2 exclude-interface-tags

ExcludeInterfaceTags is the list of tags to use when excluding ENIs for
Cilium IP allocation. Any interface matching this set of tags will not
be managed by Cilium.

=head2 first-interface-index

FirstInterfaceIndex is the index of the first ENI to use for IP
allocation, e.g. if the node has eth0, eth1, eth2 and
FirstInterfaceIndex is set to 1, then only eth1 and eth2 will be
used for IP allocation, eth0 will be ignored for PodIP allocation.

=head2 instance-type

InstanceType is the AWS EC2 instance type, e.g. "m5.large"

=head2 node-subnet-id

NodeSubnetID is the subnet of the primary ENI the instance was brought up
with. It is used as a sensible default subnet to create ENIs in.

=head2 security-group-tags

SecurityGroupTags is the list of tags to use when evaliating what
AWS security groups to use for the ENI.

=head2 security-groups

SecurityGroups is the list of security groups to attach to any ENI
that is created and attached to the instance.

=head2 subnet-ids

SubnetIDs is the list of subnet ids to use when evaluating what AWS
subnets to use for ENI and IP allocation.

=head2 subnet-tags

SubnetTags is the list of tags to use when evaluating what AWS
subnets to use for ENI and IP allocation.

=head2 use-primary-address

UsePrimaryAddress determines whether an ENI's primary address
should be available for allocations on the node

=head2 vpc-id

VpcID is the VPC ID to use when allocating ENIs.

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
