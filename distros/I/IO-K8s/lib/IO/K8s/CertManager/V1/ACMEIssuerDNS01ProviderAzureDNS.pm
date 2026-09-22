package IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAzureDNS;
# ABSTRACT: Use the Microsoft Azure DNS API to manage DNS01 challenge records.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientID              => Str;
k8s clientSecretSecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s environment           => Str, { enum => [qw(AzurePublicCloud AzureChinaCloud AzureGermanCloud AzureUSGovernmentCloud)] };
k8s hostedZoneName        => Str;
k8s managedIdentity       => '+IO::K8s::CertManager::V1::AzureManagedIdentity';
k8s resourceGroupName     => Str, { required => 'schema' };
k8s subscriptionID        => Str, { required => 'schema' };
k8s tenantID              => Str;
k8s zoneType              => Str, { enum => [qw(AzurePublicZone AzurePrivateZone)] };










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderAzureDNS - Use the Microsoft Azure DNS API to manage DNS01 challenge records.

=head1 VERSION

version 1.108

=head2 clientID

Auth: Azure Service Principal:
The ClientID of the Azure Service Principal used to authenticate with Azure DNS.
If set, ClientSecret and TenantID must also be set.

=head2 clientSecretSecretRef

Auth: Azure Service Principal:
A reference to a Secret containing the password associated with the Service Principal.
If set, ClientID and TenantID must also be set.

=head2 environment

name of the Azure environment (default AzurePublicCloud)

=head2 hostedZoneName

name of the DNS zone that should be used

=head2 managedIdentity

Auth: Azure Workload Identity or Azure Managed Service Identity:
Settings to enable Azure Workload Identity or Azure Managed Service Identity
If set, ClientID, ClientSecret and TenantID must not be set.

=head2 resourceGroupName

resource group the DNS zone is located in

=head2 subscriptionID

ID of the Azure subscription

=head2 tenantID

Auth: Azure Service Principal:
The TenantID of the Azure Service Principal used to authenticate with Azure DNS.
If set, ClientID and ClientSecret must also be set.

=head2 zoneType

ZoneType determines which type of Azure DNS zone to use.

Valid values are:
  - AzurePublicZone  (default): Use a public Azure DNS zone.
  - AzurePrivateZone: Use an Azure Private DNS zone.

If not specified, AzurePublicZone is used.

Support for Azure Private DNS zones is currently
experimental and may change in future releases.

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
