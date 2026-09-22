package IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRoute53;
# ABSTRACT: Use the AWS Route53 API to manage DNS01 challenge records.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessKeyID              => Str;
k8s accessKeyIDSecretRef     => '+IO::K8s::CertManager::V1::SecretKeySelector';
k8s auth                     => '+IO::K8s::CertManager::V1::Route53Auth';
k8s hostedZoneID             => Str;
k8s region                   => Str;
k8s role                     => Str;
k8s secretAccessKeySecretRef => '+IO::K8s::CertManager::V1::SecretKeySelector';








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuerDNS01ProviderRoute53 - Use the AWS Route53 API to manage DNS01 challenge records.

=head1 VERSION

version 1.108

=head2 accessKeyID

The AccessKeyID is used for authentication.
Cannot be set when SecretAccessKeyID is set.
If neither the Access Key nor Key ID are set, we fall back to using env
vars, shared credentials file, or AWS Instance metadata,
see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials

=head2 accessKeyIDSecretRef

The SecretAccessKey is used for authentication. If set, pull the AWS
access key ID from a key within a Kubernetes Secret.
Cannot be set when AccessKeyID is set.
If neither the Access Key nor Key ID are set, we fall back to using env
vars, shared credentials file, or AWS Instance metadata,
see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials

=head2 auth

Auth configures how cert-manager authenticates.

=head2 hostedZoneID

If set, the provider will manage only this zone in Route53 and will not do a lookup using the route53:ListHostedZonesByName api call.

=head2 region

Override the AWS region.

Route53 is a global service and does not have regional endpoints but the
region specified here (or via environment variables) is used as a hint to
help compute the correct AWS credential scope and partition when it
connects to Route53. See:
- [Amazon Route 53 endpoints and quotas](https://docs.aws.amazon.com/general/latest/gr/r53.html)
- [Global services](https://docs.aws.amazon.com/whitepapers/latest/aws-fault-isolation-boundaries/global-services.html)

If you omit this region field, cert-manager will use the region from
AWS_REGION and AWS_DEFAULT_REGION environment variables, if they are set
in the cert-manager controller Pod.

The `region` field is not needed if you use [IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).
Instead an AWS_REGION environment variable is added to the cert-manager controller Pod by:
[Amazon EKS Pod Identity Webhook](https://github.com/aws/amazon-eks-pod-identity-webhook).
In this case this `region` field value is ignored.

The `region` field is not needed if you use [EKS Pod Identities](https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html).
Instead an AWS_REGION environment variable is added to the cert-manager controller Pod by:
[Amazon EKS Pod Identity Agent](https://github.com/aws/eks-pod-identity-agent),
In this case this `region` field value is ignored.

=head2 role

Role is a Role ARN which the Route53 provider will assume using either the explicit credentials AccessKeyID/SecretAccessKey
or the inferred credentials from environment variables, shared credentials file or AWS Instance metadata

=head2 secretAccessKeySecretRef

The SecretAccessKey is used for authentication.
If neither the Access Key nor Key ID are set, we fall back to using env
vars, shared credentials file, or AWS Instance metadata,
see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials

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
