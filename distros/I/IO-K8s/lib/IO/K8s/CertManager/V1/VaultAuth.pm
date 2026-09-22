package IO::K8s::CertManager::V1::VaultAuth;
# ABSTRACT: Auth configures how cert-manager authenticates with the Vault server.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s appRole           => '+IO::K8s::CertManager::V1::VaultAppRole';
k8s aws               => '+IO::K8s::CertManager::V1::VaultAWSAuth';
k8s clientCertificate => '+IO::K8s::CertManager::V1::VaultClientCertificateAuth';
k8s kubernetes        => '+IO::K8s::CertManager::V1::VaultKubernetesAuth';
k8s tokenSecretRef    => '+IO::K8s::CertManager::V1::SecretKeySelector';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VaultAuth - Auth configures how cert-manager authenticates with the Vault server.

=head1 VERSION

version 1.108

=head2 appRole

AppRole authenticates with Vault using the App Role auth mechanism,
with the role and secret stored in a Kubernetes Secret resource.

=head2 aws

AWS authenticates with Vault using AWS IAM authentication.
This allows authentication using IAM roles for service accounts (IRSA),
EKS Pod Identity (PIA), or ambient credentials (EC2 instance profiles, ECS task role).

=head2 clientCertificate

ClientCertificate authenticates with Vault by presenting a client
certificate during the request's TLS handshake.
Works only when using HTTPS protocol.

=head2 kubernetes

Kubernetes authenticates with Vault by passing the ServiceAccount
token stored in the named Secret resource to the Vault server.

=head2 tokenSecretRef

TokenSecretRef authenticates with Vault by presenting a token.

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
