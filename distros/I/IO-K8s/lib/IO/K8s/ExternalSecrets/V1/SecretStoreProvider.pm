package IO::K8s::ExternalSecrets::V1::SecretStoreProvider;
# ABSTRACT: Used to configure the provider.
our $VERSION = '1.108';
use utf8;
use IO::K8s::Resource;

k8s akeyless                       => '+IO::K8s::ExternalSecrets::V1::AkeylessProvider';
k8s aws                            => '+IO::K8s::ExternalSecrets::V1::AWSProvider';
k8s azurekv                        => '+IO::K8s::ExternalSecrets::V1::AzureKVProvider';
k8s barbican                       => '+IO::K8s::ExternalSecrets::V1::BarbicanProvider';
k8s beyondtrust                    => '+IO::K8s::ExternalSecrets::V1::BeyondtrustProvider';
k8s beyondtrustworkloadcredentials => '+IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider';
k8s bitwardensecretsmanager        => '+IO::K8s::ExternalSecrets::V1::BitwardenSecretsManagerProvider';
k8s chef                           => '+IO::K8s::ExternalSecrets::V1::ChefProvider';
k8s cloudrusm                      => '+IO::K8s::ExternalSecrets::V1::CloudruSMProvider';
k8s conjur                         => '+IO::K8s::ExternalSecrets::V1::ConjurProvider';
k8s crd                            => '+IO::K8s::ExternalSecrets::V1::CRDProvider';
k8s delinea                        => '+IO::K8s::ExternalSecrets::V1::DelineaProvider';
k8s doppler                        => '+IO::K8s::ExternalSecrets::V1::DopplerProvider';
k8s dvls                           => '+IO::K8s::ExternalSecrets::V1::DVLSProvider';
k8s fake                           => '+IO::K8s::ExternalSecrets::V1::FakeProvider';
k8s fortanix                       => '+IO::K8s::ExternalSecrets::V1::FortanixProvider';
k8s gcpsm                          => '+IO::K8s::ExternalSecrets::V1::GCPSMProvider';
k8s github                         => '+IO::K8s::ExternalSecrets::V1::GithubProvider';
k8s gitlab                         => '+IO::K8s::ExternalSecrets::V1::GitlabProvider';
k8s ibm                            => '+IO::K8s::ExternalSecrets::V1::IBMProvider';
k8s infisical                      => '+IO::K8s::ExternalSecrets::V1::InfisicalProvider';
k8s keepersecurity                 => '+IO::K8s::ExternalSecrets::V1::KeeperSecurityProvider';
k8s kubernetes                     => '+IO::K8s::ExternalSecrets::V1::KubernetesProvider';
k8s nebiusmysterybox               => '+IO::K8s::ExternalSecrets::V1::NebiusMysteryboxProvider';
k8s ngrok                          => '+IO::K8s::ExternalSecrets::V1::NgrokProvider';
k8s onboardbase                    => '+IO::K8s::ExternalSecrets::V1::OnboardbaseProvider';
k8s onepassword                    => '+IO::K8s::ExternalSecrets::V1::OnePasswordProvider';
k8s onepasswordSDK                 => '+IO::K8s::ExternalSecrets::V1::OnePasswordSDKProvider';
k8s openBao                        => '+IO::K8s::ExternalSecrets::V1::OpenBaoProvider';
k8s oracle                         => '+IO::K8s::ExternalSecrets::V1::OracleProvider';
k8s ovh                            => '+IO::K8s::ExternalSecrets::V1::OvhProvider';
k8s passbolt                       => '+IO::K8s::ExternalSecrets::V1::PassboltProvider';
k8s passworddepot                  => '+IO::K8s::ExternalSecrets::V1::PasswordDepotProvider';
k8s previder                       => '+IO::K8s::ExternalSecrets::V1::PreviderProvider';
k8s pulumi                         => '+IO::K8s::ExternalSecrets::V1::PulumiProvider';
k8s scaleway                       => '+IO::K8s::ExternalSecrets::V1::ScalewayProvider';
k8s secretserver                   => '+IO::K8s::ExternalSecrets::V1::SecretServerProvider';
k8s senhasegura                    => '+IO::K8s::ExternalSecrets::V1::SenhaseguraProvider';
k8s vault                          => '+IO::K8s::ExternalSecrets::V1::VaultProvider';
k8s volcengine                     => '+IO::K8s::ExternalSecrets::V1::VolcengineProvider';
k8s webhook                        => '+IO::K8s::ExternalSecrets::V1::WebhookProvider';
k8s yandexcertificatemanager       => '+IO::K8s::ExternalSecrets::V1::YandexCertificateManagerProvider';
k8s yandexlockbox                  => '+IO::K8s::ExternalSecrets::V1::YandexLockboxProvider';













































1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::SecretStoreProvider - Used to configure the provider.

=head1 VERSION

version 1.108

=head2 akeyless

Akeyless configures this store to sync secrets using Akeyless Vault provider

=head2 aws

AWS configures this store to sync secrets using AWS Secret Manager provider

=head2 azurekv

AzureKV configures this store to sync secrets using Azure Key Vault provider

=head2 barbican

Barbican configures this store to sync secrets using the OpenStack Barbican provider

=head2 beyondtrust

Beyondtrust configures this store to sync secrets using Password Safe provider.

=head2 beyondtrustworkloadcredentials

BeyondtrustWorkloadCredentials configures this store to sync secrets using the BeyondTrust Workload Credentials provider.

=head2 bitwardensecretsmanager

BitwardenSecretsManager configures this store to sync secrets using BitwardenSecretsManager provider

=head2 chef

Chef configures this store to sync secrets with chef server

=head2 cloudrusm

CloudruSM configures this store to sync secrets using the Cloud.ru Secret Manager provider

=head2 conjur

Conjur configures this store to sync secrets using conjur provider

=head2 crd

CRD configures this store to sync secrets from arbitrary Kubernetes resources,
including both custom resources (CRDs) and core API resources. Resources are
selected by API group, version and kind, where group can be "" (empty string)
for core resources such as ConfigMap. Reading the core v1 Secret is
intentionally blocked — use the Kubernetes provider for that.

=head2 delinea

Delinea DevOps Secrets Vault
https://docs.delinea.com/online-help/products/devops-secrets-vault/current

=head2 doppler

Doppler configures this store to sync secrets using the Doppler provider

=head2 dvls

DVLS configures this store to sync secrets using Devolutions Server provider

=head2 fake

Fake configures a store with static key/value pairs

=head2 fortanix

Fortanix configures this store to sync secrets using the Fortanix provider

=head2 gcpsm

GCPSM configures this store to sync secrets using Google Cloud Platform Secret Manager provider

=head2 github

Github configures this store to push GitHub Actions or Dependabot secrets using the GitHub API provider.
Note: This provider only supports write operations (PushSecret) and cannot fetch secrets from GitHub

=head2 gitlab

GitLab configures this store to sync secrets using GitLab Variables provider

=head2 ibm

IBM configures this store to sync secrets using IBM Cloud provider

=head2 infisical

Infisical configures this store to sync secrets using the Infisical provider

=head2 keepersecurity

KeeperSecurity configures this store to sync secrets using the KeeperSecurity provider

=head2 kubernetes

Kubernetes configures this store to sync secrets using a Kubernetes cluster provider

=head2 nebiusmysterybox

NebiusMysterybox configures this store to sync secrets using NebiusMysterybox provider

=head2 ngrok

Ngrok configures this store to sync secrets using the ngrok provider.

=head2 onboardbase

Onboardbase configures this store to sync secrets using the Onboardbase provider

=head2 onepassword

OnePassword configures this store to sync secrets using the 1Password Cloud provider

=head2 onepasswordSDK

OnePasswordSDK configures this store to use 1Password's new Go SDK to sync secrets.

=head2 openBao

OpenBao configures this store to sync secrets using the OpenBao provider.

=head2 oracle

Oracle configures this store to sync secrets using Oracle Vault provider

=head2 ovh

OVHcloud configures this store to sync secrets using the OVHcloud provider.

=head2 passbolt

PassboltProvider provides access to Passbolt secrets manager.
See: https://www.passbolt.com.

=head2 passworddepot

PasswordDepotProvider configures a store to sync secrets with a Password Depot instance.

=head2 previder

Previder configures this store to sync secrets using the Previder provider

=head2 pulumi

Pulumi configures this store to sync secrets using the Pulumi provider

=head2 scaleway

Scaleway configures this store to sync secrets using the Scaleway provider.

=head2 secretserver

SecretServer configures this store to sync secrets using SecretServer provider
https://docs.delinea.com/online-help/secret-server/start.htm

=head2 senhasegura

Senhasegura configures this store to sync secrets using senhasegura provider

=head2 vault

Vault configures this store to sync secrets using the HashiCorp Vault provider.

=head2 volcengine

Volcengine configures this store to sync secrets using the Volcengine provider

=head2 webhook

Webhook configures this store to sync secrets using a generic templated webhook

=head2 yandexcertificatemanager

YandexCertificateManager configures this store to sync secrets using Yandex Certificate Manager provider

=head2 yandexlockbox

YandexLockbox configures this store to sync secrets using Yandex Lockbox provider

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
