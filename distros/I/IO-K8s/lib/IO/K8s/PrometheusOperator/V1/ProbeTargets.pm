package IO::K8s::PrometheusOperator::V1::ProbeTargets;
# ABSTRACT: targets defines a set of static or dynamically discovered targets to probe.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s ingress      => '+IO::K8s::PrometheusOperator::V1::ProbeTargetIngress';
k8s staticConfig => '+IO::K8s::PrometheusOperator::V1::ProbeTargetStaticConfig';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ProbeTargets - targets defines a set of static or dynamically discovered targets to probe.

=head1 VERSION

version 1.108

=head2 ingress

ingress defines the Ingress objects to probe and the relabeling
configuration.
If `staticConfig` is also defined, `staticConfig` takes precedence.

=head2 staticConfig

staticConfig defines the static list of targets to probe and the
relabeling configuration.
If `ingress` is also defined, `staticConfig` takes precedence.
More info: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#static_config.

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
