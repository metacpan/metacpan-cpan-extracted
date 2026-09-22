package IO::K8s::Cilium::V2alpha1::CiliumBGPClusterConfigSpec;
# ABSTRACT: Spec defines the desired cluster configuration of the BGP control plane.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s bgpInstances => ['+IO::K8s::Cilium::V2alpha1::CiliumBGPInstance'], { required => 'schema' };
k8s nodeSelector => 'Meta::V1::LabelSelector';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumBGPClusterConfigSpec - Spec defines the desired cluster configuration of the BGP control plane.

=head1 VERSION

version 1.108

=head2 bgpInstances

A list of CiliumBGPInstance(s) which instructs
the BGP control plane how to instantiate virtual BGP routers.

=head2 nodeSelector

NodeSelector selects a group of nodes where this BGP Cluster
config applies.
If empty / nil this config applies to all nodes.

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
