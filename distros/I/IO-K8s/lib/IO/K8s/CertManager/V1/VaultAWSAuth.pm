package IO::K8s::CertManager::V1::VaultAWSAuth;
# ABSTRACT: AWS authenticates with Vault using AWS IAM authentication.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s iamRoleArn        => Str;
k8s mountPath         => Str;
k8s region            => Str;
k8s role              => Str, { required => 'schema' };
k8s serviceAccountRef => '+IO::K8s::CertManager::V1::ServiceAccountRef';
k8s vaultHeaderValue  => Str;







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VaultAWSAuth - AWS authenticates with Vault using AWS IAM authentication.

=head1 VERSION

version 1.108

=head2 iamRoleArn

The ARN of the AWS IAM role to assume using the Kubernetes service account
token. Required when using IRSA (serviceAccountRef is set).
This role must have a trust policy that allows the OIDC provider to assume it.

=head2 mountPath

The Vault mountPath here is the mount path to use when authenticating with
Vault. For example, setting a value to `/v1/auth/foo`, will use the path
`/v1/auth/foo/login` to authenticate with Vault. If unspecified, the
default value "/v1/auth/aws" will be used.

=head2 region

The AWS region to use for authentication. If not specified, the region
will be determined from AWS_REGION or AWS_DEFAULT_REGION environment
variables, falling back to "us-east-1" if not set.

=head2 role

A required field containing the Vault Role to assume when authenticating.

=head2 serviceAccountRef

A reference to a service account that will be used to request a web identity
token for IRSA (IAM Roles for Service Accounts) authentication.

=head2 vaultHeaderValue

The Vault header value to include in the STS signing request.
This is used to prevent replay attacks.

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
