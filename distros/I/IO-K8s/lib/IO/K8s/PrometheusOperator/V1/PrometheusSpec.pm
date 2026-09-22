package IO::K8s::PrometheusOperator::V1::PrometheusSpec;
# ABSTRACT: spec defines the specification of the desired behavior of the Prometheus cluster.
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s additionalAlertManagerConfigs        => 'Core::V1::ConfigMapKeySelector';
k8s additionalAlertRelabelConfigs        => 'Core::V1::ConfigMapKeySelector';
k8s additionalArgs                       => ['+IO::K8s::PrometheusOperator::V1::Argument'];
k8s additionalScrapeConfigs              => 'Core::V1::ConfigMapKeySelector';
k8s affinity                             => 'Core::V1::Affinity';
k8s alerting                             => '+IO::K8s::PrometheusOperator::V1::AlertingSpec';
k8s allowOverlappingBlocks               => Bool;
k8s apiserverConfig                      => '+IO::K8s::PrometheusOperator::V1::APIServerConfig';
k8s arbitraryFSAccessThroughSMs          => '+IO::K8s::PrometheusOperator::V1::ArbitraryFSAccessThroughSMsConfig';
k8s automountServiceAccountToken         => Bool;
k8s baseImage                            => Str;
k8s bodySizeLimit                        => Str, { pattern => qr/(^0|([0-9]*[.])?[0-9]+((K|M|G|T|E|P)i?)?B)$/ };
k8s configMaps                           => [Str];
k8s containers                           => ['Core::V1::Container'];
k8s convertClassicHistogramsToNHCB       => Bool;
k8s disableCompaction                    => Bool;
k8s dnsConfig                            => 'Core::V1::PodDNSConfig';
k8s dnsPolicy                            => Str, { enum => [qw(ClusterFirstWithHostNet ClusterFirst Default None)] };
k8s enableAdminAPI                       => Bool;
k8s enableFeatures                       => [Str];
k8s enableOTLPReceiver                   => Bool;
k8s enableRemoteWriteReceiver            => Bool;
k8s enableServiceLinks                   => Bool;
k8s enforcedBodySizeLimit                => Str, { pattern => qr/(^0|([0-9]*[.])?[0-9]+((K|M|G|T|E|P)i?)?B)$/ };
k8s enforcedKeepDroppedTargets           => Int, { minimum => 0 };
k8s enforcedLabelLimit                   => Int, { minimum => 0 };
k8s enforcedLabelNameLengthLimit         => Int, { minimum => 0 };
k8s enforcedLabelValueLengthLimit        => Int, { minimum => 0 };
k8s enforcedNamespaceLabel               => Str;
k8s enforcedSampleLimit                  => Int, { minimum => 0 };
k8s enforcedTargetLimit                  => Int, { minimum => 0 };
k8s evaluationInterval                   => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/, default => '30s' };
k8s excludedFromEnforcement              => ['+IO::K8s::PrometheusOperator::V1::ObjectReference'];
k8s exemplars                            => '+IO::K8s::PrometheusOperator::V1::Exemplars';
k8s externalLabels                       => { Str => 1 };
k8s externalUrl                          => Str;
k8s hostAliases                          => ['Core::V1::HostAlias'];
k8s hostNetwork                          => Bool;
k8s hostUsers                            => Bool;
k8s ignoreNamespaceSelectors             => Bool;
k8s image                                => Str;
k8s imagePullPolicy                      => Str, { enum => ['','Always','Never','IfNotPresent'] };
k8s imagePullSecrets                     => ['Core::V1::LocalObjectReference'];
k8s initContainers                       => ['Core::V1::Container'];
k8s keepDroppedTargets                   => Int, { minimum => 0 };
k8s labelLimit                           => Int, { minimum => 0 };
k8s labelNameLengthLimit                 => Int, { minimum => 0 };
k8s labelValueLengthLimit                => Int, { minimum => 0 };
k8s listenLocal                          => Bool;
k8s logFormat                            => Str, { enum => ['','logfmt','json'] };
k8s logLevel                             => Str, { enum => ['','debug','info','warn','error'] };
k8s maximumStartupDurationSeconds        => Int, { minimum => 60 };
k8s minReadySeconds                      => Int, { minimum => 0 };
k8s nameEscapingScheme                   => Str, { enum => [qw(AllowUTF8 Underscores Dots Values)] };
k8s nameValidationScheme                 => Str, { enum => [qw(UTF8 Legacy)] };
k8s nodeSelector                         => { Str => 1 };
k8s otlp                                 => '+IO::K8s::PrometheusOperator::V1::OTLPConfig';
k8s overrideHonorLabels                  => Bool;
k8s overrideHonorTimestamps              => Bool;
k8s paused                               => Bool;
k8s persistentVolumeClaimRetentionPolicy => 'Apps::V1::StatefulSetPersistentVolumeClaimRetentionPolicy';
k8s podManagementPolicy                  => Str, { enum => [qw(OrderedReady Parallel)] };
k8s podMetadata                          => '+IO::K8s::PrometheusOperator::V1::EmbeddedObjectMetadata';
k8s podMonitorNamespaceSelector          => 'Meta::V1::LabelSelector';
k8s podMonitorSelector                   => 'Meta::V1::LabelSelector';
k8s podTargetLabels                      => [Str];
k8s portName                             => Str, { default => 'web' };
k8s priorityClassName                    => Str;
k8s probeNamespaceSelector               => 'Meta::V1::LabelSelector';
k8s probeSelector                        => 'Meta::V1::LabelSelector';
k8s prometheusExternalLabelName          => Str;
k8s prometheusRulesExcludedFromEnforce   => ['+IO::K8s::PrometheusOperator::V1::PrometheusRuleExcludeConfig'];
k8s query                                => '+IO::K8s::PrometheusOperator::V1::QuerySpec';
k8s queryLogFile                         => Str;
k8s reloadStrategy                       => Str, { enum => [qw(HTTP ProcessSignal)] };
k8s remoteRead                           => ['+IO::K8s::PrometheusOperator::V1::RemoteReadSpec'];
k8s remoteWrite                          => ['+IO::K8s::PrometheusOperator::V1::RemoteWriteSpec'];
k8s remoteWriteReceiverMessageVersions   => [Str], { enum => [qw(V1.0 V2.0)] };
k8s replicaExternalLabelName             => Str;
k8s replicas                             => Int;
k8s resources                            => 'Core::V1::ResourceRequirements';
k8s retention                            => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s retentionSize                        => Str, { pattern => qr/(^0|([0-9]*[.])?[0-9]+((K|M|G|T|E|P)i?)?B)$/ };
k8s routePrefix                          => Str;
k8s ruleNamespaceSelector                => 'Meta::V1::LabelSelector';
k8s ruleQueryOffset                      => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s ruleSelector                         => 'Meta::V1::LabelSelector';
k8s rules                                => '+IO::K8s::PrometheusOperator::V1::Rules';
k8s runtime                              => '+IO::K8s::PrometheusOperator::V1::RuntimeConfig';
k8s sampleLimit                          => Int, { minimum => 0 };
k8s schedulerName                        => Str;
k8s scrapeClasses                        => ['+IO::K8s::PrometheusOperator::V1::ScrapeClass'];
k8s scrapeClassicHistograms              => Bool;
k8s scrapeConfigNamespaceSelector        => 'Meta::V1::LabelSelector';
k8s scrapeConfigSelector                 => 'Meta::V1::LabelSelector';
k8s scrapeFailureLogFile                 => Str;
k8s scrapeInterval                       => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/, default => '30s' };
k8s scrapeNativeHistograms               => Bool;
k8s scrapeProtocols                      => [Str], { enum => [qw(PrometheusProto OpenMetricsText0.0.1 OpenMetricsText1.0.0 PrometheusText0.0.4 PrometheusText1.0.0)] };
k8s scrapeTimeout                        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s secrets                              => [Str];
k8s securityContext                      => 'Core::V1::PodSecurityContext';
k8s serviceAccountName                   => Str;
k8s serviceDiscoveryRole                 => Str, { enum => [qw(Endpoints EndpointSlice)] };
k8s serviceMonitorNamespaceSelector      => 'Meta::V1::LabelSelector';
k8s serviceMonitorSelector               => 'Meta::V1::LabelSelector';
k8s serviceName                          => Str;
k8s sha                                  => Str;
k8s shardRetentionPolicy                 => '+IO::K8s::PrometheusOperator::V1::ShardRetentionPolicy';
k8s shardingStrategy                     => '+IO::K8s::PrometheusOperator::V1::ShardingStrategy';
k8s shards                               => Int, { default => 1 };
k8s storage                              => '+IO::K8s::PrometheusOperator::V1::StorageSpec';
k8s tag                                  => Str;
k8s targetLimit                          => Int, { minimum => 0 };
k8s terminationGracePeriodSeconds        => Int, { minimum => 0 };
k8s thanos                               => '+IO::K8s::PrometheusOperator::V1::ThanosSpec';
k8s tolerations                          => ['Core::V1::Toleration'];
k8s topologySpreadConstraints            => ['+IO::K8s::PrometheusOperator::V1::TopologySpreadConstraint'];
k8s tracingConfig                        => '+IO::K8s::PrometheusOperator::V1::TracingConfig';
k8s tsdb                                 => '+IO::K8s::PrometheusOperator::V1::TSDBSpec';
k8s updateStrategy                       => '+IO::K8s::PrometheusOperator::V1::StatefulSetUpdateStrategy';
k8s version                              => Str;
k8s volumeMounts                         => ['+IO::K8s::PrometheusOperator::V1::VolumeMount'];
k8s volumes                              => ['Core::V1::Volume'];
k8s walCompression                       => Bool;
k8s web                                  => '+IO::K8s::PrometheusOperator::V1::PrometheusWebSpec';
































































































































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PrometheusSpec - spec defines the specification of the desired behavior of the Prometheus cluster.

=head1 VERSION

version 1.108

=head2 additionalAlertManagerConfigs

additionalAlertManagerConfigs defines a key of a Secret containing
additional Prometheus Alertmanager configurations. The Alertmanager
configurations are appended to the configuration generated by the
Prometheus Operator. They must be formatted according to the official
Prometheus documentation:

https://prometheus.io/docs/prometheus/latest/configuration/configuration/#alertmanager_config

The user is responsible for making sure that the configurations are valid

Note that using this feature may expose the possibility to break
upgrades of Prometheus. It is advised to review Prometheus release notes
to ensure that no incompatible AlertManager configs are going to break
Prometheus after the upgrade.

=head2 additionalAlertRelabelConfigs

additionalAlertRelabelConfigs defines a key of a Secret containing
additional Prometheus alert relabel configurations. The alert relabel
configurations are appended to the configuration generated by the
Prometheus Operator. They must be formatted according to the official
Prometheus documentation:

https://prometheus.io/docs/prometheus/latest/configuration/configuration/#alert_relabel_configs

The user is responsible for making sure that the configurations are valid

Note that using this feature may expose the possibility to break
upgrades of Prometheus. It is advised to review Prometheus release notes
to ensure that no incompatible alert relabel configs are going to break
Prometheus after the upgrade.

=head2 additionalArgs

additionalArgs allows setting additional arguments for the 'prometheus' container.

It is intended for e.g. activating hidden flags which are not supported by
the dedicated configuration options yet. The arguments are passed as-is to the
Prometheus container which may cause issues if they are invalid or not supported
by the given Prometheus version.

In case of an argument conflict (e.g. an argument which is already set by the
operator itself) or when providing an invalid argument, the reconciliation will
fail and an error will be logged.

=head2 additionalScrapeConfigs

additionalScrapeConfigs allows specifying a key of a Secret containing
additional Prometheus scrape configurations. Scrape configurations
specified are appended to the configurations generated by the Prometheus
Operator. Job configurations specified must have the form as specified
in the official Prometheus documentation:
https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config.
As scrape configs are appended, the user is responsible to make sure it
is valid. Note that using this feature may expose the possibility to
break upgrades of Prometheus. It is advised to review Prometheus release
notes to ensure that no incompatible scrape configs are going to break
Prometheus after the upgrade.

=head2 affinity

affinity defines the Pods' affinity scheduling rules if specified.

=head2 alerting

alerting defines the settings related to Alertmanager.

=head2 allowOverlappingBlocks

allowOverlappingBlocks enables vertical compaction and vertical query
merge in Prometheus.

Deprecated: this flag has no effect for Prometheus >= 2.39.0 where overlapping blocks are enabled by default.

=head2 apiserverConfig

apiserverConfig allows specifying a host and auth methods to access the
Kuberntees API server.
If null, Prometheus is assumed to run inside of the cluster: it will
discover the API servers automatically and use the Pod's CA certificate
and bearer token file at /var/run/secrets/kubernetes.io/serviceaccount/.

=head2 arbitraryFSAccessThroughSMs

arbitraryFSAccessThroughSMs when true, ServiceMonitor, PodMonitor and Probe object are forbidden to
reference arbitrary files on the file system of the 'prometheus'
container.
When a ServiceMonitor's endpoint specifies a `bearerTokenFile` value
(e.g.  '/var/run/secrets/kubernetes.io/serviceaccount/token'), a
malicious target can get access to the Prometheus service account's
token in the Prometheus' scrape request. Setting
`spec.arbitraryFSAccessThroughSM` to 'true' would prevent the attack.
Users should instead provide the credentials using the
`spec.bearerTokenSecret` field.

=head2 automountServiceAccountToken

automountServiceAccountToken defines whether a service account token should be automatically mounted in the pod.
If the field isn't set, the operator mounts the service account token by default.

**Warning:** be aware that by default, Prometheus requires the service account token for Kubernetes service discovery.
It is possible to use strategic merge patch to project the service account token into the 'prometheus' container.

=head2 baseImage

baseImage is deprecated: use 'spec.image' instead.

=head2 bodySizeLimit

bodySizeLimit defines per-scrape on response body size.
Only valid in Prometheus versions 2.45.0 and newer.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedBodySizeLimit.

=head2 configMaps

configMaps defines a list of ConfigMaps in the same namespace as the Prometheus
object, which shall be mounted into the Prometheus Pods.
Each ConfigMap is added to the StatefulSet definition as a volume named `configmap-<configmap-name>`.
The ConfigMaps are mounted into /etc/prometheus/configmaps/<configmap-name> in the 'prometheus' container.

=head2 containers

containers allows injecting additional containers or modifying operator
generated containers. This can be used to allow adding an authentication
proxy to the Pods or to change the behavior of an operator generated
container. Containers described here modify an operator generated
container if they share the same name and modifications are done via a
strategic merge patch.

The names of containers managed by the operator are:
* `prometheus`
* `config-reloader`
* `thanos-sidecar`

Overriding containers which are managed by the operator require careful
testing, especially when upgrading to a new version of the operator.

=head2 convertClassicHistogramsToNHCB

convertClassicHistogramsToNHCB defines whether to convert all scraped classic histograms into a native
histogram with custom buckets.

It requires Prometheus >= v3.4.0.

=head2 disableCompaction

disableCompaction when true, the Prometheus compaction is disabled.

When `spec.thanos.objectStorageConfig` or `spec.thanos.objectStorageConfigFile` are defined, the operator's
default handling depends on the Prometheus and Thanos sidecar versions:
  - With Prometheus < v3.9.0 or a Thanos sidecar < v0.41.0, block compaction is disabled to avoid race
    conditions during block uploads (as the Thanos documentation recommends).
  - With Prometheus >= v3.9.0 and a Thanos sidecar >= v0.41.0, local compaction is kept enabled and coordinated
    with the sidecar through the shipper meta file (`--storage.tsdb.delay-compact-file.path`), so blocks are only
    compacted after they have been uploaded.
Setting this field to true always disables local compaction regardless of the versions.

=head2 dnsConfig

dnsConfig defines the DNS configuration for the pods.

=head2 dnsPolicy

dnsPolicy defines the DNS policy for the pods.

=head2 enableAdminAPI

enableAdminAPI defines access to the Prometheus web admin API.

WARNING: Enabling the admin APIs enables mutating endpoints, to delete data,
shutdown Prometheus, and more. Enabling this should be done with care and the
user is advised to add additional authentication authorization via a proxy to
ensure only clients authorized to perform these actions can do so.

For more information:
https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-admin-apis

=head2 enableFeatures

enableFeatures enables access to Prometheus feature flags. By default, no features are enabled.

Enabling features which are disabled by default is entirely outside the
scope of what the maintainers will support and by doing so, you accept
that this behaviour may break at any time without notice.

For more information see https://prometheus.io/docs/prometheus/latest/feature_flags/

=head2 enableOTLPReceiver

enableOTLPReceiver defines the Prometheus to be used as a receiver for the OTLP Metrics protocol.

Note that the OTLP receiver endpoint is automatically enabled if `.spec.otlpConfig` is defined.

It requires Prometheus >= v2.47.0.

=head2 enableRemoteWriteReceiver

enableRemoteWriteReceiver defines the Prometheus to be used as a receiver for the Prometheus remote
write protocol.

WARNING: This is not considered an efficient way of ingesting samples.
Use it with caution for specific low-volume use cases.
It is not suitable for replacing the ingestion via scraping and turning
Prometheus into a push-based metrics collection system.
For more information see https://prometheus.io/docs/prometheus/latest/querying/api/#remote-write-receiver

It requires Prometheus >= v2.33.0.

=head2 enableServiceLinks

enableServiceLinks defines whether information about services should be injected into pod's environment variables

=head2 enforcedBodySizeLimit

enforcedBodySizeLimit when defined specifies a global limit on the size
of uncompressed response body that will be accepted by Prometheus.
Targets responding with a body larger than this many bytes will cause
the scrape to fail.

It requires Prometheus >= v2.28.0.

When both `enforcedBodySizeLimit` and `bodySizeLimit` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined bodySizeLimit value will inherit the global bodySizeLimit value (Prometheus >= 2.45.0) or the enforcedBodySizeLimit value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedBodySizeLimit` is greater than the `bodySizeLimit`, the `bodySizeLimit` will be set to `enforcedBodySizeLimit`.
* Scrape objects with a bodySizeLimit value less than or equal to enforcedBodySizeLimit keep their specific value.
* Scrape objects with a bodySizeLimit value greater than enforcedBodySizeLimit are set to enforcedBodySizeLimit.

=head2 enforcedKeepDroppedTargets

enforcedKeepDroppedTargets when defined specifies a global limit on the number of targets
dropped by relabeling that will be kept in memory. The value overrides
any `spec.keepDroppedTargets` set by
ServiceMonitor, PodMonitor, Probe objects unless `spec.keepDroppedTargets` is
greater than zero and less than `spec.enforcedKeepDroppedTargets`.

It requires Prometheus >= v2.47.0.

When both `enforcedKeepDroppedTargets` and `keepDroppedTargets` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined keepDroppedTargets value will inherit the global keepDroppedTargets value (Prometheus >= 2.45.0) or the enforcedKeepDroppedTargets value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedKeepDroppedTargets` is greater than the `keepDroppedTargets`, the `keepDroppedTargets` will be set to `enforcedKeepDroppedTargets`.
* Scrape objects with a keepDroppedTargets value less than or equal to enforcedKeepDroppedTargets keep their specific value.
* Scrape objects with a keepDroppedTargets value greater than enforcedKeepDroppedTargets are set to enforcedKeepDroppedTargets.

=head2 enforcedLabelLimit

enforcedLabelLimit when defined specifies a global limit on the number
of labels per sample. The value overrides any `spec.labelLimit` set by
ServiceMonitor, PodMonitor, Probe objects unless `spec.labelLimit` is
greater than zero and less than `spec.enforcedLabelLimit`.

It requires Prometheus >= v2.27.0.

When both `enforcedLabelLimit` and `labelLimit` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined labelLimit value will inherit the global labelLimit value (Prometheus >= 2.45.0) or the enforcedLabelLimit value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedLabelLimit` is greater than the `labelLimit`, the `labelLimit` will be set to `enforcedLabelLimit`.
* Scrape objects with a labelLimit value less than or equal to enforcedLabelLimit keep their specific value.
* Scrape objects with a labelLimit value greater than enforcedLabelLimit are set to enforcedLabelLimit.

=head2 enforcedLabelNameLengthLimit

enforcedLabelNameLengthLimit when defined specifies a global limit on the length
of labels name per sample. The value overrides any `spec.labelNameLengthLimit` set by
ServiceMonitor, PodMonitor, Probe objects unless `spec.labelNameLengthLimit` is
greater than zero and less than `spec.enforcedLabelNameLengthLimit`.

It requires Prometheus >= v2.27.0.

When both `enforcedLabelNameLengthLimit` and `labelNameLengthLimit` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined labelNameLengthLimit value will inherit the global labelNameLengthLimit value (Prometheus >= 2.45.0) or the enforcedLabelNameLengthLimit value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedLabelNameLengthLimit` is greater than the `labelNameLengthLimit`, the `labelNameLengthLimit` will be set to `enforcedLabelNameLengthLimit`.
* Scrape objects with a labelNameLengthLimit value less than or equal to enforcedLabelNameLengthLimit keep their specific value.
* Scrape objects with a labelNameLengthLimit value greater than enforcedLabelNameLengthLimit are set to enforcedLabelNameLengthLimit.

=head2 enforcedLabelValueLengthLimit

enforcedLabelValueLengthLimit when not null defines a global limit on the length
of labels value per sample. The value overrides any `spec.labelValueLengthLimit` set by
ServiceMonitor, PodMonitor, Probe objects unless `spec.labelValueLengthLimit` is
greater than zero and less than `spec.enforcedLabelValueLengthLimit`.

It requires Prometheus >= v2.27.0.

When both `enforcedLabelValueLengthLimit` and `labelValueLengthLimit` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined labelValueLengthLimit value will inherit the global labelValueLengthLimit value (Prometheus >= 2.45.0) or the enforcedLabelValueLengthLimit value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedLabelValueLengthLimit` is greater than the `labelValueLengthLimit`, the `labelValueLengthLimit` will be set to `enforcedLabelValueLengthLimit`.
* Scrape objects with a labelValueLengthLimit value less than or equal to enforcedLabelValueLengthLimit keep their specific value.
* Scrape objects with a labelValueLengthLimit value greater than enforcedLabelValueLengthLimit are set to enforcedLabelValueLengthLimit.

=head2 enforcedNamespaceLabel

enforcedNamespaceLabel when not empty, a label will be added to:

1. All metrics scraped from `ServiceMonitor`, `PodMonitor`, `Probe` and `ScrapeConfig` objects.
2. All metrics generated from recording rules defined in `PrometheusRule` objects.
3. All alerts generated from alerting rules defined in `PrometheusRule` objects.
4. All vector selectors of PromQL expressions defined in `PrometheusRule` objects.

The label will not added for objects referenced in `spec.excludedFromEnforcement`.

The label's name is this field's value.
The label's value is the namespace of the `ServiceMonitor`,
`PodMonitor`, `Probe`, `PrometheusRule` or `ScrapeConfig` object.

=head2 enforcedSampleLimit

enforcedSampleLimit when defined specifies a global limit on the number
of scraped samples that will be accepted. This overrides any
`spec.sampleLimit` set by ServiceMonitor, PodMonitor, Probe objects
unless `spec.sampleLimit` is greater than zero and less than
`spec.enforcedSampleLimit`.

It is meant to be used by admins to keep the overall number of
samples/series under a desired limit.

When both `enforcedSampleLimit` and `sampleLimit` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined sampleLimit value will inherit the global sampleLimit value (Prometheus >= 2.45.0) or the enforcedSampleLimit value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedSampleLimit` is greater than the `sampleLimit`, the `sampleLimit` will be set to `enforcedSampleLimit`.
* Scrape objects with a sampleLimit value less than or equal to enforcedSampleLimit keep their specific value.
* Scrape objects with a sampleLimit value greater than enforcedSampleLimit are set to enforcedSampleLimit.

=head2 enforcedTargetLimit

enforcedTargetLimit when defined specifies a global limit on the number
of scraped targets. The value overrides any `spec.targetLimit` set by
ServiceMonitor, PodMonitor, Probe objects unless `spec.targetLimit` is
greater than zero and less than `spec.enforcedTargetLimit`.

It is meant to be used by admins to to keep the overall number of
targets under a desired limit.

When both `enforcedTargetLimit` and `targetLimit` are defined and greater than zero, the following rules apply:
* Scrape objects without a defined targetLimit value will inherit the global targetLimit value (Prometheus >= 2.45.0) or the enforcedTargetLimit value (Prometheus < v2.45.0).
  If Prometheus version is >= 2.45.0 and the `enforcedTargetLimit` is greater than the `targetLimit`, the `targetLimit` will be set to `enforcedTargetLimit`.
* Scrape objects with a targetLimit value less than or equal to enforcedTargetLimit keep their specific value.
* Scrape objects with a targetLimit value greater than enforcedTargetLimit are set to enforcedTargetLimit.

=head2 evaluationInterval

evaluationInterval defines the interval between rule evaluations.
Default: "30s"

=head2 excludedFromEnforcement

excludedFromEnforcement defines the list of references to PodMonitor, ServiceMonitor, Probe and PrometheusRule objects
to be excluded from enforcing a namespace label of origin.

It is only applicable if `spec.enforcedNamespaceLabel` set to true.

=head2 exemplars

exemplars related settings that are runtime reloadable.
It requires to enable the `exemplar-storage` feature flag to be effective.

=head2 externalLabels

externalLabels defines the labels to add to any time series or alerts when communicating with
external systems (federation, remote storage, Alertmanager).
Labels defined by `spec.replicaExternalLabelName` and
`spec.prometheusExternalLabelName` take precedence over this list.

=head2 externalUrl

externalUrl defines the external URL under which the Prometheus service is externally
available. This is necessary to generate correct URLs (for instance if
Prometheus is accessible behind an Ingress resource).

=head2 hostAliases

hostAliases defines the optional list of hosts and IPs that will be injected into the Pod's
hosts file if specified.

=head2 hostNetwork

hostNetwork defines the host's network namespace if true.

Make sure to understand the security implications if you want to enable
it (https://kubernetes.io/docs/concepts/configuration/overview/ ).

When hostNetwork is enabled, this will set the DNS policy to
`ClusterFirstWithHostNet` automatically (unless `.spec.DNSPolicy` is set
to a different value).

=head2 hostUsers

hostUsers supports the user space in Kubernetes.

More info: https://kubernetes.io/docs/tasks/configure-pod-container/user-namespaces/

The feature requires at least Kubernetes 1.28 with the `UserNamespacesSupport` feature gate enabled.
Starting Kubernetes 1.33, the feature is enabled by default.

=head2 ignoreNamespaceSelectors

ignoreNamespaceSelectors when true, `spec.namespaceSelector` from all PodMonitor, ServiceMonitor
and Probe objects will be ignored. They will only discover targets
within the namespace of the PodMonitor, ServiceMonitor and Probe
object.

=head2 image

image defines the container image name for Prometheus. If specified, it takes precedence
over the `spec.baseImage`, `spec.tag` and `spec.sha` fields.

Specifying `spec.version` is still necessary to ensure the Prometheus
Operator knows which version of Prometheus is being configured.

If neither `spec.image` nor `spec.baseImage` are defined, the operator
will use the latest upstream version of Prometheus available at the time
when the operator was released.

=head2 imagePullPolicy

imagePullPolicy defines the image pull policy for the 'prometheus', 'init-config-reloader' and 'config-reloader' containers.
See https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy for more details.

=head2 imagePullSecrets

imagePullSecrets defines an optional list of references to Secrets in the same namespace
to use for pulling images from registries.
See http://kubernetes.io/docs/user-guide/images#specifying-imagepullsecrets-on-a-pod

=head2 initContainers

initContainers allows injecting initContainers to the Pod definition. Those
can be used to e.g. fetch secrets for injection into the Prometheus
configuration from external sources. Any errors during the execution of
an initContainer will lead to a restart of the Pod. More info:
https://kubernetes.io/docs/concepts/workloads/pods/init-containers/
InitContainers described here modify an operator generated init
containers if they share the same name and modifications are done via a
strategic merge patch.

The names of init container name managed by the operator are:
* `init-config-reloader`.

Overriding init containers which are managed by the operator require
careful testing, especially when upgrading to a new version of the
operator.

=head2 keepDroppedTargets

keepDroppedTargets defines the per-scrape limit on the number of targets dropped by relabeling
that will be kept in memory. 0 means no limit.

It requires Prometheus >= v2.47.0.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedKeepDroppedTargets.

=head2 labelLimit

labelLimit defines per-scrape limit on number of labels that will be accepted for a sample.
Only valid in Prometheus versions 2.45.0 and newer.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedLabelLimit.

=head2 labelNameLengthLimit

labelNameLengthLimit defines the per-scrape limit on length of labels name that will be accepted for a sample.
Only valid in Prometheus versions 2.45.0 and newer.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedLabelNameLengthLimit.

=head2 labelValueLengthLimit

labelValueLengthLimit defines the per-scrape limit on length of labels value that will be accepted for a sample.
Only valid in Prometheus versions 2.45.0 and newer.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedLabelValueLengthLimit.

=head2 listenLocal

listenLocal when true, the Prometheus server listens on the loopback address
instead of the Pod IP's address.

=head2 logFormat

logFormat for Log level for Prometheus and the config-reloader sidecar.

=head2 logLevel

logLevel for Prometheus and the config-reloader sidecar.

=head2 maximumStartupDurationSeconds

maximumStartupDurationSeconds defines the maximum time that the `prometheus` container's startup probe will wait before being considered failed. The startup probe will return success after the WAL replay is complete.
If set, the value should be greater than 60 (seconds). Otherwise it will be equal to 900 seconds (15 minutes).

=head2 minReadySeconds

minReadySeconds defines the minimum number of seconds for which a newly created Pod should be ready
without any of its container crashing for it to be considered available.

If unset, pods will be considered available as soon as they are ready.

=head2 nameEscapingScheme

nameEscapingScheme defines the character escaping scheme that will be requested when scraping
for metric and label names that do not conform to the legacy Prometheus
character set.

It requires Prometheus >= v3.4.0.

=head2 nameValidationScheme

nameValidationScheme defines the validation scheme for metric and label names.

It requires Prometheus >= v2.55.0.

=head2 nodeSelector

nodeSelector defines on which Nodes the Pods are scheduled.

=head2 otlp

otlp defines the settings related to the OTLP receiver feature.
It requires Prometheus >= v2.55.0.

=head2 overrideHonorLabels

overrideHonorLabels when true, Prometheus resolves label conflicts by renaming the labels in the scraped data
 to “exported_” for all targets created from ServiceMonitor, PodMonitor and
ScrapeConfig objects. Otherwise the HonorLabels field of the service or pod monitor applies.
In practice,`OverrideHonorLabels:true` enforces `honorLabels:false`
for all ServiceMonitor, PodMonitor and ScrapeConfig objects.

=head2 overrideHonorTimestamps

overrideHonorTimestamps when true, Prometheus ignores the timestamps for all the targets created
from service and pod monitors.
Otherwise the HonorTimestamps field of the service or pod monitor applies.

=head2 paused

paused defines when a Prometheus deployment is paused, no actions except for deletion
will be performed on the underlying objects.

=head2 persistentVolumeClaimRetentionPolicy

persistentVolumeClaimRetentionPolicy defines the field controls if and how PVCs are deleted during the lifecycle of a StatefulSet.
The default behavior is all PVCs are retained.
This is an alpha field from kubernetes 1.23 until 1.26 and a beta field from 1.26.
It requires enabling the StatefulSetAutoDeletePVC feature gate.

=head2 podManagementPolicy

podManagementPolicy defines the policy for creating/deleting pods when
scaling up and down.

Unlike the default StatefulSet behavior, the default policy is
`Parallel` to avoid manual intervention in case a pod gets stuck during
a rollout.

Note that updating this value implies the recreation of the StatefulSet
which incurs a service outage.

=head2 podMetadata

podMetadata defines labels and annotations which are propagated to the Prometheus pods.

The following items are reserved and cannot be overridden:
* "prometheus" label, set to the name of the Prometheus object.
* "app.kubernetes.io/instance" label, set to the name of the Prometheus object.
* "app.kubernetes.io/managed-by" label, set to "prometheus-operator".
* "app.kubernetes.io/name" label, set to "prometheus".
* "app.kubernetes.io/version" label, set to the Prometheus version.
* "operator.prometheus.io/name" label, set to the name of the Prometheus object.
* "operator.prometheus.io/shard" label, set to the shard number of the Prometheus object.
* "kubectl.kubernetes.io/default-container" annotation, set to "prometheus".

=head2 podMonitorNamespaceSelector

podMonitorNamespaceSelector defines the namespaces to match for PodMonitors discovery. An empty label selector
matches all namespaces. A null label selector (default value) matches the current
namespace only.

=head2 podMonitorSelector

podMonitorSelector defines the podMonitors to be selected for target discovery. An empty label selector
matches all objects. A null label selector matches no objects.

If `spec.serviceMonitorSelector`, `spec.podMonitorSelector`, `spec.probeSelector`
and `spec.scrapeConfigSelector` are null, the Prometheus configuration is unmanaged.
The Prometheus operator will ensure that the Prometheus configuration's
Secret exists, but it is the responsibility of the user to provide the raw
gzipped Prometheus configuration under the `prometheus.yaml.gz` key.
This behavior is *deprecated* and will be removed in the next major version
of the custom resource definition. It is recommended to use
`spec.additionalScrapeConfigs` instead.

=head2 podTargetLabels

podTargetLabels are appended to the `spec.podTargetLabels` field of all
PodMonitor and ServiceMonitor objects.

=head2 portName

portName used for the pods and governing service.
Default: "web"

=head2 priorityClassName

priorityClassName assigned to the Pods.

=head2 probeNamespaceSelector

probeNamespaceSelector defines the namespaces to match for Probe discovery. An empty label
selector matches all namespaces. A null label selector matches the
current namespace only.

=head2 probeSelector

probeSelector defines the probes to be selected for target discovery. An empty label selector
matches all objects. A null label selector matches no objects.

If `spec.serviceMonitorSelector`, `spec.podMonitorSelector`, `spec.probeSelector`
and `spec.scrapeConfigSelector` are null, the Prometheus configuration is unmanaged.
The Prometheus operator will ensure that the Prometheus configuration's
Secret exists, but it is the responsibility of the user to provide the raw
gzipped Prometheus configuration under the `prometheus.yaml.gz` key.
This behavior is *deprecated* and will be removed in the next major version
of the custom resource definition. It is recommended to use
`spec.additionalScrapeConfigs` instead.

=head2 prometheusExternalLabelName

prometheusExternalLabelName defines the name of Prometheus external label used to denote the Prometheus instance
name. The external label will _not_ be added when the field is set to
the empty string (`""`).

Default: "prometheus"

=head2 prometheusRulesExcludedFromEnforce

prometheusRulesExcludedFromEnforce defines the list of PrometheusRule objects to which the namespace label
enforcement doesn't apply.
This is only relevant when `spec.enforcedNamespaceLabel` is set to true.
Deprecated: use `spec.excludedFromEnforcement` instead.

=head2 query

query defines the configuration of the Prometheus query service.

=head2 queryLogFile

queryLogFile specifies where the file to which PromQL queries are logged.

If the filename has an empty path, e.g. 'query.log', The Prometheus Pods
will mount the file into an emptyDir volume at `/var/log/prometheus`.
If a full path is provided, e.g. '/var/log/prometheus/query.log', you
must mount a volume in the specified directory and it must be writable.
This is because the prometheus container runs with a read-only root
filesystem for security reasons.
Alternatively, the location can be set to a standard I/O stream, e.g.
`/dev/stdout`, to log query information to the default Prometheus log
stream.

=head2 reloadStrategy

reloadStrategy defines the strategy used to reload the Prometheus configuration.
If not specified, the configuration is reloaded using the /-/reload HTTP endpoint.

=head2 remoteRead

remoteRead defines the list of remote read configurations.

=head2 remoteWrite

remoteWrite defines the list of remote write configurations.

=head2 remoteWriteReceiverMessageVersions

remoteWriteReceiverMessageVersions list of the protobuf message versions to accept when receiving the
remote writes.

It requires Prometheus >= v2.54.0.

=head2 replicaExternalLabelName

replicaExternalLabelName defines the name of Prometheus external label used to denote the replica name.
The external label will _not_ be added when the field is set to the
empty string (`""`).

Default: "prometheus_replica"

=head2 replicas

replicas defines the number of replicas of each shard to deploy for a Prometheus deployment.
`spec.replicas` multiplied by `spec.shards` is the total number of Pods
created.

Default: 1

=head2 resources

resources defines the resources requests and limits of the 'prometheus' container.

=head2 retention

retention defines how long to retain the Prometheus data.

Default: "24h" if `spec.retention` and `spec.retentionSize` are empty.

=head2 retentionSize

retentionSize defines the maximum number of bytes used by the Prometheus data.

=head2 routePrefix

routePrefix defines the route prefix Prometheus registers HTTP handlers for.

This is useful when using `spec.externalURL`, and a proxy is rewriting
HTTP routes of a request, and the actual ExternalURL is still true, but
the server serves requests under a different route prefix. For example
for use with `kubectl proxy`.

=head2 ruleNamespaceSelector

ruleNamespaceSelector defines the namespaces to match for PrometheusRule discovery. An empty label selector
matches all namespaces. A null label selector matches the current
namespace only.

=head2 ruleQueryOffset

ruleQueryOffset defines the offset the rule evaluation timestamp of this particular group by the specified duration into the past.
It requires Prometheus >= v2.53.0.

=head2 ruleSelector

ruleSelector defines the prometheusRule objects to be selected for rule evaluation. An empty
label selector matches all objects. A null label selector matches no
objects.

=head2 rules

rules defines the configuration of the Prometheus rules' engine.

=head2 runtime

runtime defines the values for the Prometheus process behavior

=head2 sampleLimit

sampleLimit defines per-scrape limit on number of scraped samples that will be accepted.
Only valid in Prometheus versions 2.45.0 and newer.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedSampleLimit.

=head2 schedulerName

schedulerName defines the scheduler to use for Pod scheduling. If not specified, the default scheduler is used.

=head2 scrapeClasses

scrapeClasses defines the list of scrape classes to expose to scraping objects such as
PodMonitors, ServiceMonitors, Probes and ScrapeConfigs.

This is an *experimental feature*, it may change in any upcoming release
in a breaking way.

=head2 scrapeClassicHistograms

scrapeClassicHistograms defines whether to scrape a classic histogram that is also exposed as a native histogram.

Notice: `scrapeClassicHistograms` corresponds to the `always_scrape_classic_histograms` field in the Prometheus configuration.

It requires Prometheus >= v3.5.0.

=head2 scrapeConfigNamespaceSelector

scrapeConfigNamespaceSelector defines the namespaces to match for ScrapeConfig discovery. An empty label selector
matches all namespaces. A null label selector matches the current
namespace only.

Note that the ScrapeConfig custom resource definition is currently at Alpha level
and will be graduated to Beta in a future release.

=head2 scrapeConfigSelector

scrapeConfigSelector defines the scrapeConfigs to be selected for target discovery. An empty label
selector matches all objects. A null label selector matches no objects.

If `spec.serviceMonitorSelector`, `spec.podMonitorSelector`, `spec.probeSelector`
and `spec.scrapeConfigSelector` are null, the Prometheus configuration is unmanaged.
The Prometheus operator will ensure that the Prometheus configuration's
Secret exists, but it is the responsibility of the user to provide the raw
gzipped Prometheus configuration under the `prometheus.yaml.gz` key.
This behavior is *deprecated* and will be removed in the next major version
of the custom resource definition. It is recommended to use
`spec.additionalScrapeConfigs` instead.

Note that the ScrapeConfig custom resource definition is currently at Alpha level
and will be graduated to Beta in a future release.

=head2 scrapeFailureLogFile

scrapeFailureLogFile defines the file to which scrape failures are logged.
Reloading the configuration will reopen the file.

If the filename has an empty path, e.g. 'file.log', The Prometheus Pods
will mount the file into an emptyDir volume at `/var/log/prometheus`.
If a full path is provided, e.g. '/var/log/prometheus/file.log', you
must mount a volume in the specified directory and it must be writable.
It requires Prometheus >= v2.55.0.

=head2 scrapeInterval

scrapeInterval defines interval between consecutive scrapes.

Default: "30s"

=head2 scrapeNativeHistograms

scrapeNativeHistograms defines whether to enable scraping of native histograms.
It requires Prometheus >= v3.8.0.

=head2 scrapeProtocols

scrapeProtocols defines the protocols to negotiate during a scrape. It tells clients the
protocols supported by Prometheus in order of preference (from most to least preferred).

If unset, Prometheus uses its default value.

It requires Prometheus >= v2.49.0.

`PrometheusText1.0.0` requires Prometheus >= v3.0.0.

=head2 scrapeTimeout

scrapeTimeout defines the number of seconds to wait until a scrape request times out.
The value cannot be greater than the scrape interval otherwise the operator will reject the resource.

=head2 secrets

secrets defines a list of Secrets in the same namespace as the Prometheus
object, which shall be mounted into the Prometheus Pods.
Each Secret is added to the StatefulSet definition as a volume named `secret-<secret-name>`.
The Secrets are mounted into /etc/prometheus/secrets/<secret-name> in the 'prometheus' container.

=head2 securityContext

securityContext holds pod-level security attributes and common container settings.
This defaults to the default PodSecurityContext.

=head2 serviceAccountName

serviceAccountName is the name of the ServiceAccount to use to run the
Prometheus Pods.

=head2 serviceDiscoveryRole

serviceDiscoveryRole defines the service discovery role used to discover targets from
`ServiceMonitor` objects and Alertmanager endpoints.

If set, the value should be either "Endpoints" or "EndpointSlice".
If unset, the operator assumes the "Endpoints" role.

=head2 serviceMonitorNamespaceSelector

serviceMonitorNamespaceSelector defines the namespaces to match for ServicedMonitors discovery. An empty label selector
matches all namespaces. A null label selector (default value) matches the current
namespace only.

=head2 serviceMonitorSelector

serviceMonitorSelector defines the serviceMonitors to be selected for target discovery. An empty label
selector matches all objects. A null label selector matches no objects.

If `spec.serviceMonitorSelector`, `spec.podMonitorSelector`, `spec.probeSelector`
and `spec.scrapeConfigSelector` are null, the Prometheus configuration is unmanaged.
The Prometheus operator will ensure that the Prometheus configuration's
Secret exists, but it is the responsibility of the user to provide the raw
gzipped Prometheus configuration under the `prometheus.yaml.gz` key.
This behavior is *deprecated* and will be removed in the next major version
of the custom resource definition. It is recommended to use
`spec.additionalScrapeConfigs` instead.

=head2 serviceName

serviceName defines the name of the service name used by the underlying StatefulSet(s) as the governing service.
If defined, the Service  must be created before the Prometheus/PrometheusAgent resource in the same namespace and it must define a selector that matches the pod labels.
If empty, the operator will create and manage a headless service named `prometheus-operated` for Prometheus resources,
or `prometheus-agent-operated` for PrometheusAgent resources.
When deploying multiple Prometheus/PrometheusAgent resources in the same namespace, it is recommended to specify a different value for each.
See https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#stable-network-id for more details.

=head2 sha

sha is deprecated: use 'spec.image' instead. The image's digest can be specified as part of the image name.

=head2 shardRetentionPolicy

shardRetentionPolicy defines the retention policy for the Prometheus shards.

(Beta) Using this mode requires the `PrometheusShardRetentionPolicy` feature gate (enabled by default).

=head2 shardingStrategy

shardingStrategy defines the sharding strategy for distributing scraped targets across Prometheus shards.

When not defined, the operator defaults to the 'Address' mode which distributes
targets based on a hash of the target address.

=head2 shards

shards defines the number of shards to distribute the scraped targets onto.

`spec.replicas` multiplied by `spec.shards` is the total number of Pods
being created.

When not defined, the operator assumes only one shard.

Note that scaling down shards will not reshard data onto the remaining
instances, it must be manually moved. Increasing shards will not reshard
data either but it will continue to be available from the same
instances. To query globally, use either
* Thanos sidecar + querier for query federation and Thanos Ruler for rules.
* Remote-write to send metrics to a central location.

By default, the sharding of targets is performed on:
* The `__address__` target's metadata label for PodMonitor,
ServiceMonitor and ScrapeConfig resources.
* The `__param_target__` label for Probe resources.

Users can define their own sharding implementation by setting the
`__tmp_hash` label during the target discovery with relabeling
configuration (either in the monitoring resources or via scrape class).

You can also disable sharding on a specific target by setting the
`__tmp_disable_sharding` label with relabeling configuration. When
the label value isn't empty, all Prometheus shards will scrape the target.

Default: 1

=head2 storage

storage defines the storage used by Prometheus.

=head2 tag

tag is deprecated: use 'spec.image' instead. The image's tag can be specified as part of the image name.

=head2 targetLimit

targetLimit defines a limit on the number of scraped targets that will be accepted.
Only valid in Prometheus versions 2.45.0 and newer.

Note that the global limit only applies to scrape objects that don't specify an explicit limit value.
If you want to enforce a maximum limit for all scrape objects, refer to enforcedTargetLimit.

=head2 terminationGracePeriodSeconds

terminationGracePeriodSeconds defines the optional duration in seconds the pod needs to terminate gracefully.
Value must be non-negative integer. The value zero indicates stop immediately via
the kill signal (no opportunity to shut down) which may lead to data corruption.

Defaults to 600 seconds.

=head2 thanos

thanos defines the configuration of the optional Thanos sidecar.

=head2 tolerations

tolerations defines the Pods' tolerations if specified.

=head2 topologySpreadConstraints

topologySpreadConstraints defines the pod's topology spread constraints if specified.

=head2 tracingConfig

tracingConfig defines tracing in Prometheus.

This is an *experimental feature*, it may change in any upcoming release
in a breaking way.

=head2 tsdb

tsdb defines the runtime reloadable configuration of the timeseries database(TSDB).
It requires Prometheus >= v2.39.0 or PrometheusAgent >= v2.54.0.

=head2 updateStrategy

updateStrategy indicates the strategy that will be employed to update
Pods in the StatefulSet when a revision is made to statefulset's Pod
Template.

The default strategy is RollingUpdate.

=head2 version

version of Prometheus being deployed. The operator uses this information
to generate the Prometheus StatefulSet + configuration files.

If not specified, the operator assumes the latest upstream version of
Prometheus available at the time when the version of the operator was
released.

=head2 volumeMounts

volumeMounts allows the configuration of additional VolumeMounts.

VolumeMounts will be appended to other VolumeMounts in the 'prometheus'
container, that are generated as a result of StorageSpec objects.

=head2 volumes

volumes allows the configuration of additional volumes on the output
StatefulSet definition. Volumes specified will be appended to other
volumes that are generated as a result of StorageSpec objects.

=head2 walCompression

walCompression defines the compression of the write-ahead log (WAL) using Snappy.

WAL compression is enabled by default for Prometheus >= 2.20.0

Requires Prometheus v2.11.0 and above.

=head2 web

web defines the configuration of the Prometheus web server.

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
