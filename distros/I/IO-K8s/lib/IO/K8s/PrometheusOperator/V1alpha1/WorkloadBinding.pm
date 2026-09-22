package IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding;
# ABSTRACT: WorkloadBinding is a link between a configuration resource and a workload resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s conditions => ['+IO::K8s::PrometheusOperator::V1::WorkloadBindingCondition'];
k8s group      => Str, { required => 'schema', enum => [qw(monitoring.coreos.com)] };
k8s name       => Str, { required => 'schema' };
k8s namespace  => Str, { required => 'schema' };
k8s resource   => Str, { required => 'schema', enum => [qw(prometheuses prometheusagents thanosrulers alertmanagers)] };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::WorkloadBinding - WorkloadBinding is a link between a configuration resource and a workload resource.

=head1 VERSION

version 1.108

=head2 conditions

conditions defines the current state of the configuration resource when bound to the referenced Workload object.

=head2 group

group defines the group of the referenced resource.

=head2 name

name defines the name of the referenced object.

=head2 namespace

namespace defines the namespace of the referenced object.

=head2 resource

resource defines the type of resource being referenced (e.g. Prometheus, PrometheusAgent, ThanosRuler or Alertmanager).

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
