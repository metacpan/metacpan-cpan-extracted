package IO::K8s::PrometheusOperator::V1::ShardingStrategy;
# ABSTRACT: shardingStrategy defines the sharding strategy for distributing scraped targets across Prometheus shards.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s mode     => Str, { enum => [qw(Address Topology)] };
k8s topology => '+IO::K8s::PrometheusOperator::V1::TopologyShardingStrategy';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ShardingStrategy - shardingStrategy defines the sharding strategy for distributing scraped targets across Prometheus shards.

=head1 VERSION

version 1.108

=head2 mode

mode defines the sharding mode. Can be 'Address' or 'Topology'.

'Address' is the default mode and distributes targets across shards
based on a hash of the target address.

'Topology' enables zone-aware sharding where each shard is assigned to a
specific topology zone and only scrapes targets in that zone.
(Alpha) Using the 'Topology' mode requires the `PrometheusTopologySharding`
feature gate to be enabled.

=head2 topology

topology defines the configuration for topology-aware sharding.
This field is only valid when mode is set to 'Topology'.

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
