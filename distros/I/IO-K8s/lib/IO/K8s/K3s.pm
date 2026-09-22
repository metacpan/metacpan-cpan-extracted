package IO::K8s::K3s;
# ABSTRACT: K3s CRD resource map provider for IO::K8s
our $VERSION = '1.108';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub upstream_version { 'v1.36.4+k3s1' }

# Source status for maint/crd-drift-check.pl. Data only -- no fetching here.
# k3s-io/k3s does not publish machine-readable openAPIV3Schema CRDs for these
# Kinds: helm.cattle.io (HelmChart/HelmChartConfig) and k3s.cattle.io
# (Addon/ETCDSnapshotFile) are registered at runtime as wrangler-generated
# CRDs, largely with x-kubernetes-preserve-unknown-fields rather than a
# field-level schema. The helm-controller repo carries schema CRDs for
# HelmChart/HelmChartConfig only, but on a branch that cannot be pinned to
# this k3s release tag, and Addon/ETCDSnapshotFile have no published schema
# at all. Rather than fake a source, this provider is reported as unresolved
# so the other five providers are not blocked (k82).
sub crd_sources {
    return {
        status => 'unresolved',
        note   => 'k3s-io/k3s ships these CRDs as wrangler-generated, largely schemaless '
                . '(x-kubernetes-preserve-unknown-fields) manifests with no machine-readable '
                . 'openAPIV3Schema to diff; helm-controller carries schema for HelmChart/'
                . 'HelmChartConfig only, on an unpinnable branch.',
        base   => undef,
        files  => [],
    };
}

sub resource_map {
    return {
        HelmChart        => 'K3s::V1::HelmChart',
        HelmChartConfig  => 'K3s::V1::HelmChartConfig',
        Addon            => 'K3s::V1::Addon',
        ETCDSnapshotFile => 'K3s::V1::ETCDSnapshotFile',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s - K3s CRD resource map provider for IO::K8s

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);

    my $hc = $k8s->new_object('HelmChart',
        metadata => { name => 'traefik', namespace => 'kube-system' },
        spec => { chart => 'traefik', version => '25.0.0' },
    );

    print $hc->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<K3s|https://k3s.io/> Custom Resource Definitions.
Registers 4 CRD classes covering C<helm.cattle.io/v1> and C<k3s.cattle.io/v1>.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::K3s') >> at runtime.

=head2 Included CRDs (helm.cattle.io/v1)

HelmChart, HelmChartConfig — namespace-scoped.

=head2 Included CRDs (k3s.cattle.io/v1)

Addon — namespace-scoped.

ETCDSnapshotFile — cluster-scoped.

=head1 SEE ALSO

L<IO::K8s>

L<K3s documentation|https://docs.k3s.io/>

L<K3s Helm integration|https://docs.k3s.io/helm>

L<K3s packaged components|https://docs.k3s.io/installation/packaged-components>

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
