package IO::K8s::Cilium::V2::EndpointIdentifiers;
# ABSTRACT: ExternalIdentifiers is a set of identifiers to identify the endpoint apart from the pod name.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s 'cni-attachment-id'  => Str;
k8s 'container-id'       => Str;
k8s 'container-name'     => Str;
k8s 'docker-endpoint-id' => Str;
k8s 'docker-network-id'  => Str;
k8s 'k8s-namespace'      => Str;
k8s 'k8s-pod-name'       => Str;
k8s 'pod-name'           => Str;









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EndpointIdentifiers - ExternalIdentifiers is a set of identifiers to identify the endpoint apart from the pod name.

=head1 VERSION

version 1.108

=head2 cni-attachment-id

ID assigned to this attachment by container runtime

=head2 container-id

ID assigned by container runtime (deprecated, may not be unique)

=head2 container-name

Name assigned to container (deprecated, may not be unique)

=head2 docker-endpoint-id

Docker endpoint ID

=head2 docker-network-id

Docker network ID

=head2 k8s-namespace

K8s namespace for this endpoint (deprecated, may not be unique)

=head2 k8s-pod-name

K8s pod name for this endpoint (deprecated, may not be unique)

=head2 pod-name

K8s pod for this endpoint (deprecated, may not be unique)

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
