package IO::K8s::ExternalSecrets::V1::OracleProvider;
# ABSTRACT: Oracle configures this store to sync secrets using Oracle Vault provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth              => '+IO::K8s::ExternalSecrets::V1::OracleAuth';
k8s compartment       => Str;
k8s encryptionKey     => Str;
k8s principalType     => Str, { enum => ['','UserPrincipal','InstancePrincipal','Workload'] };
k8s region            => Str, { required => 'schema' };
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';
k8s vault             => Str, { required => 'schema' };








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OracleProvider - Oracle configures this store to sync secrets using Oracle Vault provider

=head1 VERSION

version 1.108

=head2 auth

Auth configures how secret-manager authenticates with the Oracle Vault.
If empty, use the instance principal, otherwise the user credentials specified in Auth.

=head2 compartment

Compartment is the vault compartment OCID.
Required for PushSecret

=head2 encryptionKey

EncryptionKey is the OCID of the encryption key within the vault.
Required for PushSecret

=head2 principalType

The type of principal to use for authentication. If left blank, the Auth struct will
determine the principal type. This optional field must be specified if using
workload identity.

=head2 region

Region is the region where vault is located.

=head2 serviceAccountRef

ServiceAccountRef specified the service account
that should be used when authenticating with WorkloadIdentity.

=head2 vault

Vault is the vault's OCID of the specific vault where secret is located.

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
