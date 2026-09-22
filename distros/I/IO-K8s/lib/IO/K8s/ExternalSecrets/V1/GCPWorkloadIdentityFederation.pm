package IO::K8s::ExternalSecrets::V1::GCPWorkloadIdentityFederation;
# ABSTRACT: GCPWorkloadIdentityFederation holds the configurations required for generating federated access tokens.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s audience               => Str;
k8s awsSecurityCredentials => '+IO::K8s::ExternalSecrets::V1::AwsCredentialsConfig';
k8s credConfig             => '+IO::K8s::ExternalSecrets::V1::ConfigMapReference';
k8s externalTokenEndpoint  => Str;
k8s gcpServiceAccountEmail => Str, { pattern => '^.*@.*\\.iam\\.gserviceaccount\\.com$' };
k8s serviceAccountRef      => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';







1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::GCPWorkloadIdentityFederation - GCPWorkloadIdentityFederation holds the configurations required for generating federated access tokens.

=head1 VERSION

version 1.108

=head2 audience

audience is the Secure Token Service (STS) audience which contains the resource name for the workload identity pool and the provider identifier in that pool.
If specified, Audience found in the external account credential config will be overridden with the configured value.
audience must be provided when serviceAccountRef or awsSecurityCredentials is configured.

=head2 awsSecurityCredentials

awsSecurityCredentials is for configuring AWS region and credentials to use for obtaining the access token,
when using the AWS metadata server is not an option.

=head2 credConfig

credConfig holds the configmap reference containing the GCP external account credential configuration in JSON format and the key name containing the json data.
For using Kubernetes cluster as the identity provider, use serviceAccountRef instead. Operators mounted serviceaccount token cannot be used as the token source, instead
serviceAccountRef must be used by providing operators service account details.

=head2 externalTokenEndpoint

externalTokenEndpoint is the endpoint explicitly set up to provide tokens, which will be matched against the
credential_source.url in the provided credConfig. This field is merely to double-check the external token source
URL is having the expected value.

=head2 gcpServiceAccountEmail

GCPServiceAccountEmail is the email of the Google Cloud service account to impersonate
after Workload Identity Federation. Use this to grant access through the service account's
IAM bindings (for example roles/secretmanager.secretAccessor). When set, it overrides
service_account_impersonation_url in the external account JSON from credConfig;
when serviceAccountRef is set, it also overrides the "iam.gke.io/gcp-service-account" annotation
on that ServiceAccount.

=head2 serviceAccountRef

serviceAccountRef is the reference to the kubernetes ServiceAccount to be used for obtaining the tokens,
when Kubernetes is configured as provider in workload identity pool.

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
