package IO::K8s::Cilium::V2::EndpointStatus;
# ABSTRACT: EndpointStatus is the status of a Cilium endpoint.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s controllers            => ['+IO::K8s::Cilium::V2::ControllerStatus'];
k8s encryption             => '+IO::K8s::Cilium::V2::EncryptionSpec';
k8s 'external-identifiers' => '+IO::K8s::Cilium::V2::EndpointIdentifiers';
k8s health                 => '+IO::K8s::Cilium::V2::EndpointHealth';
k8s id                     => Int;
k8s identity               => '+IO::K8s::Cilium::V2::EndpointIdentity';
k8s log                    => ['+IO::K8s::Cilium::V2::EndpointStatusChange'];
k8s 'named-ports'          => ['+IO::K8s::Cilium::V2::Port'];
k8s networking             => '+IO::K8s::Cilium::V2::EndpointNetworking';
k8s policy                 => '+IO::K8s::Cilium::V2::EndpointPolicy';
k8s 'service-account'      => Str;
k8s state                  => Str, { enum => [qw(creating waiting-for-identity not-ready waiting-to-regenerate regenerating restoring ready disconnecting disconnected invalid)] };













1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EndpointStatus - EndpointStatus is the status of a Cilium endpoint.

=head1 VERSION

version 1.108

=head2 controllers

Controllers is the list of failing controllers for this endpoint.

=head2 encryption

Encryption is the encryption configuration of the node

=head2 external-identifiers

ExternalIdentifiers is a set of identifiers to identify the endpoint
apart from the pod name. This includes container runtime IDs.

=head2 health

Health is the overall endpoint & subcomponent health.

=head2 id

ID is the cilium-agent-local ID of the endpoint.

=head2 identity

Identity is the security identity associated with the endpoint

=head2 log

Log is the list of the last few warning and error log entries

=head2 named-ports

NamedPorts List of named Layer 4 port and protocol pairs which will be used in Network
Policy specs.

swagger:model NamedPorts

=head2 networking

Networking is the networking properties of the endpoint.

=head2 policy

EndpointPolicy represents the endpoint's policy by listing all allowed
ingress and egress identities in combination with L4 port and protocol.

=head2 service-account

ServiceAccount is the service account associated with the endpoint

=head2 state

State is the state of the endpoint.

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
