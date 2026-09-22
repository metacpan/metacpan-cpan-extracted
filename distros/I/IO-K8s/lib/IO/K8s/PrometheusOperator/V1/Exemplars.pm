package IO::K8s::PrometheusOperator::V1::Exemplars;
# ABSTRACT: exemplars related settings that are runtime reloadable.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s maxSize => Int;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::Exemplars - exemplars related settings that are runtime reloadable.

=head1 VERSION

version 1.108

=head2 maxSize

maxSize defines the maximum number of exemplars stored in memory for all series.

exemplar-storage itself must be enabled using the `spec.enableFeature`
option for exemplars to be scraped in the first place.

If not set, Prometheus uses its default value. A value of zero or less
than zero disables the storage.

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
