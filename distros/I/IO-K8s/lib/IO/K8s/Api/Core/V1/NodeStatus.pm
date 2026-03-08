package IO::K8s::Api::Core::V1::NodeStatus;
# ABSTRACT: NodeStatus is information about the current status of a node.
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s addresses => ['Core::V1::NodeAddress'];


k8s allocatable => { Str => 1 };


k8s capacity => { Str => 1 };


k8s conditions => ['Core::V1::NodeCondition'];


k8s config => 'Core::V1::NodeConfigStatus';


k8s daemonEndpoints => 'Core::V1::NodeDaemonEndpoints';


k8s features => 'Core::V1::NodeFeatures';


k8s images => ['Core::V1::ContainerImage'];


k8s nodeInfo => 'Core::V1::NodeSystemInfo';


k8s phase => Str;


k8s runtimeHandlers => ['Core::V1::NodeRuntimeHandler'];


k8s volumesAttached => ['Core::V1::AttachedVolume'];


k8s volumesInUse => [Str];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::NodeStatus - NodeStatus is information about the current status of a node.

=head1 VERSION

version 1.006

=head2 addresses

List of addresses reachable to the node. Queried from cloud provider, if available. More info: https://kubernetes.io/docs/concepts/nodes/node/#addresses Note: This field is declared as mergeable, but the merge key is not sufficiently unique, which can cause data corruption when it is merged. Callers should instead use a full-replacement patch. See https://pr.k8s.io/79391 for an example. Consumers should assume that addresses can change during the lifetime of a Node. However, there are some exceptions where this may not be possible, such as Pods that inherit a Node's address in its own status or consumers of the downward API (status.hostIP).

=head2 allocatable

Allocatable represents the resources of a node that are available for scheduling. Defaults to Capacity.

=head2 capacity

Capacity represents the total resources of a node. More info: https://kubernetes.io/docs/reference/node/node-status/#capacity

=head2 conditions

Conditions is an array of current observed node conditions. More info: https://kubernetes.io/docs/concepts/nodes/node/#condition

=head2 config

Status of the config assigned to the node via the dynamic Kubelet config feature.

=head2 daemonEndpoints

Endpoints of daemons running on the Node.

=head2 features

Features describes the set of features implemented by the CRI implementation.

=head2 images

List of container images on this node

=head2 nodeInfo

Set of ids/uuids to uniquely identify the node. More info: https://kubernetes.io/docs/concepts/nodes/node/#info

=head2 phase

NodePhase is the recently observed lifecycle phase of the node. More info: https://kubernetes.io/docs/concepts/nodes/node/#phase The field is never populated, and now is deprecated.

=head2 runtimeHandlers

The available runtime handlers.

=head2 volumesAttached

List of volumes that are attached to the node.

=head2 volumesInUse

List of attachable volumes in use (mounted) by the node.

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
