package IO::K8s::Traefik::V1alpha1::RouterObservabilityConfig;
# ABSTRACT: Observability defines the observability configuration for a router.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessLogs     => Bool;
k8s metrics        => Bool;
k8s traceVerbosity => Str, { enum => [qw(minimal detailed)], default => 'minimal' };
k8s tracing        => Bool;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::RouterObservabilityConfig - Observability defines the observability configuration for a router.

=head1 VERSION

version 1.108

=head2 accessLogs

AccessLogs enables access logs for this router.

=head2 metrics

Metrics enables metrics for this router.

=head2 traceVerbosity

TraceVerbosity defines the verbosity level of the tracing for this router.

=head2 tracing

Tracing enables tracing for this router.

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
