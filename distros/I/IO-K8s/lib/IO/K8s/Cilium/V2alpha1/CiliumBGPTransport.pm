package IO::K8s::Cilium::V2alpha1::CiliumBGPTransport;
# ABSTRACT: Transport defines the BGP transport parameters for the peer.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s localPort => Int, { minimum => 1, maximum => 65535 };
k8s peerPort  => Int, { minimum => 1, maximum => 65535, default => 179 };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumBGPTransport - Transport defines the BGP transport parameters for the peer.

=head1 VERSION

version 1.108

=head2 localPort

Deprecated
LocalPort is the local port to be used for the BGP session.

If not specified, ephemeral port will be picked to initiate a connection.

This field is deprecated and will be removed in a future release.
Local port configuration is unnecessary and is not recommended.

=head2 peerPort

PeerPort is the peer port to be used for the BGP session.

If not specified, defaults to TCP port 179.

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
