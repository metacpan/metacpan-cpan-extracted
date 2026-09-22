package IO::K8s::PrometheusOperator::V1::ObjectReference;
# ABSTRACT: ObjectReference references a PodMonitor, ServiceMonitor, Probe or PrometheusRule object.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s group     => Str, { enum => [qw(monitoring.coreos.com)], default => 'monitoring.coreos.com' };
k8s name      => Str;
k8s namespace => Str, { required => 'schema' };
k8s resource  => Str, { required => 'schema', enum => [qw(prometheusrules servicemonitors podmonitors probes scrapeconfigs)] };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ObjectReference - ObjectReference references a PodMonitor, ServiceMonitor, Probe or PrometheusRule object.

=head1 VERSION

version 1.108

=head2 group

group of the referent. When not specified, it defaults to `monitoring.coreos.com`

=head2 name

name of the referent. When not set, all resources in the namespace are matched.

=head2 namespace

namespace of the referent.
More info: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/

=head2 resource

resource of the referent.

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
