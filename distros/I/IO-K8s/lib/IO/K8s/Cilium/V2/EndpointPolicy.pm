package IO::K8s::Cilium::V2::EndpointPolicy;
# ABSTRACT: EndpointPolicy represents the endpoint's policy by listing all allowed ingress and egress identities in combination with L4 port and protocol.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s egress  => '+IO::K8s::Cilium::V2::EndpointPolicyDirection';
k8s ingress => '+IO::K8s::Cilium::V2::EndpointPolicyDirection';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EndpointPolicy - EndpointPolicy represents the endpoint's policy by listing all allowed ingress and egress identities in combination with L4 port and protocol.

=head1 VERSION

version 1.108

=head2 egress

EndpointPolicyDirection is the list of allowed identities per direction.

=head2 ingress

EndpointPolicyDirection is the list of allowed identities per direction.

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
