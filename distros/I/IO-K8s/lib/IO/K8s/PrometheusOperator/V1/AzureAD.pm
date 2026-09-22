package IO::K8s::PrometheusOperator::V1::AzureAD;
# ABSTRACT: azureAd for the URL.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cloud            => Str, { enum => [qw(AzureChina AzureGovernment AzurePublic)] };
k8s managedIdentity  => '+IO::K8s::PrometheusOperator::V1::ManagedIdentity';
k8s oauth            => '+IO::K8s::PrometheusOperator::V1::AzureOAuth';
k8s scope            => Str, { pattern => qr/^[\w\s:\/.\\-]+$/ };
k8s sdk              => '+IO::K8s::PrometheusOperator::V1::AzureSDK';
k8s workloadIdentity => '+IO::K8s::PrometheusOperator::V1::AzureWorkloadIdentity';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::PrometheusOperator::V1::AzureAD - azureAd for the URL.

=head1 VERSION

version 1.108

=head2 cloud

cloud defines the Azure Cloud. Options are 'AzurePublic', 'AzureChina', or 'AzureGovernment'.

=head2 managedIdentity

managedIdentity defines the Azure User-assigned Managed identity.
Cannot be set at the same time as `oauth`, `sdk` or `workloadIdentity`.

=head2 oauth

oauth defines the oauth config that is being used to authenticate.
Cannot be set at the same time as `managedIdentity`, `sdk` or `workloadIdentity`.

It requires Prometheus >= v2.48.0 or Thanos >= v0.31.0.

=head2 scope

scope is the custom OAuth 2.0 scope to request when acquiring tokens.
It requires Prometheus >= 3.9.0. Currently not supported by Thanos.

=head2 sdk

sdk defines the Azure SDK config that is being used to authenticate.
See https://learn.microsoft.com/en-us/azure/developer/go/azure-sdk-authentication
Cannot be set at the same time as `oauth`, `managedIdentity` or `workloadIdentity`.

It requires Prometheus >= v2.52.0 or Thanos >= v0.36.0.

=head2 workloadIdentity

workloadIdentity defines the Azure Workload Identity authentication.
Cannot be set at the same time as `oauth`, `managedIdentity`, or `sdk`.

It requires Prometheus >= 3.7.0. Currently not supported by Thanos.

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
