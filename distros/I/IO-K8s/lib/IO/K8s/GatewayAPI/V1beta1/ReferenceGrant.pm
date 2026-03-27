package IO::K8s::GatewayAPI::V1beta1::ReferenceGrant;
# ABSTRACT: Gateway API cross-namespace reference permission
our $VERSION = '1.100';
use IO::K8s::APIObject
    api_version     => 'gateway.networking.k8s.io/v1beta1',
    resource_plural => 'referencegrants';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::GatewayAPI::V1beta1::ReferenceGrant - Gateway API cross-namespace reference permission

=head1 VERSION

version 1.100

=head1 DESCRIPTION

Represents a ReferenceGrant resource from the Kubernetes Gateway API (C<gateway.networking.k8s.io/v1beta1>). A ReferenceGrant grants permission for resources in other namespaces to reference resources in this namespace, enabling cross-namespace resource sharing in a controlled manner. ReferenceGrant is a namespaced resource. The C<spec> and C<status> fields are opaque hashrefs containing the Gateway API structure.

=head1 SEE ALSO

=over

=item * L<IO::K8s::GatewayAPI> - Gateway API module namespace

=item * L<https://gateway-api.sigs.k8s.io/api-types/referencegrant/> - Upstream ReferenceGrant documentation

=item * L<IO::K8s::GatewayAPI::V1::Gateway> - May use ReferenceGrant for cross-namespace references

=item * L<IO::K8s::GatewayAPI::V1::HTTPRoute> - May use ReferenceGrant for backend references

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

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
