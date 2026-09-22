package IO::K8s::PrometheusOperator::V1::PrometheusStatus;
# ABSTRACT: status defines the most recent observed status of the Prometheus cluster.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s availableReplicas   => Int;
k8s conditions          => ['+IO::K8s::PrometheusOperator::V1::Condition'];
k8s paused              => Bool;
k8s replicas            => Int;
k8s selector            => Str;
k8s shardStatuses       => ['+IO::K8s::PrometheusOperator::V1::ShardStatus'];
k8s shards              => Int;
k8s unavailableReplicas => Int;
k8s updatedReplicas     => Int;










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PrometheusStatus - status defines the most recent observed status of the Prometheus cluster.

=head1 VERSION

version 1.108

=head2 availableReplicas

availableReplicas defines the total number of available pods (ready for at least minReadySeconds)
targeted by this Prometheus deployment.

=head2 conditions

conditions defines the current state of the Prometheus deployment.

=head2 paused

paused defines whether any actions on the underlying managed objects are
being performed. Only delete actions will be performed.

=head2 replicas

replicas defines the total number of non-terminated pods targeted by this Prometheus deployment
(their labels match the selector).

=head2 selector

selector used to match the pods targeted by this Prometheus resource.

=head2 shardStatuses

shardStatuses defines the list has one entry per shard. Each entry provides a summary of the shard status.

=head2 shards

shards defines the most recently observed number of shards.

=head2 unavailableReplicas

unavailableReplicas defines the total number of unavailable pods targeted by this Prometheus deployment.

=head2 updatedReplicas

updatedReplicas defines the total number of non-terminated pods targeted by this Prometheus deployment
that have the desired version spec.

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
