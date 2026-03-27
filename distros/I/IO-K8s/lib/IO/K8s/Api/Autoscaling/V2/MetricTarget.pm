package IO::K8s::Api::Autoscaling::V2::MetricTarget;
# ABSTRACT: MetricTarget defines the target value, average value, or average utilization of a specific metric
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s averageUtilization => Int;


k8s averageValue => Quantity;


k8s type => Str, 'required';


k8s value => Quantity;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::MetricTarget - MetricTarget defines the target value, average value, or average utilization of a specific metric

=head1 VERSION

version 1.100

=head2 averageUtilization

averageUtilization is the target value of the average of the resource metric across all relevant pods, represented as a percentage of the requested value of the resource for the pods. Currently only valid for Resource metric source type

=head2 averageValue

averageValue is the target value of the average of the metric across all relevant pods (as a quantity)

=head2 type

type represents whether the metric type is Utilization, Value, or AverageValue

=head2 value

value is the target value of the metric (as a quantity).

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
