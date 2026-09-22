package IO::K8s::Cilium::V2alpha1::CiliumEndpointSlice;
# ABSTRACT: CiliumEndpointSlice contains a group of CoreCiliumendpoints.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2alpha1',
    resource_plural => 'ciliumendpointslices';

k8s endpoints => ['+IO::K8s::Cilium::V2alpha1::CoreCiliumEndpoint'], { required => 'schema' };
k8s namespace => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumEndpointSlice - CiliumEndpointSlice contains a group of CoreCiliumendpoints.

=head1 VERSION

version 1.108

=head2 endpoints

Endpoints is a list of coreCEPs packed in a CiliumEndpointSlice

=head2 namespace

Namespace indicate as CiliumEndpointSlice namespace.
All the CiliumEndpoints within the same namespace are put together
in CiliumEndpointSlice.

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
