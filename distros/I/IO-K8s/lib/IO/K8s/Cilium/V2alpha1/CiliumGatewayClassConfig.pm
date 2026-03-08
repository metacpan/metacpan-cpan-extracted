package IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfig;
# ABSTRACT: Cilium Gateway API class configuration
our $VERSION = '1.006';
use IO::K8s::APIObject
    api_version     => 'cilium.io/v2alpha1',
    resource_plural => 'ciliumgatewayclassconfigs';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Cilium::V2alpha1::CiliumGatewayClassConfig - Cilium Gateway API class configuration

=head1 VERSION

version 1.006

=head1 DESCRIPTION

This cluster-scoped resource provides configuration for the Cilium Gateway API controller, defining how Cilium implements Kubernetes Gateway API resources for ingress traffic management. It uses API version C<cilium.io/v2alpha1>. The C<spec> and C<status> fields contain opaque CRD-specific data structures managed by the Cilium Gateway API controller.

=head1 SEE ALSO

=over

=item * L<IO::K8s::Cilium> - Main Cilium CRD namespace

=item * L<https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/> - Upstream Cilium Gateway API documentation

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
