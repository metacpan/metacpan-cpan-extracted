package IO::K8s::Traefik::V1alpha1::TLSOption;
# ABSTRACT: Traefik TLS configuration options
our $VERSION = '1.006';
use IO::K8s::APIObject
    api_version     => 'traefik.io/v1alpha1',
    resource_plural => 'tlsoptions';
with 'IO::K8s::Role::Namespaced';

k8s spec   => { Str => 1 };
k8s status => { Str => 1 };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TLSOption - Traefik TLS configuration options

=head1 VERSION

version 1.006

=head1 DESCRIPTION

TLSOption configures TLS parameters for Traefik. It defines minimum TLS version, cipher suites, client authentication, and other TLS-specific settings. This is a namespace-scoped custom resource using API version C<traefik.io/v1alpha1>. The C<spec> and C<status> fields are opaque hashrefs managed by Traefik.

=head1 SEE ALSO

=over

=item * L<IO::K8s::Traefik> - Traefik CRD namespace

=item * L<https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/> - Official Traefik CRD documentation

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
