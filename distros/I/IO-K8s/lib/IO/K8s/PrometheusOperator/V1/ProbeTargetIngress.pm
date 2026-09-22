package IO::K8s::PrometheusOperator::V1::ProbeTargetIngress;
# ABSTRACT: ingress defines the Ingress objects to probe and the relabeling configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s namespaceSelector => '+IO::K8s::PrometheusOperator::V1::NamespaceSelector';
k8s relabelingConfigs => ['+IO::K8s::PrometheusOperator::V1::RelabelConfig'];
k8s selector          => 'Meta::V1::LabelSelector';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ProbeTargetIngress - ingress defines the Ingress objects to probe and the relabeling configuration.

=head1 VERSION

version 1.108

=head2 namespaceSelector

namespaceSelector defines from which namespaces to select Ingress objects.

=head2 relabelingConfigs

relabelingConfigs to apply to the label set of the target before it gets
scraped.
The original ingress address is available via the
`__tmp_prometheus_ingress_address` label. It can be used to customize the
probed URL.
The original scrape job's name is available via the `__tmp_prometheus_job_name` label.
More info: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config

=head2 selector

selector to select the Ingress objects.

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
