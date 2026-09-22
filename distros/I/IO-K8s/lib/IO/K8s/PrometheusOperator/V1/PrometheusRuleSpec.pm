package IO::K8s::PrometheusOperator::V1::PrometheusRuleSpec;
# ABSTRACT: spec defines the specification of desired alerting rule definitions for Prometheus.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s groups => ['+IO::K8s::PrometheusOperator::V1::RuleGroup'];


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::PrometheusRuleSpec - spec defines the specification of desired alerting rule definitions for Prometheus.

=head1 VERSION

version 1.108

=head2 groups

groups defines the content of Prometheus rule file

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
