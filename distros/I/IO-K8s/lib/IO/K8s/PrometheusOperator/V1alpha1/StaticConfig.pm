package IO::K8s::PrometheusOperator::V1alpha1::StaticConfig;
# ABSTRACT: StaticConfig defines a Prometheus static configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s labels  => { Str => 1 };
k8s targets => [Str], { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1alpha1::StaticConfig - StaticConfig defines a Prometheus static configuration.

=head1 VERSION

version 1.108

=head2 labels

labels defines labels assigned to all metrics scraped from the targets.

=head2 targets

targets defines the list of targets for this static configuration.

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
