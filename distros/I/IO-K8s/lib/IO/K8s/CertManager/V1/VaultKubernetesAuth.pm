package IO::K8s::CertManager::V1::VaultKubernetesAuth;
# ABSTRACT: Kubernetes authenticates with Vault by passing the ServiceAccount token stored in the named Secret resource to the Vault server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s mountPath         => Str;
k8s role              => Str, { required => 'schema' };
k8s secretRef         => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s serviceAccountRef => '+IO::K8s::CertManager::V1::ServiceAccountRef';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VaultKubernetesAuth - Kubernetes authenticates with Vault by passing the ServiceAccount token stored in the named Secret resource to the Vault server.

=head1 VERSION

version 1.108

=head2 mountPath

The Vault mountPath here is the mount path to use when authenticating with
Vault. For example, setting a value to `/v1/auth/foo`, will use the path
`/v1/auth/foo/login` to authenticate with Vault. If unspecified, the
default value "/v1/auth/kubernetes" will be used.

=head2 role

A required field containing the Vault Role to assume. A Role binds a
Kubernetes ServiceAccount with a set of Vault policies.

=head2 secretRef

The required Secret field containing a Kubernetes ServiceAccount JWT used
for authenticating with Vault. Use of 'ambient credentials' is not
supported.

=head2 serviceAccountRef

A reference to a service account that will be used to request a bound
token (also known as "projected token"). Compared to using "secretRef",
using this field means that you don't rely on statically bound tokens. To
use this field, you must configure an RBAC rule to let cert-manager
request a token.

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
