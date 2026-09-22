package IO::K8s::PrometheusOperator::V1::RollingUpdateStatefulSetStrategy;
# ABSTRACT: rollingUpdate is used to communicate parameters when type is RollingUpdate.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s maxUnavailable => IntOrStr;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::RollingUpdateStatefulSetStrategy - rollingUpdate is used to communicate parameters when type is RollingUpdate.

=head1 VERSION

version 1.108

=head2 maxUnavailable

maxUnavailable is the maximum number of pods that can be unavailable
during the update. The value can be an absolute number (ex: 5) or a
percentage of desired pods (ex: 10%). Absolute number is calculated from
percentage by rounding up. This can not be 0.  Defaults to 1. This field
is alpha-level and is only honored by servers that enable the
MaxUnavailableStatefulSet feature. The field applies to all pods in the
range 0 to Replicas-1.  That means if there is any unavailable pod in
the range 0 to Replicas-1, it will be counted towards MaxUnavailable.

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
