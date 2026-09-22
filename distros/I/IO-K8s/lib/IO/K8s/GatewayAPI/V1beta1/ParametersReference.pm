package IO::K8s::GatewayAPI::V1beta1::ParametersReference;
# ABSTRACT: ParametersRef is a reference to a resource that contains the configuration parameters corresponding to the GatewayClass.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s group     => Str, { required => 'schema', pattern => qr/^$|^[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*$/ };
k8s kind      => Str, { required => 'schema', pattern => qr/^[a-zA-Z]([-a-zA-Z0-9]*[a-zA-Z0-9])?$/ };
k8s name      => Str, { required => 'schema' };
k8s namespace => Str, { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::ParametersReference - ParametersRef is a reference to a resource that contains the configuration parameters corresponding to the GatewayClass.

=head1 VERSION

version 1.108

=head2 group

Group is the group of the referent.

=head2 kind

Kind is kind of the referent.

=head2 name

Name is the name of the referent.

=head2 namespace

Namespace is the namespace of the referent.
This field is required when referring to a Namespace-scoped resource and
MUST be unset when referring to a Cluster-scoped resource.

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
