package IO::K8s::Cilium::V2::CiliumBGPNodeStatus;
# ABSTRACT: Status is the most recently observed status of the CiliumBGPNodeConfig.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s bgpInstances => ['+IO::K8s::Cilium::V2::CiliumBGPNodeInstanceStatus'];
k8s conditions   => ['Meta::V1::Condition'];



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::CiliumBGPNodeStatus - Status is the most recently observed status of the CiliumBGPNodeConfig.

=head1 VERSION

version 1.108

=head2 bgpInstances

BGPInstances is the status of the BGP instances on the node.

=head2 conditions

The current conditions of the CiliumBGPNodeConfig

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
