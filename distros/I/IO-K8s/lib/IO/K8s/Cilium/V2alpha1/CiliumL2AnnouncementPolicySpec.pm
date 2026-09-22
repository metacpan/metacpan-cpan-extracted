package IO::K8s::Cilium::V2alpha1::CiliumL2AnnouncementPolicySpec;
# ABSTRACT: Spec is a human readable description of a L2 announcement policy
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s externalIPs     => Bool;
k8s interfaces      => [Str];
k8s loadBalancerIPs => Bool;
k8s nodeSelector    => 'Meta::V1::LabelSelector';
k8s serviceSelector => 'Meta::V1::LabelSelector';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumL2AnnouncementPolicySpec - Spec is a human readable description of a L2 announcement policy

=head1 VERSION

version 1.108

=head2 externalIPs

If true, the external IPs of the services are announced

=head2 interfaces

A list of regular expressions that express which network interface(s) should be used
to announce the services over. If nil, all network interfaces are used.

=head2 loadBalancerIPs

If true, the loadbalancer IPs of the services are announced

If nil this policy applies to all services.

=head2 nodeSelector

NodeSelector selects a group of nodes which will announce the IPs for
the services selected by the service selector.

If nil this policy applies to all nodes.

=head2 serviceSelector

ServiceSelector selects a set of services which will be announced over L2 networks.
The loadBalancerClass for a service must be nil or specify a supported class, e.g.
"io.cilium/l2-announcer". Refer to the following document for additional details
regarding load balancer classes:

  https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-class

If nil this policy applies to all services.

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
