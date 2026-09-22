package IO::K8s::PrometheusOperator::V1alpha1::FileSDConfig;
# ABSTRACT: FileSDConfig defines a Prometheus file service discovery configuration See https://prometheus.io/docs/prometheus/latest/configuration/configuration/#file_sd_config
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s files           => [Str], { required => 'schema', pattern => qr/^[^*]*(\*[^\/]*)?\.(json|yml|yaml|JSON|YML|YAML)$/ };
k8s refreshInterval => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::FileSDConfig - FileSDConfig defines a Prometheus file service discovery configuration See https://prometheus.io/docs/prometheus/latest/configuration/configuration/#file_sd_config

=head1 VERSION

version 1.108

=head2 files

files defines the list of files to be used for file discovery. Recommendation: use absolute paths. While relative paths work, the
prometheus-operator project makes no guarantees about the working directory where the configuration file is
stored.
Files must be mounted using Prometheus.ConfigMaps or Prometheus.Secrets.

=head2 refreshInterval

refreshInterval defines the time after which the provided names are refreshed.
If not set, Prometheus uses its default value.

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
