package IO::K8s::Api::Core::V1::NodeSpec;
# ABSTRACT: NodeSpec describes the attributes that a node is created with.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s configSource => 'Core::V1::NodeConfigSource';


k8s externalID => Str;


k8s podCIDR => Str;


k8s podCIDRs => [Str];


k8s providerID => Str;


k8s taints => ['Core::V1::Taint'];


k8s unschedulable => Bool;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Core::V1::NodeSpec - NodeSpec describes the attributes that a node is created with.

=head1 VERSION

version 1.008

=head2 configSource

Deprecated: Previously used to specify the source of the node's configuration for the DynamicKubeletConfig feature. This feature is removed.

=head2 externalID

Deprecated. Not all kubelets will set this field. Remove field after 1.13. see: https://issues.k8s.io/61966

=head2 podCIDR

PodCIDR represents the pod IP range assigned to the node.

=head2 podCIDRs

podCIDRs represents the IP ranges assigned to the node for usage by Pods on that node. If this field is specified, the 0th entry must match the podCIDR field. It may contain at most 1 value for each of IPv4 and IPv6.

=head2 providerID

ID of the node assigned by the cloud provider in the format: <ProviderName>://<ProviderSpecificNodeID>

=head2 taints

If specified, the node's taints.

=head2 unschedulable

Unschedulable controls node schedulability of new pods. By default, node is schedulable. More info: https://kubernetes.io/docs/concepts/nodes/node/#manual-node-administration

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
