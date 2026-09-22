package IO::K8s::ExternalSecrets::V1::BitwardenSecretsManagerProvider;
# ABSTRACT: BitwardenSecretsManager configures this store to sync secrets using BitwardenSecretsManager provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiURL                => Str;
k8s auth                  => '+IO::K8s::ExternalSecrets::V1::BitwardenSecretsManagerAuth', { required => 'schema' };
k8s bitwardenServerSDKURL => Str;
k8s caBundle              => Str;
k8s caProvider            => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s identityURL           => Str;
k8s organizationID        => Str, { required => 'schema' };
k8s projectID             => Str, { required => 'schema' };









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::BitwardenSecretsManagerProvider - BitwardenSecretsManager configures this store to sync secrets using BitwardenSecretsManager provider

=head1 VERSION

version 1.108

=head2 apiURL

No description in the upstream schema.

=head2 auth

Auth configures how secret-manager authenticates with a bitwarden machine account instance.
Make sure that the token being used has permissions on the given secret.

=head2 bitwardenServerSDKURL

No description in the upstream schema.

=head2 caBundle

Base64 encoded certificate for the bitwarden server sdk. The sdk MUST run with HTTPS to make sure no MITM attack
can be performed.

=head2 caProvider

see: https://external-secrets.io/latest/spec/#external-secrets.io/v1alpha1.CAProvider

=head2 identityURL

No description in the upstream schema.

=head2 organizationID

OrganizationID determines which organization this secret store manages.

=head2 projectID

ProjectID determines which project this secret store manages.

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
