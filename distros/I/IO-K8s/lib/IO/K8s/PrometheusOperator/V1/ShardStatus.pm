package IO::K8s::PrometheusOperator::V1::ShardStatus;
# ABSTRACT: ShardStatus
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s availableReplicas   => Int, { required => 'schema' };
k8s replicas            => Int, { required => 'schema' };
k8s shardID             => Str, { required => 'schema' };
k8s unavailableReplicas => Int, { required => 'schema' };
k8s updatedReplicas     => Int, { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ShardStatus - ShardStatus

=head1 VERSION

version 1.108

=head2 availableReplicas

availableReplicas defines the total number of available pods (ready for at least minReadySeconds)
targeted by this shard.

=head2 replicas

replicas defines the total number of pods targeted by this shard.

=head2 shardID

shardID defines the identifier of the shard.

=head2 unavailableReplicas

unavailableReplicas defines the Total number of unavailable pods targeted by this shard.

=head2 updatedReplicas

updatedReplicas defines the total number of non-terminated pods targeted by this shard
that have the desired spec.

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
