package IO::K8s::K3s::V1::HelmChartSpec;
# ABSTRACT: HelmChartSpec represents the user-configurable details for installation and upgrade of a Helm chart release.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authPassCredentials   => Bool;
k8s authSecret            => 'Core::V1::LocalObjectReference';
k8s backOffLimit          => Int;
k8s bootstrap             => Bool;
k8s chart                 => Str;
k8s chartContent          => Str;
k8s createNamespace       => Bool;
k8s dockerRegistrySecret  => 'Core::V1::LocalObjectReference';
k8s driver                => Str, { enum => [qw(secret configmap)], default => 'secret' };
k8s failurePolicy         => Str, { enum => [qw(abort reinstall retry)], default => 'reinstall' };
k8s forceConflicts        => Bool;
k8s helmVersion           => Str;
k8s insecureSkipTLSVerify => Bool;
k8s jobImage              => Str;
k8s plainHTTP             => Bool;
k8s podSecurityContext    => 'Core::V1::PodSecurityContext';
k8s repo                  => Str;
k8s repoCA                => Str;
k8s repoCAConfigMap       => 'Core::V1::LocalObjectReference';
k8s securityContext       => 'Core::V1::SecurityContext';
k8s serverSide            => Str, { enum => [qw(true false auto)] };
k8s set                   => { IntOrStr => 1 };
k8s takeOwnership         => Bool;
k8s targetNamespace       => Str;
k8s timeout               => Str, { pattern => "^([0-9]+(ns|us|\x{b5}s|ms|s|m|h)?)+\$" };
k8s values                => 'Apiextensions::V1::JSON';
k8s valuesContent         => Str;
k8s valuesSecrets         => ['+IO::K8s::K3s::V1::SecretSpec'];
k8s version               => Str;






























1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::HelmChartSpec - HelmChartSpec represents the user-configurable details for installation and upgrade of a Helm chart release.

=head1 VERSION

version 1.108

=head2 authPassCredentials

Pass Basic auth credentials to all domains.
Helm CLI positional argument/flag: `--pass-credentials`

=head2 authSecret

Reference to Secret of type kubernetes.io/basic-auth holding Basic auth credentials for the Chart repo.

=head2 backOffLimit

Specify the number of retries before considering the helm job failed.

=head2 bootstrap

Set to True if this chart is needed to bootstrap the cluster (Cloud Controller Manager, CNI, etc).

=head2 chart

Helm Chart name in repository, or complete HTTPS URL to chart archive (.tgz)
Helm CLI positional argument/flag: `CHART`

=head2 chartContent

Base64-encoded chart archive .tgz; overides `.spec.chart` and `.spec.version`.
Helm CLI positional argument/flag: `CHART`

=head2 createNamespace

Create target namespace if not present.
Helm CLI positional argument/flag: `--create-namespace`

=head2 dockerRegistrySecret

Reference to Secret of type kubernetes.io/dockerconfigjson holding Docker auth credentials for the OCI-based registry acting as the Chart repo.

=head2 driver

Helm storage driver to use for this chart's release metadata.
`secret` stores releases in Kubernetes Secrets (default).
`configmap` stores releases in ConfigMaps.
This field is effectively immutable after the first install; changing the storage backend is not a supported migration path.
Helm CLI environment variable: `HELM_DRIVER`

=head2 failurePolicy

Configures handling of failed chart installation or upgrades.
- `abort` will take no action and leave the chart in a failed state so that the administrator can manually resolve the error.
- `reinstall` will perform a clean uninstall and reinstall of the chart; this is the default behavior.
- `retry` will attempt to retry the install or upgrade whenever chart configuration changes.

=head2 forceConflicts

Set to true if helm should configure server-side apply to force changes when conflicts arise in ownership of managed fields.
Helm CLI positional argument/flag: `--force-conflicts`

=head2 helmVersion

DEPRECATED. Helm version to use. Only v3 is currently supported.

=head2 insecureSkipTLSVerify

Skip TLS certificate checks for the chart download.
Helm CLI positional argument/flag: `--insecure-skip-tls-verify`

=head2 jobImage

Specify the image to use for tht helm job pod when installing or upgrading the helm chart.

=head2 plainHTTP

Use insecure HTTP connections for the chart download.
Helm CLI positional argument/flag: `--plain-http`

=head2 podSecurityContext

Custom PodSecurityContext for the helm job pod.

=head2 repo

Helm Chart repository URL.
Helm CLI positional argument/flag: `--repo`

=head2 repoCA

Verify certificates of HTTPS-enabled servers using this CA bundle. Should be a string containing one or more PEM-encoded CA Certificates.
Helm CLI positional argument/flag: `--ca-file`

=head2 repoCAConfigMap

Reference to a ConfigMap containing CA Certificates to be be trusted by Helm. Can be used along with or instead of `.spec.repoCA`
Helm CLI positional argument/flag: `--ca-file`

=head2 securityContext

custom SecurityContext for the helm job pod.

=head2 serverSide

Set to true if helm should enable server-side apply when updating objects. Defaults to `true` for install, and `auto` for upgrade.
- `true` enables server-side apply.
- `false` disables server-side apply.
- `auto` enables server-side apply if the chart was installed with server-side apply enabled.
Helm CLI positional argument/flag: `--server-side`

=head2 set

Override simple Chart values. These take precedence over options set via values or valuesContent.
Helm CLI positional argument/flag: `--set`, `--set-string`

=head2 takeOwnership

Set to True if helm should take ownership of existing resources when installing/upgrading the chart.
Helm CLI positional argument/flag: `--take-ownership`

=head2 targetNamespace

Helm Chart target namespace.
Helm CLI positional argument/flag: `--namespace`

=head2 timeout

Timeout for Helm operations.
Helm CLI positional argument/flag: `--timeout`

=head2 values

Override complex Chart values via structured YAML. Takes precedence over options set via valuesContent.
Helm CLI positional argument/flag: `--values`

=head2 valuesContent

Override complex Chart values via inline YAML content.
Helm CLI positional argument/flag: `--values`

=head2 valuesSecrets

Override complex Chart values via references to external Secrets.
Helm CLI positional argument/flag: `--values`

=head2 version

Helm Chart version. Only used when installing from repository; ignored when .spec.chart or .spec.chartContent is used to install a specific chart archive.
Helm CLI positional argument/flag: `--version`

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
