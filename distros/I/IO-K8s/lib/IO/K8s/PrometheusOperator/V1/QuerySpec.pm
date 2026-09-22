package IO::K8s::PrometheusOperator::V1::QuerySpec;
# ABSTRACT: query defines the configuration of the Prometheus query service.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s lookbackDelta  => Str;
k8s maxConcurrency => Int, { minimum => 1 };
k8s maxSamples     => Int;
k8s timeout        => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::QuerySpec - query defines the configuration of the Prometheus query service.

=head1 VERSION

version 1.108

=head2 lookbackDelta

lookbackDelta defines the delta difference allowed for retrieving metrics during expression evaluations.

=head2 maxConcurrency

maxConcurrency defines the number of concurrent queries that can be run at once.

=head2 maxSamples

maxSamples defines the maximum number of samples a single query can load into memory. Note that
queries will fail if they would load more samples than this into memory,
so this also limits the number of samples a query can return.

=head2 timeout

timeout defines the maximum time a query may take before being aborted.

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
