package IO::K8s::PrometheusOperator::V1::StatefulSetUpdateStrategy;
# ABSTRACT: updateStrategy indicates the strategy that will be employed to update Pods in the StatefulSet when a revision is made to statefulset's Pod Template.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s rollingUpdate => '+IO::K8s::PrometheusOperator::V1::RollingUpdateStatefulSetStrategy';
k8s type          => Str, { required => 'schema', enum => [qw(OnDelete RollingUpdate)] };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::StatefulSetUpdateStrategy - updateStrategy indicates the strategy that will be employed to update Pods in the StatefulSet when a revision is made to statefulset's Pod Template.

=head1 VERSION

version 1.108

=head2 rollingUpdate

rollingUpdate is used to communicate parameters when type is RollingUpdate.

=head2 type

type indicates the type of the StatefulSetUpdateStrategy.

Default is RollingUpdate.

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
