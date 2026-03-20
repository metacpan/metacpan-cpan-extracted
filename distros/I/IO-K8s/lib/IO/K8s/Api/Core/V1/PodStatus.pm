package IO::K8s::Api::Core::V1::PodStatus;
# ABSTRACT: PodStatus represents information about the status of a pod. Status may trail the actual state of a system, especially if the node that hosts the pod cannot contact the control plane.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s conditions => ['Core::V1::PodCondition'];


k8s containerStatuses => ['Core::V1::ContainerStatus'];


k8s ephemeralContainerStatuses => ['Core::V1::ContainerStatus'];


k8s hostIP => Str;


k8s hostIPs => ['Core::V1::HostIP'];


k8s initContainerStatuses => ['Core::V1::ContainerStatus'];


k8s message => Str;


k8s nominatedNodeName => Str;


k8s phase => Str;


k8s podIP => Str;


k8s podIPs => ['Core::V1::PodIP'];


k8s qosClass => Str;


k8s reason => Str;


k8s resize => Str;


k8s resourceClaimStatuses => ['Core::V1::PodResourceClaimStatus'];


k8s startTime => Time;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::PodStatus - PodStatus represents information about the status of a pod. Status may trail the actual state of a system, especially if the node that hosts the pod cannot contact the control plane.

=head1 VERSION

version 1.009

=head2 conditions

Current service state of pod. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-conditions

=head2 containerStatuses

The list has one entry per container in the manifest. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-and-container-status

=head2 ephemeralContainerStatuses

Status for any ephemeral containers that have run in this pod.

=head2 hostIP

hostIP holds the IP address of the host to which the pod is assigned. Empty if the pod has not started yet. A pod can be assigned to a node that has a problem in kubelet which in turns mean that HostIP will not be updated even if there is a node is assigned to pod

=head2 hostIPs

hostIPs holds the IP addresses allocated to the host. If this field is specified, the first entry must match the hostIP field. This list is empty if the pod has not started yet. A pod can be assigned to a node that has a problem in kubelet which in turns means that HostIPs will not be updated even if there is a node is assigned to this pod.

=head2 initContainerStatuses

The list has one entry per init container in the manifest. The most recent successful init container will have ready = true, the most recently started container will have startTime set. More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-and-container-status

=head2 message

A human readable message indicating details about why the pod is in this condition.

=head2 nominatedNodeName

nominatedNodeName is set only when this pod preempts other pods on the node, but it cannot be scheduled right away as preemption victims receive their graceful termination periods. This field does not guarantee that the pod will be scheduled on this node. Scheduler may decide to place the pod elsewhere if other nodes become available sooner. Scheduler may also decide to give the resources on this node to a higher priority pod that is created after preemption. As a result, this field may be different than PodSpec.nodeName when the pod is scheduled.

=head2 phase

The phase of a Pod is a simple, high-level summary of where the Pod is in its lifecycle. The conditions array, the reason and message fields, and the individual container status arrays contain more detail about the pod's status. There are five possible phase values:

Pending: The pod has been accepted by the Kubernetes system, but one or more of the container images has not been created. This includes time before being scheduled as well as time spent downloading images over the network, which could take a while. Running: The pod has been bound to a node, and all of the containers have been created. At least one container is still running, or is in the process of starting or restarting. Succeeded: All containers in the pod have terminated in success, and will not be restarted. Failed: All containers in the pod have terminated, and at least one container has terminated in failure. The container either exited with non-zero status or was terminated by the system. Unknown: For some reason the state of the pod could not be obtained, typically due to an error in communicating with the host of the pod.

More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#pod-phase

=head2 podIP

podIP address allocated to the pod. Routable at least within the cluster. Empty if not yet allocated.

=head2 podIPs

podIPs holds the IP addresses allocated to the pod. If this field is specified, the 0th entry must match the podIP field. Pods may be allocated at most 1 value for each of IPv4 and IPv6. This list is empty if no IPs have been allocated yet.

=head2 qosClass

The Quality of Service (QOS) classification assigned to the pod based on resource requirements See PodQOSClass type for available QOS classes More info: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/#quality-of-service-classes

=head2 reason

A brief CamelCase message indicating details about why the pod is in this state. e.g. 'Evicted'

=head2 resize

Status of resources resize desired for pod's containers. It is empty if no resources resize is pending. Any changes to container resources will automatically set this to "Proposed"

=head2 resourceClaimStatuses

Status of resource claims.

=head2 startTime

RFC 3339 date and time at which the object was acknowledged by the Kubelet. This is before the Kubelet pulled the container image(s) for the pod.

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
