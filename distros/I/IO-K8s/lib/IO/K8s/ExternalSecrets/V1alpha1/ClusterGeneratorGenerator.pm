package IO::K8s::ExternalSecrets::V1alpha1::ClusterGeneratorGenerator;
# ABSTRACT: Generator the spec for this generator, must match the kind.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s acrAccessTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::ACRAccessTokenSpec';
k8s beyondtrustWorkloadCredentialsDynamicSecretSpec => '+IO::K8s::ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecretSpec';
k8s cloudsmithAccessTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::CloudsmithAccessTokenSpec';
k8s ecrAuthorizationTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::ECRAuthorizationTokenSpec';
k8s fakeSpec => '+IO::K8s::ExternalSecrets::V1alpha1::FakeSpec';
k8s gcrAccessTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::GCRAccessTokenSpec';
k8s githubAccessTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::GithubAccessTokenSpec';
k8s gitlabDeployTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::GitlabDeployTokenSpec';
k8s grafanaSpec => '+IO::K8s::ExternalSecrets::V1alpha1::GrafanaSpec';
k8s mfaSpec => '+IO::K8s::ExternalSecrets::V1alpha1::MFASpec';
k8s passwordSpec => '+IO::K8s::ExternalSecrets::V1alpha1::PasswordSpec';
k8s quayAccessTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::QuayAccessTokenSpec';
k8s sshKeySpec => '+IO::K8s::ExternalSecrets::V1alpha1::SSHKeySpec';
k8s stsSessionTokenSpec => '+IO::K8s::ExternalSecrets::V1alpha1::STSSessionTokenSpec';
k8s uuidSpec => '+IO::K8s::ExternalSecrets::V1alpha1::UUIDSpec';
k8s vaultDynamicSecretSpec => '+IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecretSpec';
k8s webhookSpec => '+IO::K8s::ExternalSecrets::V1alpha1::WebhookSpec';


















1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::ClusterGeneratorGenerator - Generator the spec for this generator, must match the kind.

=head1 VERSION

version 1.108

=head2 acrAccessTokenSpec

ACRAccessTokenSpec defines how to generate the access token
e.g. how to authenticate and which registry to use.
see: https://github.com/Azure/acr/blob/main/docs/AAD-OAuth.md#overview

=head2 beyondtrustWorkloadCredentialsDynamicSecretSpec

BeyondtrustWorkloadCredentialsDynamicSecretSpec defines the desired spec for BeyondtrustWorkloadCredentials dynamic generator.
This generator enables obtaining temporary, short-lived credentials from BeyondTrust Workload Credentials.
For more information, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api

=head2 cloudsmithAccessTokenSpec

CloudsmithAccessTokenSpec defines the configuration for generating a Cloudsmith access token using OIDC authentication.

=head2 ecrAuthorizationTokenSpec

ECRAuthorizationTokenSpec defines the desired state to generate an AWS ECR authorization token.

=head2 fakeSpec

FakeSpec contains the static data.

=head2 gcrAccessTokenSpec

GCRAccessTokenSpec defines the desired state to generate a Google Container Registry access token.

=head2 githubAccessTokenSpec

GithubAccessTokenSpec defines the desired state to generate a GitHub access token.

=head2 gitlabDeployTokenSpec

GitlabDeployTokenSpec defines the desired state to generate a GitLab deploy token.

=head2 grafanaSpec

GrafanaSpec controls the behavior of the grafana generator.

=head2 mfaSpec

MFASpec controls the behavior of the mfa generator.

=head2 passwordSpec

PasswordSpec controls the behavior of the password generator.

=head2 quayAccessTokenSpec

QuayAccessTokenSpec defines the desired state to generate a Quay access token.

=head2 sshKeySpec

SSHKeySpec controls the behavior of the ssh key generator.

=head2 stsSessionTokenSpec

STSSessionTokenSpec defines the desired state to generate an AWS STS session token.

=head2 uuidSpec

UUIDSpec controls the behavior of the uuid generator.

=head2 vaultDynamicSecretSpec

VaultDynamicSecretSpec defines the desired spec of VaultDynamicSecret.

=head2 webhookSpec

WebhookSpec controls the behavior of the external generator. Any body parameters should be passed to the server through the parameters field.

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
