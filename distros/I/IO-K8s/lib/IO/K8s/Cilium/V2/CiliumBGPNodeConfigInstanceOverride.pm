package IO::K8s::Cilium::V2::CiliumBGPNodeConfigInstanceOverride;
# ABSTRACT: CiliumBGPNodeConfigInstanceOverride defines configuration options which can be overridden for a specific BGP instance.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s localASN  => Int, { minimum => 1, maximum => 4294967295 };
k8s localPort => Int;
k8s name      => Str, { required => 'schema' };
k8s peers     => ['+IO::K8s::Cilium::V2::CiliumBGPNodeConfigPeerOverride'];
k8s routerID  => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumBGPNodeConfigInstanceOverride - CiliumBGPNodeConfigInstanceOverride defines configuration options which can be overridden for a specific BGP instance.

=head1 VERSION

version 1.108

=head2 localASN

LocalASN is the ASN to use for this BGP instance.

=head2 localPort

LocalPort is port to use for this BGP instance.

=head2 name

Name is the name of the BGP instance for which the configuration is overridden.

=head2 peers

Peers is a list of peer configurations to override.

=head2 routerID

RouterID is BGP router id to use for this instance. It must be unique across all BGP instances.

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
