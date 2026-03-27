package IO::K8s::Api::Node::V1::RuntimeClass;
# ABSTRACT: RuntimeClass defines a class of container runtime supported in the cluster. The RuntimeClass is used to determine which container runtime is used to run all containers in a pod. RuntimeClasses are manually defined by a user or cluster provisioner, and referenced in the PodSpec. The Kubelet is responsible for resolving the RuntimeClassName reference before running the pod.  For more details, see https://kubernetes.io/docs/concepts/containers/runtime-class/
our $VERSION = '1.100';
use IO::K8s::APIObject;


k8s handler => Str, 'required';


k8s overhead => 'Node::V1::Overhead';


k8s scheduling => 'Node::V1::Scheduling';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Node::V1::RuntimeClass - RuntimeClass defines a class of container runtime supported in the cluster. The RuntimeClass is used to determine which container runtime is used to run all containers in a pod. RuntimeClasses are manually defined by a user or cluster provisioner, and referenced in the PodSpec. The Kubelet is responsible for resolving the RuntimeClassName reference before running the pod.  For more details, see https://kubernetes.io/docs/concepts/containers/runtime-class/

=head1 VERSION

version 1.100

=head1 DESCRIPTION

RuntimeClass defines a class of container runtime supported in the cluster. The RuntimeClass is used to determine which container runtime is used to run all containers in a pod. RuntimeClasses are manually defined by a user or cluster provisioner, and referenced in the PodSpec. The Kubelet is responsible for resolving the RuntimeClassName reference before running the pod.  For more details, see https://kubernetes.io/docs/concepts/containers/runtime-class/

This is a Kubernetes API object. See L<IO::K8s::Role::APIObject> for
C<metadata>, C<api_version()>, and C<kind()>.

=head2 handler

handler specifies the underlying runtime and configuration that the CRI implementation will use to handle pods of this class. The possible values are specific to the node & CRI configuration.  It is assumed that all handlers are available on every node, and handlers of the same name are equivalent on every node. For example, a handler called "runc" might specify that the runc OCI runtime (using native Linux containers) will be used to run the containers in a pod. The Handler must be lowercase, conform to the DNS Label (RFC 1123) requirements, and is immutable.

=head2 overhead

overhead represents the resource overhead associated with running a pod for a given RuntimeClass. For more details, see
 https://kubernetes.io/docs/concepts/scheduling-eviction/pod-overhead/

=head2 scheduling

scheduling holds the scheduling constraints to ensure that pods running with this RuntimeClass are scheduled to nodes that support it. If scheduling is nil, this RuntimeClass is assumed to be supported by all nodes.

=head1 SEE ALSO

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#runtimeclass-v1-node.k8s.io>

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
