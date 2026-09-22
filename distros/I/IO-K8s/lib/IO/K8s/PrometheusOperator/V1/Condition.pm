package IO::K8s::PrometheusOperator::V1::Condition;
# ABSTRACT: Condition represents the state of the resources associated with the Prometheus, Alertmanager or ThanosRuler resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s lastTransitionTime => Time, { required => 'schema' };
k8s message            => Str;
k8s observedGeneration => Int;
k8s reason             => Str;
k8s status             => Str, { required => 'schema' };
k8s type               => Str, { required => 'schema' };







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::Condition - Condition represents the state of the resources associated with the Prometheus, Alertmanager or ThanosRuler resource.

=head1 VERSION

version 1.108

=head2 lastTransitionTime

lastTransitionTime is the time of the last update to the current status
property.

=head2 message

message defines human-readable message indicating details for the
condition's last transition.

=head2 observedGeneration

observedGeneration defines the .metadata.generation that the condition was
set based upon. For instance, if C<.metadata.generation> is currently 12,
but the C<.status.conditions[].observedGeneration> is 9, the condition is
out of date with respect to the current state of the instance.

=head2 reason

reason for the condition's last transition.

=head2 status

status of the condition.

=head2 type

type of the condition being reported.

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
