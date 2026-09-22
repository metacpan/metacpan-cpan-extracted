package IO::K8s::K3s::V1::HelmChart;
# ABSTRACT: HelmChart represents configuration and state for the deployment of a Helm chart.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'helm.cattle.io/v1',
    resource_plural => 'helmcharts';
with 'IO::K8s::Role::Namespaced', 'IO::K8s::Role::HelmManaged';

k8s spec   => '+IO::K8s::K3s::V1::HelmChartSpec', { required => 'schema' };
k8s status => '+IO::K8s::K3s::V1::HelmChartStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::K3s::V1::HelmChart - HelmChart represents configuration and state for the deployment of a Helm chart.

=head1 VERSION

version 1.108

=head2 spec

HelmChartSpec represents the user-configurable details for installation and upgrade of a Helm chart release.

=head2 status

HelmChartStatus represents the resulting state from processing HelmChart events

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
