package IO::K8s::CertManager::V1::AzureManagedIdentity;
# ABSTRACT: Auth: Azure Workload Identity or Azure Managed Service Identity: Settings to enable Azure Workload Identity or Azure Managed Service Identity If set, ClientID, ClientSecret and TenantID must not be set.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientID   => Str;
k8s resourceID => Str;
k8s tenantID   => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::AzureManagedIdentity - Auth: Azure Workload Identity or Azure Managed Service Identity: Settings to enable Azure Workload Identity or Azure Managed Service Identity If set, ClientID, ClientSecret and TenantID must not be set.

=head1 VERSION

version 1.108

=head2 clientID

client ID of the managed identity, cannot be used at the same time as resourceID

=head2 resourceID

resource ID of the managed identity, cannot be used at the same time as clientID
Cannot be used for Azure Managed Service Identity

=head2 tenantID

tenant ID of the managed identity, cannot be used at the same time as resourceID

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
