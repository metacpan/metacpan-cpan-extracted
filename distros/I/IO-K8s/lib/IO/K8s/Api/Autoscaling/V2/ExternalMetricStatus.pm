package IO::K8s::Api::Autoscaling::V2::ExternalMetricStatus;
# ABSTRACT: ExternalMetricStatus indicates the current value of a global metric not associated with any Kubernetes object.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s current => 'Autoscaling::V2::MetricValueStatus', 'required';


k8s metric => 'Autoscaling::V2::MetricIdentifier', 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Autoscaling::V2::ExternalMetricStatus - ExternalMetricStatus indicates the current value of a global metric not associated with any Kubernetes object.

=head1 VERSION

version 1.009

=head2 current

current contains the current value for the given metric

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
