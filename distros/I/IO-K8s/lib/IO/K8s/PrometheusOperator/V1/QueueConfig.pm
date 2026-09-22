package IO::K8s::PrometheusOperator::V1::QueueConfig;
# ABSTRACT: queueConfig allows tuning of the remote write queue parameters.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s batchSendDeadline => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s capacity          => Int;
k8s maxBackoff        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s maxRetries        => Int;
k8s maxSamplesPerSend => Int;
k8s maxShards         => Int;
k8s minBackoff        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s minShards         => Int;
k8s retryOnRateLimit  => Bool;
k8s sampleAgeLimit    => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::QueueConfig - queueConfig allows tuning of the remote write queue parameters.

=head1 VERSION

version 1.108

=head2 batchSendDeadline

batchSendDeadline defines the maximum time a sample will wait in buffer.

=head2 capacity

capacity defines the number of samples to buffer per shard before we start
dropping them.

=head2 maxBackoff

maxBackoff defines the maximum retry delay.

=head2 maxRetries

maxRetries defines the maximum number of times to retry a batch on recoverable errors.

=head2 maxSamplesPerSend

maxSamplesPerSend defines the maximum number of samples per send.

=head2 maxShards

maxShards defines the maximum number of shards, i.e. amount of concurrency.

=head2 minBackoff

minBackoff defines the initial retry delay. Gets doubled for every retry.

=head2 minShards

minShards defines the minimum number of shards, i.e. amount of concurrency.

=head2 retryOnRateLimit

retryOnRateLimit defines the retry upon receiving a 429 status code from the remote-write storage.

This is an *experimental feature*, it may change in any upcoming release
in a breaking way.

=head2 sampleAgeLimit

sampleAgeLimit drops samples older than the limit.
It requires Prometheus >= v2.50.0 or Thanos >= v0.32.0.

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
