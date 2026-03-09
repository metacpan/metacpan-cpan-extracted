package IO::K8s::Api::Autoscaling::V2::ObjectMetricStatus;
# ABSTRACT: ObjectMetricStatus indicates the current value of a metric describing a kubernetes object (for example, hits-per-second on an Ingress object).
our $VERSION = '1.008';
use IO::K8s::Resource;

k8s current => 'Autoscaling::V2::MetricValueStatus', 'required';


k8s describedObject => 'Autoscaling::V2::CrossVersionObjectReference', 'required';


k8s metric => 'Autoscaling::V2::MetricIdentifier', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::ObjectMetricStatus - ObjectMetricStatus indicates the current value of a metric describing a kubernetes object (for example, hits-per-second on an Ingress object).

=head1 VERSION

version 1.008

=head2 current

current contains the current value for the given metric

=head2 describedObject

DescribedObject specifies the descriptions of a object,such as kind,name apiVersion

=head2 metric

metric identifies the target metric by name and selector

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

Jose Luis Martinez <jlmartin@cpan.org> (original author, inactive)

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jose Luis Martinez.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
