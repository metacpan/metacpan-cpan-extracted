package IO::K8s::PrometheusOperator::V1::Prometheus;
# ABSTRACT: The `Prometheus` custom resource definition (CRD) defines a desired [Prometheus](https://prometheus.io/docs/prometheus) setup to run in a Kubernetes cluster.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'monitoring.coreos.com/v1',
    resource_plural => 'prometheuses';
with 'IO::K8s::Role::Namespaced';

k8s spec   => '+IO::K8s::PrometheusOperator::V1::PrometheusSpec', { required => 'schema' };
k8s status => '+IO::K8s::PrometheusOperator::V1::PrometheusStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::Prometheus - The `Prometheus` custom resource definition (CRD) defines a desired [Prometheus](https://prometheus.io/docs/prometheus) setup to run in a Kubernetes cluster.

=head1 VERSION

version 1.108

=head2 spec

spec defines the specification of the desired behavior of the Prometheus cluster. More info:
https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

=head2 status

status defines the most recent observed status of the Prometheus cluster. Read-only.
More info:
https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#spec-and-status

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
