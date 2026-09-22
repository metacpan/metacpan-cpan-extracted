package IO::K8s::PrometheusOperator::V1::PodMonitorSpec;
# ABSTRACT: spec defines the specification of desired Pod selection for target discovery by Prometheus.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s attachMetadata                 => '+IO::K8s::PrometheusOperator::V1::AttachMetadata';
k8s bodySizeLimit                  => Str, { pattern => qr/(^0|([0-9]*[.])?[0-9]+((K|M|G|T|E|P)i?)?B)$/ };
k8s convertClassicHistogramsToNHCB => Bool;
k8s fallbackScrapeProtocol         => Str, { enum => [qw(PrometheusProto OpenMetricsText0.0.1 OpenMetricsText1.0.0 PrometheusText0.0.4 PrometheusText1.0.0)] };
k8s jobLabel                       => Str;
k8s keepDroppedTargets             => Int, { minimum => 0 };
k8s labelLimit                     => Int, { minimum => 0 };
k8s labelNameLengthLimit           => Int, { minimum => 0 };
k8s labelValueLengthLimit          => Int, { minimum => 0 };
k8s namespaceSelector              => '+IO::K8s::PrometheusOperator::V1::NamespaceSelector';
k8s nativeHistogramBucketLimit     => Int, { minimum => 0 };
k8s nativeHistogramMinBucketFactor => Quantity;
k8s podMetricsEndpoints            => ['+IO::K8s::PrometheusOperator::V1::PodMetricsEndpoint'];
k8s podTargetLabels                => [Str];
k8s sampleLimit                    => Int, { minimum => 0 };
k8s scrapeClass                    => Str;
k8s scrapeClassicHistograms        => Bool;
k8s scrapeNativeHistograms         => Bool;
k8s scrapeProtocols                => [Str], { enum => [qw(PrometheusProto OpenMetricsText0.0.1 OpenMetricsText1.0.0 PrometheusText0.0.4 PrometheusText1.0.0)] };
k8s selector                       => 'Meta::V1::LabelSelector', { required => 'schema' };
k8s selectorMechanism              => Str, { enum => [qw(RelabelConfig RoleSelector)] };
k8s targetLimit                    => Int, { minimum => 0 };























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PodMonitorSpec - spec defines the specification of desired Pod selection for target discovery by Prometheus.

=head1 VERSION

version 1.108

=head2 attachMetadata

attachMetadata defines additional metadata which is added to the
discovered targets.

It requires Prometheus >= v2.35.0.

=head2 bodySizeLimit

bodySizeLimit when defined specifies a job level limit on the size
of uncompressed response body that will be accepted by Prometheus.

It requires Prometheus >= v2.28.0.

=head2 convertClassicHistogramsToNHCB

convertClassicHistogramsToNHCB defines whether to convert all scraped classic histograms into a native histogram with custom buckets.
It requires Prometheus >= v3.0.0.

=head2 fallbackScrapeProtocol

fallbackScrapeProtocol defines the protocol to use if a scrape returns blank, unparseable, or otherwise invalid Content-Type.

It requires Prometheus >= v3.0.0.

=head2 jobLabel

jobLabel defines the label to use to retrieve the job name from.
`jobLabel` selects the label from the associated Kubernetes `Pod`
object which will be used as the `job` label for all metrics.

For example if `jobLabel` is set to `foo` and the Kubernetes `Pod`
object is labeled with `foo: bar`, then Prometheus adds the `job="bar"`
label to all ingested metrics.

If the value of this field is empty, the `job` label of the metrics
defaults to the namespace and name of the PodMonitor object (e.g. `<namespace>/<name>`).

=head2 keepDroppedTargets

keepDroppedTargets defines the per-scrape limit on the number of targets dropped by relabeling
that will be kept in memory. 0 means no limit.

It requires Prometheus >= v2.47.0.

=head2 labelLimit

labelLimit defines the per-scrape limit on number of labels that will be accepted for a sample.

It requires Prometheus >= v2.27.0.

=head2 labelNameLengthLimit

labelNameLengthLimit defines the per-scrape limit on length of labels name that will be accepted for a sample.

It requires Prometheus >= v2.27.0.

=head2 labelValueLengthLimit

labelValueLengthLimit defines the per-scrape limit on length of labels value that will be accepted for a sample.

It requires Prometheus >= v2.27.0.

=head2 namespaceSelector

namespaceSelector defines in which namespace(s) Prometheus should discover the pods.
By default, the pods are discovered in the same namespace as the `PodMonitor` object but it is possible to select pods across different/all namespaces.

=head2 nativeHistogramBucketLimit

nativeHistogramBucketLimit defines ff there are more than this many buckets in a native histogram,
buckets will be merged to stay within the limit.
It requires Prometheus >= v2.45.0.

=head2 nativeHistogramMinBucketFactor

nativeHistogramMinBucketFactor defines if the growth factor of one bucket to the next is smaller than this,
buckets will be merged to increase the factor sufficiently.
It requires Prometheus >= v2.50.0.

=head2 podMetricsEndpoints

podMetricsEndpoints defines how to scrape metrics from the selected pods.

=head2 podTargetLabels

podTargetLabels defines the labels which are transferred from the
associated Kubernetes `Pod` object onto the ingested metrics.

=head2 sampleLimit

sampleLimit defines a per-scrape limit on the number of scraped samples
that will be accepted.

=head2 scrapeClass

scrapeClass defines the scrape class to apply.

=head2 scrapeClassicHistograms

scrapeClassicHistograms defines whether to scrape a classic histogram that is also exposed as a native histogram.
It requires Prometheus >= v2.45.0.

Notice: `scrapeClassicHistograms` corresponds to the `always_scrape_classic_histograms` field in the Prometheus configuration.

=head2 scrapeNativeHistograms

scrapeNativeHistograms defines whether to enable scraping of native histograms.
It requires Prometheus >= v3.8.0.

=head2 scrapeProtocols

scrapeProtocols defines the protocols to negotiate during a scrape. It tells clients the
protocols supported by Prometheus in order of preference (from most to least preferred).

If unset, Prometheus uses its default value.

It requires Prometheus >= v2.49.0.

=head2 selector

selector defines the label selector to select the Kubernetes `Pod` objects to scrape metrics from.

=head2 selectorMechanism

selectorMechanism defines the mechanism used to select the endpoints to scrape.
By default, the selection process relies on relabel configurations to filter the discovered targets.
Alternatively, you can opt in for role selectors, which may offer better efficiency in large clusters.
Which strategy is best for your use case needs to be carefully evaluated.

It requires Prometheus >= v2.17.0.

=head2 targetLimit

targetLimit defines a limit on the number of scraped targets that will
be accepted.

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
