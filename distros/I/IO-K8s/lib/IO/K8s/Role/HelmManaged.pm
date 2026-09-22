package IO::K8s::Role::HelmManaged;
# ABSTRACT: Role for K3s Helm chart management
our $VERSION = '1.108';
use Moo::Role;

# The fluent setters below build the spec through IO::K8s::Role::SpecBuilder
# rather than by hand, so that role is a hard dependency of this one (k103).
# IO::K8s::Role::APIObject composes SpecBuilder for every top-level Kind, so
# these are satisfied for anything built with IO::K8s::APIObject; a class
# that composes this role without them now fails at composition time,
# naming the missing method, instead of at the first setter call.
requires qw( spec_hash spec_set );


sub from_repo {
    my ($self, $repo_url, $chart_name) = @_;
    $self->spec_set('repo',  $repo_url);
    $self->spec_set('chart', $chart_name);
    return $self;
}


sub set_version {
    my ($self, $version) = @_;
    $self->spec_set('version', $version);
    return $self;
}


sub set_values {
    my ($self, %values) = @_;
    # Helm keys carry dots (image.tag), so they must not travel through a
    # dotted spec path: fetch the map once and write into it directly.
    my $set = $self->spec_hash('set');
    @{$set}{keys %values} = values %values;
    return $self;
}


sub set_values_yaml {
    my ($self, $yaml_str) = @_;
    $self->spec_set('valuesContent', $yaml_str);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Role::HelmManaged - Role for K3s Helm chart management

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    package My::K3s::HelmChart;
    use IO::K8s::APIObject
        api_version     => 'helm.cattle.io/v1',
        resource_plural => 'helmcharts';
    with 'IO::K8s::Role::HelmManaged';

    package main;
    my $k8s = IO::K8s->new(with => ['IO::K8s::K3s']);
    my $chart = $k8s->new_object('HelmChart',
        metadata => { name => 'traefik', namespace => 'kube-system' },
    );
    $chart->from_repo('https://traefik.github.io/charts', 'traefik')
          ->set_version('25.0.0')
          ->set_values(replicas => 3);

=head1 DESCRIPTION

This role provides the fluent setters documented in README's K3s section
for working with C<HelmChart> and C<HelmChartConfig> CRDs from
L<IO::K8s::K3s>. Each setter writes through L<IO::K8s::Role::SpecBuilder>'s
C<spec_*> methods, so the methods work whether the underlying C<spec>
attribute is a plain hash or a typed object.

Use this role on a custom CRD class with
C<api_version =E<gt> 'helm.cattle.io/v1'> or
C<api_version =E<gt> 'k3s.cattle.io/v1'>, or compose it on the bundled
L<IO::K8s::K3s::V1::HelmChart> / L<IO::K8s::K3s::V1::HelmChartConfig>
classes to add the helpers at runtime.

=head2 from_repo

    $chart->from_repo($repo_url, $chart_name);

Sets the chart's C<spec.repo> to C<$repo_url> and C<spec.chart> to
C<$chart_name>, matching the HelmChart CRD's C<spec.chart> + C<spec.repo>
fields under C<helm.cattle.io/v1>. Returns C<$self> for chaining.

    $chart->from_repo('https://traefik.github.io/charts', 'traefik');

=head2 set_version

    $chart->set_version($version);

Sets the chart's C<spec.version> -- the Helm chart version to pin against,
not the C<apiVersion> of the CRD. Returns C<$self> for chaining.

    $chart->set_version('25.0.0');

=head2 set_values

    $chart->set_values(key1 => $value1, key2 => $value2, ...);

Merges the given key/value pairs into the chart's C<spec.set> hash,
preserving any values already present. This is the K3s equivalent of
C<helm install --set key=value ...> and ends up on the wire as the
C<spec.set> block the HelmChart CRD supports. Returns C<$self> for
chaining.

    $chart->set_values(replicas => 3, logLevel => 'info');

=head2 set_values_yaml

    $chart->set_values_yaml($yaml_str);

Sets the chart's C<spec.valuesContent> to a literal YAML blob. This is the
K3s equivalent of C<helm install --values values.yaml> -- the YAML is
shipped inside the manifest rather than being merged key by key. Returns
C<$self> for chaining.

    $chart->set_values_yaml(<<'YAML');
    replicas: 3
    service:
      type: LoadBalancer
    YAML

=head1 SEE ALSO

L<IO::K8s::K3s>, L<IO::K8s::Role::SpecBuilder>, L<IO::K8s::APIObject>

=cut

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
