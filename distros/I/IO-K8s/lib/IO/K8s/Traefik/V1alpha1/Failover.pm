package IO::K8s::Traefik::V1alpha1::Failover;
# ABSTRACT: Failover defines the Failover service configuration.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s errors   => '+IO::K8s::Traefik::V1alpha1::FailoverError', { required => 'schema' };
k8s fallback => '+IO::K8s::Traefik::V1alpha1::LoadBalancerSpec', { required => 'schema' };
k8s service  => '+IO::K8s::Traefik::V1alpha1::LoadBalancerSpec', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::Failover - Failover defines the Failover service configuration.

=head1 VERSION

version 1.108

=head2 errors

Errors defines which errors should trigger the use of the fallback service.

=head2 fallback

Fallback defines the fallback service to use when the main service returns an error.

=head2 service

Service defines the main service to use.

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
