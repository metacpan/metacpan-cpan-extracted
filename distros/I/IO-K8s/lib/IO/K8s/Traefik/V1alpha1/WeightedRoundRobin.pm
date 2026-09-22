package IO::K8s::Traefik::V1alpha1::WeightedRoundRobin;
# ABSTRACT: Weighted defines the Weighted Round Robin configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s services => ['+IO::K8s::Traefik::V1alpha1::Service'];
k8s sticky   => '+IO::K8s::Traefik::V1alpha1::Sticky';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::WeightedRoundRobin - Weighted defines the Weighted Round Robin configuration.

=head1 VERSION

version 1.108

=head2 services

Services defines the list of Kubernetes Service and/or TraefikService to load-balance, with weight.

=head2 sticky

Sticky defines whether sticky sessions are enabled.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/kubernetes/crd/http/traefikservice/#stickiness-and-load-balancing

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
