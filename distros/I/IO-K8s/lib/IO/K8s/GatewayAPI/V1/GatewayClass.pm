package IO::K8s::GatewayAPI::V1::GatewayClass;
# ABSTRACT: Gateway API controller class definition
our $VERSION = '1.006';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1',
    resource_plural => 'gatewayclasses';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1::GatewayClass - Gateway API controller class definition

=head1 VERSION

version 1.006

=head1 DESCRIPTION

Represents a GatewayClass resource from the Kubernetes Gateway API (C<gateway.networking.k8s.io/v1>). A GatewayClass defines a class of Gateways, identifying the controller implementation that will manage Gateways of this class. This is similar to IngressClass for Ingress resources. GatewayClass is a cluster-scoped resource. The C<spec> and C<status> fields are opaque hashrefs containing the Gateway API structure.

=head1 SEE ALSO

=over

=item * L<IO::K8s::GatewayAPI> - Gateway API module namespace

=item * L<https://gateway-api.sigs.k8s.io/api-types/gatewayclass/> - Upstream GatewayClass documentation

=item * L<IO::K8s::GatewayAPI::V1::Gateway> - Gateway instances that reference this class

=back

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
