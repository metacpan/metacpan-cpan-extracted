package IO::K8s::PrometheusOperator::V1::TSDBSpec;
# ABSTRACT: tsdb defines the runtime reloadable configuration of the timeseries database(TSDB).
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s chunkEncoding                  => '+IO::K8s::PrometheusOperator::V1::ChunkEncodingSpec';
k8s outOfOrderTimeWindow           => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s staleSeriesCompactionThreshold => Quantity;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::TSDBSpec - tsdb defines the runtime reloadable configuration of the timeseries database(TSDB).

=head1 VERSION

version 1.108

=head2 chunkEncoding

chunkEncoding configures per-chunk-type encoding overrides.

It requires Prometheus >= v3.13.0.

Notice: Setting "Xor" is incompatible with --enable-feature=st-storage
(XOR chunks do not store start timestamps).

=head2 outOfOrderTimeWindow

outOfOrderTimeWindow defines how old an out-of-order/out-of-bounds sample can be with
respect to the TSDB max time.

An out-of-order/out-of-bounds sample is ingested into the TSDB as long as
the timestamp of the sample is >= (TSDB.MaxTime - outOfOrderTimeWindow).

This is an *experimental feature*, it may change in any upcoming release
in a breaking way.

It requires Prometheus >= v2.39.0 or PrometheusAgent >= v2.54.0.

=head2 staleSeriesCompactionThreshold

staleSeriesCompactionThreshold configures the trigger point for compacting
stale series from memory into persistent blocks and removing those stale
series from memory.

The threshold is a number between 0.0 and 1.0. It represents the ratio of
stale series in memory to the total series in memory. The stale series
compaction is triggered when this ratio crosses the configured threshold.
It may not trigger the stale series compaction if the usual head compaction
is about to happen soon.

If set to 0, stale series compaction is disabled.

It requires Prometheus >= v3.10.0.

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
