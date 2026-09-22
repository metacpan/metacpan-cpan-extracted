package IO::K8s::ExternalSecrets::V1::InfisicalAuth;
# ABSTRACT: Auth configures how the Operator authenticates with the Infisical API
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s awsAuthCredentials        => '+IO::K8s::ExternalSecrets::V1::AwsAuthCredentials';
k8s azureAuthCredentials      => '+IO::K8s::ExternalSecrets::V1::AzureAuthCredentials';
k8s gcpIamAuthCredentials     => '+IO::K8s::ExternalSecrets::V1::GcpIamAuthCredentials';
k8s gcpIdTokenAuthCredentials => '+IO::K8s::ExternalSecrets::V1::GcpIDTokenAuthCredentials';
k8s jwtAuthCredentials        => '+IO::K8s::ExternalSecrets::V1::JwtAuthCredentials';
k8s kubernetesAuthCredentials => '+IO::K8s::ExternalSecrets::V1::KubernetesAuthCredentials';
k8s ldapAuthCredentials       => '+IO::K8s::ExternalSecrets::V1::LdapAuthCredentials';
k8s ociAuthCredentials        => '+IO::K8s::ExternalSecrets::V1::OciAuthCredentials';
k8s tokenAuthCredentials      => '+IO::K8s::ExternalSecrets::V1::TokenAuthCredentials';
k8s universalAuthCredentials  => '+IO::K8s::ExternalSecrets::V1::UniversalAuthCredentials';











1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::InfisicalAuth - Auth configures how the Operator authenticates with the Infisical API

=head1 VERSION

version 1.108

=head2 awsAuthCredentials

AwsAuthCredentials represents the credentials for AWS authentication.

=head2 azureAuthCredentials

AzureAuthCredentials represents the credentials for Azure authentication.

=head2 gcpIamAuthCredentials

GcpIamAuthCredentials represents the credentials for GCP IAM authentication.

=head2 gcpIdTokenAuthCredentials

GcpIDTokenAuthCredentials represents the credentials for GCP ID token authentication.

=head2 jwtAuthCredentials

JwtAuthCredentials represents the credentials for JWT authentication.

=head2 kubernetesAuthCredentials

KubernetesAuthCredentials represents the credentials for Kubernetes authentication.

=head2 ldapAuthCredentials

LdapAuthCredentials represents the credentials for LDAP authentication.

=head2 ociAuthCredentials

OciAuthCredentials represents the credentials for OCI authentication.

=head2 tokenAuthCredentials

TokenAuthCredentials represents the credentials for access token-based authentication.

=head2 universalAuthCredentials

UniversalAuthCredentials represents the client credentials for universal authentication.

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
