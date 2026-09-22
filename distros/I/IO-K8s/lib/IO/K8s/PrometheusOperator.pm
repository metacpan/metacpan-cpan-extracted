package IO::K8s::PrometheusOperator;
# ABSTRACT: Prometheus Operator CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v0.93.1' }  # prometheus-operator/prometheus-operator

# Upstream CRD manifests for the pinned upstream_version, consumed by
# maint/crd-drift-check.pl. Data only -- no fetching happens here. `base`
# + each `files` entry is the raw manifest URL; the checker caches each
# under spec/crd/PrometheusOperator/ (path separators flattened to '_').
sub crd_sources {
    my $v = __PACKAGE__->upstream_version;
    return {
        status => 'ok',
        base   => "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/$v/example/prometheus-operator-crd",
        files  => [
            'monitoring.coreos.com_alertmanagers.yaml',
            'monitoring.coreos.com_podmonitors.yaml',
            'monitoring.coreos.com_probes.yaml',
            'monitoring.coreos.com_prometheuses.yaml',
            'monitoring.coreos.com_prometheusrules.yaml',
            'monitoring.coreos.com_scrapeconfigs.yaml',
            'monitoring.coreos.com_servicemonitors.yaml',
        ],
    };
}

sub resource_map {
    return {
        # monitoring.coreos.com/v1
        Alertmanager   => 'PrometheusOperator::V1::Alertmanager',
        Prometheus     => 'PrometheusOperator::V1::Prometheus',
        ServiceMonitor => 'PrometheusOperator::V1::ServiceMonitor',
        PodMonitor     => 'PrometheusOperator::V1::PodMonitor',
        Probe          => 'PrometheusOperator::V1::Probe',
        PrometheusRule => 'PrometheusOperator::V1::PrometheusRule',
        # monitoring.coreos.com/v1alpha1
        ScrapeConfig   => 'PrometheusOperator::V1alpha1::ScrapeConfig',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator - Prometheus Operator CRD resource map provider for IO::K8s

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::PrometheusOperator']);

    my $prom = $k8s->new_object('Prometheus',
        metadata => { name => 'main', namespace => 'monitoring' },
        spec => {
            serviceAccountName => 'prometheus',
            serviceMonitorSelector => {},
        },
    );

    print $prom->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<Prometheus Operator|https://prometheus-operator.dev/>
Custom Resource Definitions. Registers 7 resource_map entries covering
C<monitoring.coreos.com/v1> (C<Alertmanager>, C<Prometheus>,
C<ServiceMonitor>, C<PodMonitor>, C<Probe>, C<PrometheusRule>) and
C<monitoring.coreos.com/v1alpha1> (C<ScrapeConfig>), matching upstream
prometheus-operator v0.93.1. All seven Kinds are namespaced.

Every Kind is modeled to full depth: each Kind's C<spec> (and, where
upstream declares one, C<status>) is a typed object graph of further
C<IO::K8s::PrometheusOperator::V1::*> / C<::V1alpha1::*> classes, one per
upstream Go structure, named after the upstream Go types in
C<github.com/prometheus-operator/prometheus-operator/pkg/apis/monitoring/{v1,v1alpha1}>
-- C<Prometheus>'s C<spec> is a
L<IO::K8s::PrometheusOperator::V1::PrometheusSpec>, whose C<remoteWrite> is
an array of L<IO::K8s::PrometheusOperator::V1::RemoteWriteSpec>, and so on
down -- rather than an opaque hashref. Embedded core Kubernetes types
(C<Core::V1::Container>, C<Core::V1::Affinity>, C<Meta::V1::LabelSelector>,
C<Core::V1::SecretKeySelector>, ...) are referenced, not re-modeled.

Upstream defines a number of structures once and embeds the SAME Go type
across multiple Kinds and multiple fields within one Kind --
C<SafeTLSConfig>, C<TLSConfig>, C<BasicAuth>, C<OAuth2>, C<Authorization>,
C<SafeAuthorization>, C<RelabelConfig>, C<SecretOrConfigMap>, C<Argument>
and C<Sigv4> among them. Each is one shared
L<IO::K8s::PrometheusOperator::V1::*> class referenced from every embedding
site (verified byte-identical generated schema at every site before
sharing), the same pattern L<IO::K8s::Cilium>'s C<Rule> uses across
C<CiliumNetworkPolicy>/C<CiliumClusterwideNetworkPolicy> -- not a copy per
Kind or per field. C<monitoring.coreos.com/v1alpha1>'s own
C<ScrapeConfig> embeds several of the very same C<v1> package types
(C<SafeTLSConfig>, C<BasicAuth>, C<OAuth2>, C<SafeAuthorization>,
C<RelabelConfig>) again across its many service-discovery blocks
(C<KubernetesSDConfig>, C<ConsulSDConfig>, C<DockerSDConfig>, ...); those
get their own C<IO::K8s::PrometheusOperator::V1alpha1::*> copies rather
than reaching across into C<::V1::*>, matching Cilium's own rule that a Go
type is never shared I<across> version directories.

Three upstream types -- C<Argument> (C<additionalArgs>, on C<Alertmanager>,
C<Prometheus> and C<Prometheus>'s embedded C<Thanos> sidecar spec),
C<ObjectReference> (C<Prometheus>'s C<excludedFromEnforcement>) and
C<HostPort> (Alertmanager's C<alertmanagerConfiguration.global.smtp.smartHost>)
-- coincidentally share a JSON key set with an unrelated shipped class
(C<Core::V1::HTTPHeader>, C<GatewayAPI>'s C<ParentReference> by way of
L<IO::K8s::Api::Networking::V1::ParentReference>, and
C<Core::V1::TCPSocketAction> respectively) and were hand-written instead of
left on L<IO::K8s::AutoGen>'s structural reuse match, which does not compare
required-ness or the actual upstream type identity -- see L<IO::K8s::PrometheusOperator::V1::Argument>,
L<IO::K8s::PrometheusOperator::V1::ObjectReference> and
L<IO::K8s::PrometheusOperator::V1::HostPort>.

Not loaded by default -- opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::PrometheusOperator') >> at
runtime.

=head2 Included CRDs (monitoring.coreos.com/v1)

Alertmanager, Prometheus, ServiceMonitor, PodMonitor, Probe, PrometheusRule

=head2 Included CRDs (monitoring.coreos.com/v1alpha1)

ScrapeConfig

=head1 SEE ALSO

L<IO::K8s>

L<Prometheus Operator documentation|https://prometheus-operator.dev/>

L<Prometheus Operator API reference|https://prometheus-operator.dev/docs/api-reference/api/>

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
