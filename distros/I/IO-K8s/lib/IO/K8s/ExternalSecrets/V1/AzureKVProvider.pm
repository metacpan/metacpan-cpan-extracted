package IO::K8s::ExternalSecrets::V1::AzureKVProvider;
# ABSTRACT: AzureKV configures this store to sync secrets using Azure Key Vault provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s authSecretRef     => '+IO::K8s::ExternalSecrets::V1::AzureKVAuth';
k8s authType          => Str, { enum => [qw(ServicePrincipal ManagedIdentity WorkloadIdentity)], default => 'ServicePrincipal' };
k8s customCloudConfig => '+IO::K8s::ExternalSecrets::V1::AzureCustomCloudConfig';
k8s environmentType   => Str, { enum => [qw(PublicCloud USGovernmentCloud ChinaCloud GermanCloud AzureStackCloud)], default => 'PublicCloud' };
k8s identityId        => Str;
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';
k8s tenantId          => Str;
k8s useAzureSDK       => Bool, { default => 0 };
k8s vaultUrl          => Str, { required => 'schema' };










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AzureKVProvider - AzureKV configures this store to sync secrets using Azure Key Vault provider

=head1 VERSION

version 1.108

=head2 authSecretRef

Auth configures how the operator authenticates with Azure. Required for ServicePrincipal auth type. Optional for WorkloadIdentity.

=head2 authType

Auth type defines how to authenticate to the keyvault service.
Valid values are:
- "ServicePrincipal" (default): Using a service principal (tenantId, clientId, clientSecret)
- "ManagedIdentity": Using Managed Identity assigned to the pod (see aad-pod-identity)
- "WorkloadIdentity": Using a Kubernetes ServiceAccount federated with Entra ID

=head2 customCloudConfig

CustomCloudConfig defines custom Azure endpoints for non-standard clouds.
Required when EnvironmentType is AzureStackCloud.
Optional for other environment types - useful for Azure China when using Workload Identity
with AKS, where the OIDC issuer (login.partner.microsoftonline.cn) differs from the
standard China Cloud endpoint (login.chinacloudapi.cn).
IMPORTANT: This feature REQUIRES UseAzureSDK to be set to true. Custom cloud
configuration is not supported with the legacy go-autorest SDK.

=head2 environmentType

EnvironmentType specifies the Azure cloud environment endpoints to use for
connecting and authenticating with Azure. By default it points to the public cloud AAD endpoint.
The following endpoints are available, also see here: https://github.com/Azure/go-autorest/blob/main/autorest/azure/environments.go#L152
PublicCloud, USGovernmentCloud, ChinaCloud, GermanCloud, AzureStackCloud
Use AzureStackCloud when you need to configure custom Azure Stack Hub or Azure Stack Edge endpoints.

=head2 identityId

If multiple Managed Identity is assigned to the pod, you can select the one to be used

=head2 serviceAccountRef

ServiceAccountRef specified the service account
that should be used when authenticating with WorkloadIdentity.

=head2 tenantId

TenantID configures the Azure Tenant to send requests to. Required for ServicePrincipal auth type. Optional for WorkloadIdentity.

=head2 useAzureSDK

UseAzureSDK enables the use of the new Azure SDK for Go (azcore-based) instead of the legacy go-autorest SDK.
This is experimental and may have behavioral differences. Defaults to false (legacy SDK).

=head2 vaultUrl

Vault Url from which the secrets to be fetched from.

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
