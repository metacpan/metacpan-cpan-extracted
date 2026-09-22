package IO::K8s::ExternalSecrets::V1::AWSProvider;
# ABSTRACT: AWS configures this store to sync secrets using AWS Secret Manager provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s additionalRoles   => [Str];
k8s auth              => '+IO::K8s::ExternalSecrets::V1::AWSAuth';
k8s customSessionTags => { Str => 1 };
k8s externalID        => Str;
k8s prefix            => Str;
k8s region            => Str, { required => 'schema' };
k8s role              => Str;
k8s secretsManager    => '+IO::K8s::ExternalSecrets::V1::SecretsManager';
k8s service           => Str, { required => 'schema', enum => [qw(SecretsManager ParameterStore CertificateManager)] };
k8s sessionTags       => ['+IO::K8s::ExternalSecrets::V1::Tag'];
k8s sessionTagsPolicy => Str, { enum => [qw(None Simple Custom)], default => 'None' };
k8s transitiveTagKeys => [Str];













1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AWSProvider - AWS configures this store to sync secrets using AWS Secret Manager provider

=head1 VERSION

version 1.108

=head2 additionalRoles

AdditionalRoles is a chained list of Role ARNs which the provider will sequentially assume before assuming the Role

=head2 auth

Auth defines the information necessary to authenticate against AWS
if not set aws sdk will infer credentials from your environment
see: https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/configuring-sdk.html#specifying-credentials

=head2 customSessionTags

CustomSessionTags defines additional STS session tags to include when SessionTagsPolicy is Custom.
These are merged with the automatically injected esoNamespace, esoStoreName, and esoStoreKind tags.

=head2 externalID

AWS External ID set on assumed IAM roles

=head2 prefix

Prefix adds a prefix to all retrieved values.

=head2 region

AWS Region to be used for the provider

=head2 role

Role is a Role ARN which the provider will assume

=head2 secretsManager

SecretsManager defines how the provider behaves when interacting with AWS SecretsManager

=head2 service

Service defines which service should be used to fetch the secrets

=head2 sessionTags

AWS STS assume role session tags

=head2 sessionTagsPolicy

SessionTagsPolicy controls whether and how STS session tags are added when assuming roles.
None (default): no tags are added.
Simple: automatically adds esoNamespace (from the ExternalSecret), esoStoreName, and esoStoreKind tags.
Custom: adds esoNamespace, esoStoreName, and esoStoreKind plus any tags defined in CustomSessionTags.
Note: the IAM role must have sts:TagSession permission when using Simple or Custom.

=head2 transitiveTagKeys

AWS STS assume role transitive session tags. Required when multiple rules are used with the provider

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
