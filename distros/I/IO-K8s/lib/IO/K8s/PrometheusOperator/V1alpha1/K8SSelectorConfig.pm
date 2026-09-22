package IO::K8s::PrometheusOperator::V1alpha1::K8SSelectorConfig;
# ABSTRACT: K8SSelectorConfig is Kubernetes Selector Config
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s field => Str;
k8s label => Str;
k8s role  => Str, { required => 'schema', enum => [qw(Pod Endpoints Ingress Service Node EndpointSlice)] };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::K8SSelectorConfig - K8SSelectorConfig is Kubernetes Selector Config

=head1 VERSION

version 1.108

=head2 field

field defines an optional field selector to limit the service discovery to resources which have fields with specific values.
e.g: `metadata.name=foobar`

=head2 label

label defines an optional label selector to limit the service discovery to resources with specific labels and label values.
e.g: `node.kubernetes.io/instance-type=master`

=head2 role

role defines the type of Kubernetes resource to limit the service discovery to.
Accepted values are: Node, Pod, Endpoints, EndpointSlice, Service, Ingress.

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
