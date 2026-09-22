package IO::K8s::Cilium::V2alpha1::IPPoolSpec;
# ABSTRACT: IPPoolSpec
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s allowFirstIP      => Bool, { default => 0 };
k8s allowLastIP       => Bool, { default => 0 };
k8s ipv4              => '+IO::K8s::Cilium::V2alpha1::IPv4PoolSpec';
k8s ipv6              => '+IO::K8s::Cilium::V2alpha1::IPv6PoolSpec';
k8s namespaceSelector => 'Meta::V1::LabelSelector';
k8s podSelector       => 'Meta::V1::LabelSelector';








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::IPPoolSpec - IPPoolSpec

=head1 VERSION

version 1.108

=head2 allowFirstIP

AllowFirstIP allows the first IP of each allocated CIDR to be used. If
unset or false, this IP is reserved. This field is ignored for /{31,32}
and /{127,128} CIDRs since reserving the first and last IPs would make
the CIDRs unusable. This field is immutable.

=head2 allowLastIP

AllowLastIP allows the last IP of each allocated CIDR to be used. If
unset or false, this IP is reserved. This field is ignored for /{31,32}
and /{127,128} CIDRs since reserving the first and last IPs would make
the CIDRs unusable. This field is immutable.

=head2 ipv4

IPv4 specifies the IPv4 CIDRs and mask sizes of the pool

=head2 ipv6

IPv6 specifies the IPv6 CIDRs and mask sizes of the pool

=head2 namespaceSelector

NamespaceSelector selects the set of Namespaces that are eligible to use
this pool. If both PodSelector and NamespaceSelector are specified, a Pod
must match both selectors to be eligible for IP allocation from this pool.

If NamespaceSelector is empty, the pool can be used by Pods in any namespace
(subject to PodSelector constraints).

=head2 podSelector

PodSelector selects the set of Pods that are eligible to receive IPs from
this pool when neither the Pod nor its Namespace specify an explicit
`ipam.cilium.io/*` annotation.

The selector can match on regular Pod labels and on the following synthetic
labels that Cilium adds for convenience:

io.kubernetes.pod.namespace – the Pod's namespace
io.kubernetes.pod.name      – the Pod's name

A single Pod must not match more than one pool for the same IP family.
If multiple pools match, IP allocation fails for that Pod and a warning event
is emitted in the namespace of the Pod.

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
