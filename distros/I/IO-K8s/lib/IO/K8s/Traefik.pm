package IO::K8s::Traefik;
# ABSTRACT: Traefik CRD resource map provider for IO::K8s
our $VERSION = '1.009';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub resource_map {
    return {
        IngressRoute        => 'Traefik::V1alpha1::IngressRoute',
        IngressRouteTCP     => 'Traefik::V1alpha1::IngressRouteTCP',
        IngressRouteUDP     => 'Traefik::V1alpha1::IngressRouteUDP',
        Middleware          => 'Traefik::V1alpha1::Middleware',
        MiddlewareTCP       => 'Traefik::V1alpha1::MiddlewareTCP',
        ServersTransport    => 'Traefik::V1alpha1::ServersTransport',
        ServersTransportTCP => 'Traefik::V1alpha1::ServersTransportTCP',
        TLSOption           => 'Traefik::V1alpha1::TLSOption',
        TLSStore            => 'Traefik::V1alpha1::TLSStore',
        TraefikService      => 'Traefik::V1alpha1::TraefikService',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik - Traefik CRD resource map provider for IO::K8s

=head1 VERSION

version 1.009

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::Traefik']);

    my $ir = $k8s->new_object('IngressRoute',
        metadata => { name => 'my-route', namespace => 'default' },
        spec => {
            entryPoints => ['web'],
            routes => [{ match => 'Host(`example.com`)', kind => 'Rule' }],
        },
    );

    print $ir->to_yaml;

=head1 DESCRIPTION

Resource map provider for L<Traefik|https://traefik.io/> Custom Resource
Definitions. Registers 10 CRD classes for C<traefik.io/v1alpha1>.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::Traefik') >> at runtime.

=head2 Included CRDs (traefik.io/v1alpha1)

IngressRoute, IngressRouteTCP, IngressRouteUDP, Middleware, MiddlewareTCP,
ServersTransport, ServersTransportTCP, TLSOption, TLSStore, TraefikService

All resources are namespace-scoped.

=head1 SEE ALSO

L<IO::K8s>

L<Traefik documentation|https://doc.traefik.io/traefik/>

L<Traefik Kubernetes CRD reference|https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/>

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
