package IO::K8s::PrometheusOperator::V1::Rule;
# ABSTRACT: Rule describes an alerting or recording rule See Prometheus documentation: [alerting](https://www.prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) or [recording](https://www.prometheus.io/docs/prometheus/latest/configuration/recording_rules/#recording-rules) rule
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s alert           => Str;
k8s annotations     => { Str => 1 };
k8s expr            => IntOrStr, { required => 'schema' };
k8s for             => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s keep_firing_for => Str, { pattern => qr/^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$/ };
k8s labels          => { Str => 1 };
k8s record          => Str;








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::Rule - Rule describes an alerting or recording rule See Prometheus documentation: [alerting](https://www.prometheus.io/docs/prometheus/latest/configuration/alerting_rules/) or [recording](https://www.prometheus.io/docs/prometheus/latest/configuration/recording_rules/#recording-rules) rule

=head1 VERSION

version 1.108

=head2 alert

alert defines the name of the alert. Must be a valid label value.
Only one of `record` and `alert` must be set.

=head2 annotations

annotations defines annotations to add to each alert.
Only valid for alerting rules.

=head2 expr

expr defines the PromQL expression to evaluate.

=head2 for

for defines how alerts are considered firing once they have been returned for this long.

=head2 keep_firing_for

keep_firing_for defines how long an alert will continue firing after the condition that triggered it has cleared.

=head2 labels

labels defines labels to add or overwrite.

=head2 record

record defines the name of the time series to output to. Must be a valid metric name.
Only one of `record` and `alert` must be set.

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
