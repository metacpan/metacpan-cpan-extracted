package IO::K8s::ExternalSecrets::V1::VaultAuth;
# ABSTRACT: Auth configures how secret-manager authenticates with the Vault server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s appRole        => '+IO::K8s::ExternalSecrets::V1::VaultAppRole';
k8s cert           => '+IO::K8s::ExternalSecrets::V1::VaultCertAuth';
k8s gcp            => '+IO::K8s::ExternalSecrets::V1::VaultGCPAuth';
k8s iam            => '+IO::K8s::ExternalSecrets::V1::VaultIamAuth';
k8s jwt            => '+IO::K8s::ExternalSecrets::V1::VaultJwtAuth';
k8s kubernetes     => '+IO::K8s::ExternalSecrets::V1::VaultKubernetesAuth';
k8s ldap           => '+IO::K8s::ExternalSecrets::V1::VaultLdapAuth';
k8s namespace      => Str;
k8s tokenSecretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s userPass       => '+IO::K8s::ExternalSecrets::V1::VaultUserPassAuth';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::VaultAuth - Auth configures how secret-manager authenticates with the Vault server.

=head1 VERSION

version 1.108

=head2 appRole

AppRole authenticates with Vault using the App Role auth mechanism,
with the role and secret stored in a Kubernetes Secret resource.

=head2 cert

Cert authenticates with TLS Certificates by passing client certificate, private key and ca certificate
Cert authentication method

=head2 gcp

Gcp authenticates with Vault using Google Cloud Platform authentication method
GCP authentication method

=head2 iam

Iam authenticates with vault by passing a special AWS request signed with AWS IAM credentials
AWS IAM authentication method

=head2 jwt

Jwt authenticates with Vault by passing role and JWT token using the
JWT/OIDC authentication method

=head2 kubernetes

Kubernetes authenticates with Vault by passing the ServiceAccount
token stored in the named Secret resource to the Vault server.

=head2 ldap

Ldap authenticates with Vault by passing username/password pair using
the LDAP authentication method

=head2 namespace

Name of the vault namespace to authenticate to. This can be different than the namespace your secret is in.
Namespaces is a set of features within Vault Enterprise that allows
Vault environments to support Secure Multi-tenancy. e.g: "ns1".
More about namespaces can be found here https://www.vaultproject.io/docs/enterprise/namespaces
This will default to Vault.Namespace field if set, or empty otherwise

=head2 tokenSecretRef

TokenSecretRef authenticates with Vault by presenting a token.

=head2 userPass

UserPass authenticates with Vault by passing username/password pair

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
