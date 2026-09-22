package IO::K8s::Cilium::V2::EnvoyConfig;
# ABSTRACT: EnvoyConfig is a reference to the CEC or CCEC resource in which the listener is defined.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s kind => Str, { enum => [qw(CiliumEnvoyConfig CiliumClusterwideEnvoyConfig)] };
k8s name => Str, { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2::EnvoyConfig - EnvoyConfig is a reference to the CEC or CCEC resource in which the listener is defined.

=head1 VERSION

version 1.108

=head2 kind

Kind is the resource type being referred to. Defaults to CiliumEnvoyConfig or
CiliumClusterwideEnvoyConfig for CiliumNetworkPolicy and CiliumClusterwideNetworkPolicy,
respectively. The only case this is currently explicitly needed is when referring to a
CiliumClusterwideEnvoyConfig from CiliumNetworkPolicy, as using a namespaced listener
from a cluster scoped policy is not allowed.

=head2 name

Name is the resource name of the CiliumEnvoyConfig or CiliumClusterwideEnvoyConfig where
the listener is defined in.

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
