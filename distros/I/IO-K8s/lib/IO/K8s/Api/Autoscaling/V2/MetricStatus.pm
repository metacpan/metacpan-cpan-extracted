package IO::K8s::Api::Autoscaling::V2::MetricStatus;
# ABSTRACT: MetricStatus describes the last-read state of a single metric.
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s containerResource => 'Autoscaling::V2::ContainerResourceMetricStatus';


k8s external => 'Autoscaling::V2::ExternalMetricStatus';


k8s object => 'Autoscaling::V2::ObjectMetricStatus';


k8s pods => 'Autoscaling::V2::PodsMetricStatus';


k8s resource => 'Autoscaling::V2::ResourceMetricStatus';


k8s type => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::MetricStatus - MetricStatus describes the last-read state of a single metric.

=head1 VERSION

version 1.008

=head2 containerResource

container resource refers to a resource metric (such as those specified in requests and limits) known to Kubernetes describing a single container in each pod in the current scale target (e.g. CPU or memory). Such metrics are built in to Kubernetes, and have special scaling options on top of those available to normal per-pod metrics using the "pods" source.

=head2 external

external refers to a global metric that is not associated with any Kubernetes object. It allows autoscaling based on information coming from components running outside of cluster (for example length of queue in cloud messaging service, or QPS from loadbalancer running outside of cluster).

=head2 object

object refers to a metric describing a single kubernetes object (for example, hits-per-second on an Ingress object).

=head2 pods

pods refers to a metric describing each pod in the current scale target (for example, transactions-processed-per-second).  The values will be averaged together before being compared to the target value.

=head2 resource

resource refers to a resource metric (such as those specified in requests and limits) known to Kubernetes describing each pod in the current scale target (e.g. CPU or memory). Such metrics are built in to Kubernetes, and have special scaling options on top of those available to normal per-pod metrics using the "pods" source.

=head2 type

type is the type of metric source.  It will be one of "ContainerResource", "External", "Object", "Pods" or "Resource", each corresponds to a matching field in the object. Note: "ContainerResource" type is available on when the feature-gate HPAContainerMetrics is enabled

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
