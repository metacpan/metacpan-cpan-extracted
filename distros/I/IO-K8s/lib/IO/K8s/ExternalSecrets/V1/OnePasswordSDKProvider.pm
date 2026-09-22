package IO::K8s::ExternalSecrets::V1::OnePasswordSDKProvider;
# ABSTRACT: OnePasswordSDK configures this store to use 1Password's new Go SDK to sync secrets.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth            => '+IO::K8s::ExternalSecrets::V1::OnePasswordSDKAuth', { required => 'schema' };
k8s cache           => '+IO::K8s::ExternalSecrets::V1::CacheConfig';
k8s environment     => Str;
k8s integrationInfo => '+IO::K8s::ExternalSecrets::V1::IntegrationInfo';
k8s vault           => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OnePasswordSDKProvider - OnePasswordSDK configures this store to use 1Password's new Go SDK to sync secrets.

=head1 VERSION

version 1.108

=head2 auth

Auth defines the information necessary to authenticate against OnePassword API.

=head2 cache

Cache configures client-side caching for read operations (GetSecret, GetSecretMap).
When enabled, secrets are cached with the specified TTL.
Write operations (PushSecret, DeleteSecret) automatically invalidate relevant cache entries.
If omitted, caching is disabled (default).
cache: {} is a valid option to set.

=head2 environment

Environment defines the 1Password Environment ID to read variables from.
Environments are read-only: PushSecret, DeleteSecret, and SecretExists return an error when set.
Mutually exclusive with Vault.

=head2 integrationInfo

IntegrationInfo specifies the name and version of the integration built using the 1Password Go SDK.
If you don't know which name and version to use, use `DefaultIntegrationName` and `DefaultIntegrationVersion`, respectively.

=head2 vault

Vault defines the vault's name or uuid to access. Do NOT add op:// prefix. This will be done automatically.
Mutually exclusive with Environment.

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
