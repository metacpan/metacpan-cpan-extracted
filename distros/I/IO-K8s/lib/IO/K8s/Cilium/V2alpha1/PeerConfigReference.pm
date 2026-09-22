package IO::K8s::Cilium::V2alpha1::PeerConfigReference;
# ABSTRACT: PeerConfigRef is a reference to a peer configuration resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s group => Str, { default => 'cilium.io' };
k8s kind  => Str, { default => 'CiliumBGPPeerConfig' };
k8s name  => Str, { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::PeerConfigReference - PeerConfigRef is a reference to a peer configuration resource.

=head1 VERSION

version 1.108

=head2 group

Group is the group of the peer config resource.
If not specified, the default of "cilium.io" is used.

=head2 kind

Kind is the kind of the peer config resource.
If not specified, the default of "CiliumBGPPeerConfig" is used.

=head2 name

Name is the name of the peer config resource.
Name refers to the name of a Kubernetes object (typically a CiliumBGPPeerConfig).

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
