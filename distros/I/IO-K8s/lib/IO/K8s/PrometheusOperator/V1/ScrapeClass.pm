package IO::K8s::PrometheusOperator::V1::ScrapeClass;
# ABSTRACT: ScrapeClass
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s attachMetadata         => '+IO::K8s::PrometheusOperator::V1::AttachMetadata';
k8s authorization          => '+IO::K8s::PrometheusOperator::V1::Authorization';
k8s default                => Bool;
k8s fallbackScrapeProtocol => Str, { enum => [qw(PrometheusProto OpenMetricsText0.0.1 OpenMetricsText1.0.0 PrometheusText0.0.4 PrometheusText1.0.0)] };
k8s metricRelabelings      => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s name                   => Str, { required => 'schema' };
k8s relabelings            => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s tlsConfig              => '+IO::K8s::PrometheusOperator::V1::TLSConfig';









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ScrapeClass - ScrapeClass

=head1 VERSION

version 1.108

=head2 attachMetadata

attachMetadata defines additional metadata to the discovered targets.
When the scrape object defines its own configuration, it takes
precedence over the scrape class configuration.

=head2 authorization

authorization section for the ScrapeClass.
It will only apply if the scrape resource doesn't specify any Authorization.

=head2 default

default defines that the scrape applies to all scrape objects that
don't configure an explicit scrape class name.

Only one scrape class can be set as the default.

=head2 fallbackScrapeProtocol

fallbackScrapeProtocol defines the protocol to use if a scrape returns blank, unparseable, or otherwise invalid Content-Type.
It will only apply if the scrape resource doesn't specify any FallbackScrapeProtocol

It requires Prometheus >= v3.0.0.

=head2 metricRelabelings

metricRelabelings defines the relabeling rules to apply to all samples before ingestion.

The Operator adds the scrape class metric relabelings defined here.
Then the Operator adds the target-specific metric relabelings defined in ServiceMonitors, PodMonitors, Probes and ScrapeConfigs.
Then the Operator adds namespace enforcement relabeling rule, specified in '.spec.enforcedNamespaceLabel'.

More info: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#metric_relabel_configs

=head2 name

name of the scrape class.

=head2 relabelings

relabelings defines the relabeling rules to apply to all scrape targets.

The Operator automatically adds relabelings for a few standard Kubernetes fields
like `__meta_kubernetes_namespace` and `__meta_kubernetes_service_name`.
Then the Operator adds the scrape class relabelings defined here.
Then the Operator adds the target-specific relabelings defined in the scrape object.

More info: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config

=head2 tlsConfig

tlsConfig defines the TLS settings to use for the scrape. When the
scrape objects define their own CA, certificate and/or key, they take
precedence over the corresponding scrape class fields.

For now only the `caFile`, `certFile` and `keyFile` fields are supported.

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
