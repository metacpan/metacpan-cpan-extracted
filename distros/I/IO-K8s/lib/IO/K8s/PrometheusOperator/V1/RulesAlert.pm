package IO::K8s::PrometheusOperator::V1::RulesAlert;
# ABSTRACT: alert defines the parameters of the Prometheus rules' engine.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s forGracePeriod     => Str;
k8s forOutageTolerance => Str;
k8s resendDelay        => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::RulesAlert - alert defines the parameters of the Prometheus rules' engine.

=head1 VERSION

version 1.108

=head2 forGracePeriod

forGracePeriod defines the minimum duration between alert and restored 'for' state.

This is maintained only for alerts with a configured 'for' time greater
than the grace period.

=head2 forOutageTolerance

forOutageTolerance defines the max time to tolerate prometheus outage for restoring 'for' state of
alert.

=head2 resendDelay

resendDelay defines the minimum amount of time to wait before resending an alert to
Alertmanager.

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
