package IO::K8s::Traefik::V1alpha1::TraefikServiceSpec;
# ABSTRACT: TraefikServiceSpec defines the desired state of a TraefikService.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s failover            => '+IO::K8s::Traefik::V1alpha1::Failover';
k8s highestRandomWeight => '+IO::K8s::Traefik::V1alpha1::HighestRandomWeight';
k8s mirroring           => '+IO::K8s::Traefik::V1alpha1::Mirroring';
k8s weighted            => '+IO::K8s::Traefik::V1alpha1::WeightedRoundRobin';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TraefikServiceSpec - TraefikServiceSpec defines the desired state of a TraefikService.

=head1 VERSION

version 1.108

=head2 failover

Failover defines the Failover service configuration.

=head2 highestRandomWeight

HighestRandomWeight defines the highest random weight service configuration.

=head2 mirroring

Mirroring defines the Mirroring service configuration.

=head2 weighted

Weighted defines the Weighted Round Robin configuration.

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
