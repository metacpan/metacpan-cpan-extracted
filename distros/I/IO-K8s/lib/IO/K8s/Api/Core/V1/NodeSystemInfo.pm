package IO::K8s::Api::Core::V1::NodeSystemInfo;
# ABSTRACT: NodeSystemInfo is a set of ids/uuids to uniquely identify the node.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s architecture => Str, 'required';


k8s bootID => Str, 'required';


k8s containerRuntimeVersion => Str, 'required';


k8s kernelVersion => Str, 'required';


k8s kubeProxyVersion => Str, 'required';


k8s kubeletVersion => Str, 'required';


k8s machineID => Str, 'required';


k8s operatingSystem => Str, 'required';


k8s osImage => Str, 'required';


k8s systemUUID => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::NodeSystemInfo - NodeSystemInfo is a set of ids/uuids to uniquely identify the node.

=head1 VERSION

version 1.009

=head2 architecture

The Architecture reported by the node

=head2 bootID

Boot ID reported by the node.

=head2 containerRuntimeVersion

ContainerRuntime Version reported by the node through runtime remote API (e.g. containerd://1.4.2).

=head2 kernelVersion

Kernel Version reported by the node from 'uname -r' (e.g. 3.16.0-0.bpo.4-amd64).

=head2 kubeProxyVersion

Deprecated: KubeProxy Version reported by the node.

=head2 kubeletVersion

Kubelet Version reported by the node.

=head2 machineID

MachineID reported by the node. For unique machine identification in the cluster this field is preferred. Learn more from man(5) machine-id: http://man7.org/linux/man-pages/man5/machine-id.5.html

=head2 operatingSystem

The Operating System reported by the node

=head2 osImage

OS Image reported by the node from /etc/os-release (e.g. Debian GNU/Linux 7 (wheezy)).

=head2 systemUUID

SystemUUID reported by the node. For unique machine identification MachineID is preferred. This field is specific to Red Hat hosts https://access.redhat.com/documentation/en-us/red_hat_subscription_management/1/html/rhsm/uuid

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
