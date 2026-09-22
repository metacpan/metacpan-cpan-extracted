package IO::K8s::Traefik::V1alpha1::IngressRouteTCPSpec;
# ABSTRACT: IngressRouteTCPSpec defines the desired state of IngressRouteTCP.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s entryPoints      => [Str];
k8s ingressClassName => Str;
k8s routes           => ['+IO::K8s::Traefik::V1alpha1::RouteTCP'], { required => 'schema' };
k8s tls              => '+IO::K8s::Traefik::V1alpha1::TLSTCP';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::IngressRouteTCPSpec - IngressRouteTCPSpec defines the desired state of IngressRouteTCP.

=head1 VERSION

version 1.108

=head2 entryPoints

EntryPoints defines the list of entry point names to bind to.
Entry points have to be configured in the static configuration.
More info: https://doc.traefik.io/traefik/v3.7/reference/install-configuration/entrypoints/
Default: all.

=head2 ingressClassName

IngressClassName defines the name of the IngressClass cluster resource.

=head2 routes

Routes defines the list of routes.

=head2 tls

TLS defines the TLS configuration on a layer 4 / TCP Route.
More info: https://doc.traefik.io/traefik/v3.7/reference/routing-configuration/tcp/routing/router/#tls

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
