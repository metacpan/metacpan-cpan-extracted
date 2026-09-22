package IO::K8s::GatewayAPI::V1::ReferenceGrantSpec;
# ABSTRACT: Spec defines the desired state of ReferenceGrant.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s from => ['+IO::K8s::GatewayAPI::V1::ReferenceGrantFrom'], { required => 'schema' };
k8s to   => ['+IO::K8s::GatewayAPI::V1::ReferenceGrantTo'], { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::ReferenceGrantSpec - Spec defines the desired state of ReferenceGrant.

=head1 VERSION

version 1.108

=head2 from

From describes the trusted namespaces and kinds that can reference the
resources described in "To". Each entry in this list MUST be considered
to be an additional place that references can be valid from, or to put
this another way, entries MUST be combined using OR.

Support: Core

=head2 to

To describes the resources that may be referenced by the resources
described in "From". Each entry in this list MUST be considered to be an
additional place that references can be valid to, or to put this another
way, entries MUST be combined using OR.

Support: Core

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
