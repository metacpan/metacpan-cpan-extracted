package IO::K8s::PrometheusOperator::V1::PrometheusRule;
# ABSTRACT: The `PrometheusRule` custom resource definition (CRD) defines [alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) and [recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) rules to be evaluated by `Prometheus` or `ThanosRuler` objects.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'monitoring.coreos.com/v1',
    resource_plural => 'prometheusrules';
with 'IO::K8s::Role::Namespaced';

k8s spec   => '+IO::K8s::PrometheusOperator::V1::PrometheusRuleSpec', { required => 'schema' };
k8s status => '+IO::K8s::PrometheusOperator::V1::ConfigResourceStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PrometheusRule - The `PrometheusRule` custom resource definition (CRD) defines [alerting](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) and [recording](https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/) rules to be evaluated by `Prometheus` or `ThanosRuler` objects.

=head1 VERSION

version 1.108

=head2 spec

spec defines the specification of desired alerting rule definitions for Prometheus.

=head2 status

status defines the status subresource. It is under active development and is updated only when the
"StatusForConfigurationResources" feature gate is enabled.

Most recent observed status of the PrometheusRule. Read-only.
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
