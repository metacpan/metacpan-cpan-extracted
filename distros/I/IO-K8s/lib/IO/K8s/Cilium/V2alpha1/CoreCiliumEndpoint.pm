package IO::K8s::Cilium::V2alpha1::CoreCiliumEndpoint;
# ABSTRACT: CoreCiliumEndpoint is slim version of status of CiliumEndpoint.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s encryption        => '+IO::K8s::Cilium::V2alpha1::EncryptionSpec';
k8s id                => Int;
k8s name              => Str;
k8s 'named-ports'     => ['+IO::K8s::Cilium::V2alpha1::Port'];
k8s networking        => '+IO::K8s::Cilium::V2alpha1::EndpointNetworking';
k8s 'pod-uid'         => Str;
k8s 'service-account' => Str;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CoreCiliumEndpoint - CoreCiliumEndpoint is slim version of status of CiliumEndpoint.

=head1 VERSION

version 1.108

=head2 encryption

EncryptionSpec defines the encryption relevant configuration of a node.

=head2 id

IdentityID is the numeric identity of the endpoint

=head2 name

Name indicate as CiliumEndpoint name.

=head2 named-ports

NamedPorts List of named Layer 4 port and protocol pairs which will be used in Network
Policy specs.

swagger:model NamedPorts

=head2 networking

EndpointNetworking is the addressing information of an endpoint.

=head2 pod-uid

PodUID is the UID of the Pod that owns this endpoint.

=head2 service-account

ServiceAccount is the service account of the endpoint.

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
