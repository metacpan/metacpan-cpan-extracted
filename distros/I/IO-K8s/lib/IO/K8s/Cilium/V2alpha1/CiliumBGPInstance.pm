package IO::K8s::Cilium::V2alpha1::CiliumBGPInstance;
# ABSTRACT: CiliumBGPInstance
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s localASN  => Int, { minimum => 1, maximum => 4294967295 };
k8s localPort => Int, { minimum => 1, maximum => 65535 };
k8s name      => Str, { required => 'schema' };
k8s peers     => ['+IO::K8s::Cilium::V2alpha1::CiliumBGPPeer'];





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumBGPInstance - CiliumBGPInstance

=head1 VERSION

version 1.108

=head2 localASN

LocalASN is the ASN of this BGP instance.
Supports extended 32bit ASNs.

=head2 localPort

LocalPort is the port on which the BGP daemon listens for incoming connections.

If not specified, BGP instance will not listen for incoming connections.

=head2 name

Name is the name of the BGP instance. It is a unique identifier for the BGP instance
within the cluster configuration.

=head2 peers

Peers is a list of neighboring BGP peers for this virtual router

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
