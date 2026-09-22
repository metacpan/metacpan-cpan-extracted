package IO::K8s::PrometheusOperator::V1::ThanosSpec;
# ABSTRACT: thanos defines the configuration of the optional Thanos sidecar.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s additionalArgs          => ['+IO::K8s::PrometheusOperator::V1::Argument'];
k8s baseImage               => Str;
k8s blockSize               => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/, default => '2h' };
k8s getConfigInterval       => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s getConfigTimeout        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s grpcListenLocal         => Bool;
k8s grpcServerTlsConfig     => '+IO::K8s::PrometheusOperator::V1::GRPCServerTLSConfig';
k8s httpListenLocal         => Bool;
k8s image                   => Str;
k8s listenLocal             => Bool;
k8s logFormat               => Str, { enum => ['','logfmt','json'] };
k8s logLevel                => Str, { enum => ['','debug','info','warn','error'] };
k8s minTime                 => Str;
k8s objectStorageConfig     => 'Core::V1::ConfigMapKeySelector';
k8s objectStorageConfigFile => Str;
k8s readyTimeout            => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s resources               => 'Core::V1::ResourceRequirements';
k8s sha                     => Str;
k8s tag                     => Str;
k8s tracingConfig           => 'Core::V1::ConfigMapKeySelector';
k8s tracingConfigFile       => Str;
k8s version                 => Str;
k8s volumeMounts            => ['+IO::K8s::PrometheusOperator::V1::VolumeMount'];
























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ThanosSpec - thanos defines the configuration of the optional Thanos sidecar.

=head1 VERSION

version 1.108

=head2 additionalArgs

additionalArgs allows setting additional arguments for the Thanos container.
The arguments are passed as-is to the Thanos container which may cause issues
if they are invalid or not supported the given Thanos version.
In case of an argument conflict (e.g. an argument which is already set by the
operator itself) or when providing an invalid argument, the reconciliation will
fail and an error will be logged.

=head2 baseImage

baseImage is deprecated: use 'image' instead.

=head2 blockSize

blockSize controls the size of TSDB blocks produced by Prometheus.
The default value is 2h to match the upstream Prometheus defaults.

WARNING: Changing the block duration can impact the performance and
efficiency of the entire Prometheus/Thanos stack due to how it interacts
with memory and Thanos compactors. It is recommended to keep this value
set to a multiple of 120 times your longest scrape or rule interval. For
example, 30s * 120 = 1h.

=head2 getConfigInterval

getConfigInterval defines how often to retrieve the Prometheus configuration.

=head2 getConfigTimeout

getConfigTimeout defines the maximum time to wait when retrieving the Prometheus configuration.

=head2 grpcListenLocal

grpcListenLocal defines when true, the Thanos sidecar listens on the loopback interface instead
of the Pod IP's address for the gRPC endpoints.

It has no effect if `listenLocal` is true.

=head2 grpcServerTlsConfig

grpcServerTlsConfig defines the TLS parameters for the gRPC server providing the StoreAPI.

Note: Currently only the `minVersion`, `caFile`, `certFile`, `keyFile`, `cipherSuites` and `curves` fields are supported.

=head2 httpListenLocal

httpListenLocal when true, the Thanos sidecar listens on the loopback interface instead
of the Pod IP's address for the HTTP endpoints.

It has no effect if `listenLocal` is true.

=head2 image

image defines the container image name for Thanos. If specified, it takes precedence over
the `spec.thanos.baseImage`, `spec.thanos.tag` and `spec.thanos.sha`
fields.

Specifying `spec.thanos.version` is still necessary to ensure the
Prometheus Operator knows which version of Thanos is being configured.

If neither `spec.thanos.image` nor `spec.thanos.baseImage` are defined,
the operator will use the latest upstream version of Thanos available at
the time when the operator was released.

=head2 listenLocal

listenLocal is deprecated: use `grpcListenLocal` and `httpListenLocal` instead.

=head2 logFormat

logFormat for the Thanos sidecar.

=head2 logLevel

logLevel for the Thanos sidecar.

=head2 minTime

minTime defines the start of time range limit served by the Thanos sidecar's StoreAPI.
The field's value should be a constant time in RFC3339 format or a time
duration relative to current time, such as -1d or 2h45m. Valid duration
units are ms, s, m, h, d, w, y.

=head2 objectStorageConfig

objectStorageConfig defines the Thanos sidecar's configuration to upload TSDB blocks to object storage.

More info: https://thanos.io/tip/thanos/storage.md/

objectStorageConfigFile takes precedence over this field.

=head2 objectStorageConfigFile

objectStorageConfigFile defines the Thanos sidecar's configuration file to upload TSDB blocks to object storage.

More info: https://thanos.io/tip/thanos/storage.md/

This field takes precedence over objectStorageConfig.

=head2 readyTimeout

readyTimeout defines the maximum time that the Thanos sidecar will wait for
Prometheus to start.

=head2 resources

resources defines the resources requests and limits of the Thanos sidecar.

=head2 sha

sha is deprecated: use 'image' instead.  The image digest can be specified as part of the image name.

=head2 tag

tag is deprecated: use 'image' instead. The image's tag can be specified as as part of the image name.

=head2 tracingConfig

tracingConfig defines the tracing configuration for the Thanos sidecar.

`tracingConfigFile` takes precedence over this field.

More info: https://thanos.io/tip/thanos/tracing.md/

This is an *experimental feature*, it may change in any upcoming release
in a breaking way.

=head2 tracingConfigFile

tracingConfigFile defines the tracing configuration file for the Thanos sidecar.

This field takes precedence over `tracingConfig`.

More info: https://thanos.io/tip/thanos/tracing.md/

This is an *experimental feature*, it may change in any upcoming release
in a breaking way.

=head2 version

version of Thanos being deployed. The operator uses this information
to generate the Prometheus StatefulSet + configuration files.

If not specified, the operator assumes the latest upstream release of
Thanos available at the time when the version of the operator was
released.

=head2 volumeMounts

volumeMounts allows configuration of additional VolumeMounts for Thanos.
VolumeMounts specified will be appended to other VolumeMounts in the
'thanos-sidecar' container.

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
