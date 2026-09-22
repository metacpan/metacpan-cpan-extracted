package IO::K8s::PrometheusOperator::V1::TracingConfig;
# ABSTRACT: tracingConfig defines tracing in Prometheus.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientType       => Str, { enum => [qw(http grpc HTTP GRPC)] };
k8s compression      => Str, { enum => [qw(gzip Gzip)] };
k8s endpoint         => Str, { required => 'schema' };
k8s headers          => { Str => 1 };
k8s insecure         => Bool;
k8s samplingFraction => Quantity;
k8s timeout          => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s tlsConfig        => '+IO::K8s::PrometheusOperator::V1::TLSConfig';









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::TracingConfig - tracingConfig defines tracing in Prometheus.

=head1 VERSION

version 1.108

=head2 clientType

clientType defines the client used to export the traces. Supported values are `HTTP` and `GRPC`.

=head2 compression

compression key for supported compression types. The only supported value is `Gzip`.

=head2 endpoint

endpoint to send the traces to. Should be provided in format <host>:<port>.

=head2 headers

headers defines the key-value pairs to be used as headers associated with gRPC or HTTP requests.

=head2 insecure

insecure if disabled, the client will use a secure connection.

=head2 samplingFraction

samplingFraction defines the probability a given trace will be sampled. Must be a float from 0 through 1.

=head2 timeout

timeout defines the maximum time the exporter will wait for each batch export.

=head2 tlsConfig

tlsConfig to use when sending traces.

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
