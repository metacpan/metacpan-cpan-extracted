package IO::K8s::GatewayAPI;
# ABSTRACT: Gateway API CRD resource map provider for IO::K8s
our $VERSION = '1.008';
use Moo;
with 'IO::K8s::Role::ResourceMap';

sub resource_map {
    return {
        # gateway.networking.k8s.io/v1
        GatewayClass   => 'GatewayAPI::V1::GatewayClass',
        Gateway        => 'GatewayAPI::V1::Gateway',
        HTTPRoute      => 'GatewayAPI::V1::HTTPRoute',
        GRPCRoute      => 'GatewayAPI::V1::GRPCRoute',
        # gateway.networking.k8s.io/v1beta1
        ReferenceGrant => 'GatewayAPI::V1beta1::ReferenceGrant',
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI - Gateway API CRD resource map provider for IO::K8s

=head1 VERSION

version 1.008

=head1 SYNOPSIS

    my $k8s = IO::K8s->new(with => ['IO::K8s::GatewayAPI']);

    my $gw = $k8s->new_object('Gateway',
        metadata => { name => 'my-gateway', namespace => 'default' },
        spec => {
            gatewayClassName => 'istio',
            listeners => [{ name => 'http', port => 80, protocol => 'HTTP' }],
        },
    );

    print $gw->to_yaml;

=head1 DESCRIPTION

Resource map provider for the L<Kubernetes Gateway API|https://gateway-api.sigs.k8s.io/>
Custom Resource Definitions. Registers 5 CRD classes covering
C<gateway.networking.k8s.io/v1> (GA) and C<gateway.networking.k8s.io/v1beta1>
(beta).

The Gateway API is an official Kubernetes SIG-Network project that provides
expressive, extensible, and role-oriented interfaces for service networking.

Not loaded by default — opt in via the C<with> constructor parameter of
L<IO::K8s> or by calling C<< $k8s->add('IO::K8s::GatewayAPI') >> at runtime.

=head2 Included CRDs (gateway.networking.k8s.io/v1)

GatewayClass (cluster-scoped), Gateway (namespaced), HTTPRoute (namespaced),
GRPCRoute (namespaced)

=head2 Included CRDs (gateway.networking.k8s.io/v1beta1)

ReferenceGrant (namespaced)

=head1 SEE ALSO

L<IO::K8s>

L<Gateway API documentation|https://gateway-api.sigs.k8s.io/>

L<Gateway API reference|https://gateway-api.sigs.k8s.io/reference/spec/>

L<GatewayClass|https://gateway-api.sigs.k8s.io/api-types/gatewayclass/>

L<HTTPRoute|https://gateway-api.sigs.k8s.io/api-types/httproute/>

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
