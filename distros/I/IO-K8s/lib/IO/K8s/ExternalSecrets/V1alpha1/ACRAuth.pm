package IO::K8s::ExternalSecrets::V1alpha1::ACRAuth;
# ABSTRACT: ACRAuth defines the authentication methods for Azure Container Registry.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s managedIdentity  => '+IO::K8s::ExternalSecrets::V1alpha1::ACRManagedIdentity';
k8s servicePrincipal => '+IO::K8s::ExternalSecrets::V1alpha1::ACRServicePrincipal';
k8s workloadIdentity => '+IO::K8s::ExternalSecrets::V1alpha1::ACRWorkloadIdentity';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::ACRAuth - ACRAuth defines the authentication methods for Azure Container Registry.

=head1 VERSION

version 1.108

=head2 managedIdentity

ManagedIdentity uses Azure Managed Identity to authenticate with Azure.

=head2 servicePrincipal

ServicePrincipal uses Azure Service Principal credentials to authenticate with Azure.

=head2 workloadIdentity

WorkloadIdentity uses Azure Workload Identity to authenticate with Azure.

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
