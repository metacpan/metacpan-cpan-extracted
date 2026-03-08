package IO::K8s::Api::Autoscaling::V2::MetricIdentifier;
# ABSTRACT: MetricIdentifier defines the name and optionally selector for a metric
our $VERSION = '1.006';
use IO::K8s::Resource;

k8s name => Str, 'required';


k8s selector => 'Meta::V1::LabelSelector';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::MetricIdentifier - MetricIdentifier defines the name and optionally selector for a metric

=head1 VERSION

version 1.006

=head2 name

name is the name of the given metric

=head2 selector

selector is the string-encoded form of a standard kubernetes label selector for the given metric When set, it is passed as an additional parameter to the metrics server for more specific metrics scoping. When unset, just the metricName will be used to gather metrics.

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
