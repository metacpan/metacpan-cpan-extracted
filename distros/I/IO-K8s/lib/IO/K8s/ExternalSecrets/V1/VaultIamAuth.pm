package IO::K8s::ExternalSecrets::V1::VaultIamAuth;
# ABSTRACT: Iam authenticates with vault by passing a special AWS request signed with AWS IAM credentials AWS IAM authentication method
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s externalID          => Str;
k8s jwt                 => '+IO::K8s::ExternalSecrets::V1::VaultAwsJWTAuth';
k8s path                => Str;
k8s region              => Str;
k8s role                => Str;
k8s secretRef           => '+IO::K8s::ExternalSecrets::V1::VaultAwsAuthSecretRef';
k8s vaultAwsIamServerID => Str;
k8s vaultRole           => Str, { required => 'schema' };









1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::VaultIamAuth - Iam authenticates with vault by passing a special AWS request signed with AWS IAM credentials AWS IAM authentication method

=head1 VERSION

version 1.108

=head2 externalID

AWS External ID set on assumed IAM roles

=head2 jwt

Specify a service account with IRSA enabled

=head2 path

Path where the AWS auth method is enabled in Vault, e.g: "aws"

=head2 region

AWS region

=head2 role

This is the AWS role to be assumed before talking to vault

=head2 secretRef

Specify credentials in a Secret object

=head2 vaultAwsIamServerID

X-Vault-AWS-IAM-Server-ID is an additional header used by Vault IAM auth method to mitigate against different types of replay attacks. More details here: https://developer.hashicorp.com/vault/docs/auth/aws

=head2 vaultRole

Vault Role. In vault, a role describes an identity with a set of permissions, groups, or policies you want to attach a user of the secrets engine

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
