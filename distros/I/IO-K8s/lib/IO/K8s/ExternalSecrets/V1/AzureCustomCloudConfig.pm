package IO::K8s::ExternalSecrets::V1::AzureCustomCloudConfig;
# ABSTRACT: CustomCloudConfig defines custom Azure endpoints for non-standard clouds.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s activeDirectoryEndpoint => Str, { required => 'schema' };
k8s keyVaultDNSSuffix       => Str;
k8s keyVaultEndpoint        => Str;
k8s resourceManagerEndpoint => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AzureCustomCloudConfig - CustomCloudConfig defines custom Azure endpoints for non-standard clouds.

=head1 VERSION

version 1.108

=head2 activeDirectoryEndpoint

ActiveDirectoryEndpoint is the AAD endpoint for authentication
Required when using custom cloud configuration

=head2 keyVaultDNSSuffix

KeyVaultDNSSuffix is the DNS suffix for Key Vault URLs

=head2 keyVaultEndpoint

KeyVaultEndpoint is the Key Vault service endpoint

=head2 resourceManagerEndpoint

ResourceManagerEndpoint is the Azure Resource Manager endpoint

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
