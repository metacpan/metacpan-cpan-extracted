package IO::K8s::ExternalSecrets::V1::PulumiOIDCAuth;
# ABSTRACT: OIDCConfig authenticates using Kubernetes ServiceAccount tokens via OIDC.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s expirationSeconds => Int, { minimum => 600, default => 600 };
k8s organization      => Str, { required => 'schema' };
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::PulumiOIDCAuth - OIDCConfig authenticates using Kubernetes ServiceAccount tokens via OIDC.

=head1 VERSION

version 1.108

=head2 expirationSeconds

ExpirationSeconds sets the token validity duration for service account and OIDC token.
Defaults to 10 minutes.

=head2 organization

Organization is the name of the Pulumi organization configured for OIDC authentication.

=head2 serviceAccountRef

ServiceAccountRef specifies the Kubernetes ServiceAccount to use for authentication.

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
