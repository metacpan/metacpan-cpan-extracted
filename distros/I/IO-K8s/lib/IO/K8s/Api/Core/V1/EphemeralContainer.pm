package IO::K8s::Api::Core::V1::EphemeralContainer;
# ABSTRACT: An EphemeralContainer is a temporary container that you may add to an existing Pod for user-initiated activities such as debugging. Ephemeral containers have no resource or scheduling guarantees, and they will not be restarted when they exit or when a Pod is removed or restarted. The kubelet may evict a Pod if an ephemeral container causes the Pod to exceed its resource allocation. To add an ephemeral container, use the ephemeralcontainers subresource of an existing Pod. Ephemeral containers may not be removed or restarted.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s args => [Str];


k8s command => [Str];


k8s env => ['Core::V1::EnvVar'];


k8s envFrom => ['Core::V1::EnvFromSource'];


k8s image => Str;


k8s imagePullPolicy => Str;


k8s lifecycle => 'Core::V1::Lifecycle';


k8s livenessProbe => 'Core::V1::Probe';


k8s name => Str, 'required';


k8s ports => ['Core::V1::ContainerPort'];


k8s readinessProbe => 'Core::V1::Probe';


k8s resizePolicy => ['Core::V1::ContainerResizePolicy'];


k8s resources => 'Core::V1::ResourceRequirements';


k8s restartPolicy => Str;


k8s securityContext => 'Core::V1::SecurityContext';


k8s startupProbe => 'Core::V1::Probe';


k8s stdin => Bool;


k8s stdinOnce => Bool;


k8s targetContainerName => Str;


k8s terminationMessagePath => Str;


k8s terminationMessagePolicy => Str;


k8s tty => Bool;


k8s volumeDevices => ['Core::V1::VolumeDevice'];


k8s volumeMounts => ['Core::V1::VolumeMount'];


k8s workingDir => Str;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::EphemeralContainer - An EphemeralContainer is a temporary container that you may add to an existing Pod for user-initiated activities such as debugging. Ephemeral containers have no resource or scheduling guarantees, and they will not be restarted when they exit or when a Pod is removed or restarted. The kubelet may evict a Pod if an ephemeral container causes the Pod to exceed its resource allocation. To add an ephemeral container, use the ephemeralcontainers subresource of an existing Pod. Ephemeral containers may not be removed or restarted.

=head1 VERSION

version 1.008

=head2 args

Arguments to the entrypoint. The image's CMD is used if this is not provided. Variable references $(VAR_NAME) are expanded using the container's environment. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. "$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)". Escaped references will never be expanded, regardless of whether the variable exists or not. Cannot be updated. More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell

=head2 command

Entrypoint array. Not executed within a shell. The image's ENTRYPOINT is used if this is not provided. Variable references $(VAR_NAME) are expanded using the container's environment. If a variable cannot be resolved, the reference in the input string will be unchanged. Double $$ are reduced to a single $, which allows for escaping the $(VAR_NAME) syntax: i.e. "$$(VAR_NAME)" will produce the string literal "$(VAR_NAME)". Escaped references will never be expanded, regardless of whether the variable exists or not. Cannot be updated. More info: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/#running-a-command-in-a-shell

=head2 env

List of environment variables to set in the container. Cannot be updated.

=head2 envFrom

List of sources to populate environment variables in the container. The keys defined within a source must be a C_IDENTIFIER. All invalid keys will be reported as an event when the container is starting. When a key exists in multiple sources, the value associated with the last source will take precedence. Values defined by an Env with a duplicate key will take precedence. Cannot be updated.

=head2 image

Container image name. More info: https://kubernetes.io/docs/concepts/containers/images

=head2 imagePullPolicy

Image pull policy. One of Always, Never, IfNotPresent. Defaults to Always if :latest tag is specified, or IfNotPresent otherwise. Cannot be updated. More info: https://kubernetes.io/docs/concepts/containers/images#updating-images

=head2 lifecycle

Lifecycle is not allowed for ephemeral containers.

=head2 livenessProbe

Probes are not allowed for ephemeral containers.

=head2 name

Name of the ephemeral container specified as a DNS_LABEL. This name must be unique among all containers, init containers and ephemeral containers.

=head2 ports

Ports are not allowed for ephemeral containers.

=head2 readinessProbe

Probes are not allowed for ephemeral containers.

=head2 resizePolicy

Resources resize policy for the container.

=head2 resources

Resources are not allowed for ephemeral containers. Ephemeral containers use spare resources already allocated to the pod.

=head2 restartPolicy

Restart policy for the container to manage the restart behavior of each container within a pod. This may only be set for init containers. You cannot set this field on ephemeral containers.

=head2 securityContext

Optional: SecurityContext defines the security options the ephemeral container should be run with. If set, the fields of SecurityContext override the equivalent fields of PodSecurityContext.

=head2 startupProbe

Probes are not allowed for ephemeral containers.

=head2 stdin

Whether this container should allocate a buffer for stdin in the container runtime. If this is not set, reads from stdin in the container will always result in EOF. Default is false.

=head2 stdinOnce

Whether the container runtime should close the stdin channel after it has been opened by a single attach. When stdin is true the stdin stream will remain open across multiple attach sessions. If stdinOnce is set to true, stdin is opened on container start, is empty until the first client attaches to stdin, and then remains open and accepts data until the client disconnects, at which time stdin is closed and remains closed until the container is restarted. If this flag is false, a container processes that reads from stdin will never receive an EOF. Default is false

=head2 targetContainerName

If set, the name of the container from PodSpec that this ephemeral container targets. The ephemeral container will be run in the namespaces (IPC, PID, etc) of this container. If not set then the ephemeral container uses the namespaces configured in the Pod spec.

The container runtime must implement support for this feature. If the runtime does not support namespace targeting then the result of setting this field is undefined.

=head2 terminationMessagePath

Optional: Path at which the file to which the container's termination message will be written is mounted into the container's filesystem. Message written is intended to be brief final status, such as an assertion failure message. Will be truncated by the node if greater than 4096 bytes. The total message length across all containers will be limited to 12kb. Defaults to /dev/termination-log. Cannot be updated.

=head2 terminationMessagePolicy

Indicate how the termination message should be populated. File will use the contents of terminationMessagePath to populate the container status message on both success and failure. FallbackToLogsOnError will use the last chunk of container log output if the termination message file is empty and the container exited with an error. The log output is limited to 2048 bytes or 80 lines, whichever is smaller. Defaults to File. Cannot be updated.

=head2 tty

Whether this container should allocate a TTY for itself, also requires 'stdin' to be true. Default is false.

=head2 volumeDevices

volumeDevices is the list of block devices to be used by the container.

=head2 volumeMounts

Pod volumes to mount into the container's filesystem. Subpath mounts are not allowed for ephemeral containers. Cannot be updated.

=head2 workingDir

Container's working directory. If not specified, the container runtime's default will be used, which might be configured in the container image. Cannot be updated.

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
