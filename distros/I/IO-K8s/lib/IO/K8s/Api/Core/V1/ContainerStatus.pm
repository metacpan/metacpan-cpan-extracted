package IO::K8s::Api::Core::V1::ContainerStatus;
# ABSTRACT: ContainerStatus contains details for the current status of this container.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s allocatedResources => { Str => 1 };


k8s allocatedResourcesStatus => ['Core::V1::ResourceStatus'];


k8s containerID => Str;


k8s image => Str, 'required';


k8s imageID => Str, 'required';


k8s lastState => 'Core::V1::ContainerState';


k8s name => Str, 'required';


k8s ready => Bool, 'required';


k8s resources => 'Core::V1::ResourceRequirements';


k8s restartCount => Int, 'required';


k8s started => Bool;


k8s state => 'Core::V1::ContainerState';


k8s user => 'Core::V1::ContainerUser';


k8s volumeMounts => ['Core::V1::VolumeMountStatus'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::ContainerStatus - ContainerStatus contains details for the current status of this container.

=head1 VERSION

version 1.009

=head2 allocatedResources

AllocatedResources represents the compute resources allocated for this container by the node. Kubelet sets this value to Container.Resources.Requests upon successful pod admission and after successfully admitting desired pod resize.

=head2 allocatedResourcesStatus

AllocatedResourcesStatus represents the status of various resources allocated for this Pod.

=head2 containerID

ContainerID is the ID of the container in the format '<type>://<container_id>'. Where type is a container runtime identifier, returned from Version call of CRI API (for example "containerd").

=head2 image

Image is the name of container image that the container is running. The container image may not match the image used in the PodSpec, as it may have been resolved by the runtime. More info: https://kubernetes.io/docs/concepts/containers/images.

=head2 imageID

ImageID is the image ID of the container's image. The image ID may not match the image ID of the image used in the PodSpec, as it may have been resolved by the runtime.

=head2 lastState

LastTerminationState holds the last termination state of the container to help debug container crashes and restarts. This field is not populated if the container is still running and RestartCount is 0.

=head2 name

Name is a DNS_LABEL representing the unique name of the container. Each container in a pod must have a unique name across all container types. Cannot be updated.

=head2 ready

Ready specifies whether the container is currently passing its readiness check. The value will change as readiness probes keep executing. If no readiness probes are specified, this field defaults to true once the container is fully started (see Started field).

The value is typically used to determine whether a container is ready to accept traffic.

=head2 resources

Resources represents the compute resource requests and limits that have been successfully enacted on the running container after it has been started or has been successfully resized.

=head2 restartCount

RestartCount holds the number of times the container has been restarted. Kubelet makes an effort to always increment the value, but there are cases when the state may be lost due to node restarts and then the value may be reset to 0. The value is never negative.

=head2 started

Started indicates whether the container has finished its postStart lifecycle hook and passed its startup probe. Initialized as false, becomes true after startupProbe is considered successful. Resets to false when the container is restarted, or if kubelet loses state temporarily. In both cases, startup probes will run again. Is always true when no startupProbe is defined and container is running and has passed the postStart lifecycle hook. The null value must be treated the same as false.

=head2 state

State holds details about the container's current condition.

=head2 user

User represents user identity information initially attached to the first process of the container

=head2 volumeMounts

Status of volume mounts.

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
