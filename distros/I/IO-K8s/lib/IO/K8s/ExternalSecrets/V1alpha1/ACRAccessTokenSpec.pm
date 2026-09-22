package IO::K8s::ExternalSecrets::V1alpha1::ACRAccessTokenSpec;
# ABSTRACT: ACRAccessTokenSpec defines how to generate the access token e.g. how to authenticate and which registry to use.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth            => '+IO::K8s::ExternalSecrets::V1alpha1::ACRAuth', { required => 'schema' };
k8s environmentType => Str, { enum => [qw(PublicCloud USGovernmentCloud ChinaCloud GermanCloud AzureStackCloud)], default => 'PublicCloud' };
k8s registry        => Str, { required => 'schema' };
k8s scope           => Str;
k8s tenantId        => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::ACRAccessTokenSpec - ACRAccessTokenSpec defines how to generate the access token e.g. how to authenticate and which registry to use.

=head1 VERSION

version 1.108

=head2 auth

ACRAuth defines the authentication methods for Azure Container Registry.

=head2 environmentType

EnvironmentType specifies the Azure cloud environment endpoints to use for
connecting and authenticating with Azure. By default, it points to the public cloud AAD endpoint.
The following endpoints are available, also see here: https://github.com/Azure/go-autorest/blob/main/autorest/azure/environments.go#L152
PublicCloud, USGovernmentCloud, ChinaCloud, GermanCloud

=head2 registry

the domain name of the ACR registry
e.g. foobarexample.azurecr.io

=head2 scope

Define the scope for the access token, e.g. pull/push access for a repository.
if not provided it will return a refresh token that has full scope.
Note: you need to pin it down to the repository level, there is no wildcard available.

examples:
repository:my-repository:pull,push
repository:my-repository:pull

see docs for details: https://docs.docker.com/registry/spec/auth/scope/

=head2 tenantId

TenantID configures the Azure Tenant to send requests to. Required for ServicePrincipal auth type.

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
