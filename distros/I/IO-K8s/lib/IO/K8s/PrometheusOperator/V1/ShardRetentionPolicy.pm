package IO::K8s::PrometheusOperator::V1::ShardRetentionPolicy;
# ABSTRACT: shardRetentionPolicy defines the retention policy for the Prometheus shards.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s retain     => '+IO::K8s::PrometheusOperator::V1::RetainConfig';
k8s whenScaled => Str, { enum => [qw(Retain Delete)] };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::ShardRetentionPolicy - shardRetentionPolicy defines the retention policy for the Prometheus shards.

=head1 VERSION

version 1.108

=head2 retain

retain defines the config for retention when the retention policy is set
to `Retain`.

If not defined, the operator will use the retention duration configured
for the Prometheus data. If the resource uses size-based retention, the
shard(s) are kept forever (unless manually deleted).

=head2 whenScaled

whenScaled defines the retention policy when the Prometheus shards are scaled down.
* `Delete`, the operator will delete the pods from the scaled-down shard(s).
* `Retain`, the operator will keep the pods from the scaled-down shard(s), so the data can still be queried.

If not defined, the operator assumes the `Delete` value.

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
