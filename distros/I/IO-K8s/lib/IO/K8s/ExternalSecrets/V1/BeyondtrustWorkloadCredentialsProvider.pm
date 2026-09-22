package IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider;
# ABSTRACT: BeyondtrustWorkloadCredentials configures this store to sync secrets using the BeyondTrust Workload Credentials provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth       => '+IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsAuth', { required => 'schema' };
k8s caBundle   => Str;
k8s caProvider => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s folderPath => Str;
k8s server     => '+IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsServer', { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider - BeyondtrustWorkloadCredentials configures this store to sync secrets using the BeyondTrust Workload Credentials provider.

=head1 VERSION

version 1.108

=head2 auth

Auth configures how the Operator authenticates with the BeyondTrust Workload Credentials API.
Currently supports API key authentication via Kubernetes secret reference.
For authentication setup, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api#authentication

=head2 caBundle

CABundle is a base64-encoded CA certificate used to validate the BeyondTrust Workload Credentials API TLS certificate.
Use this when your BeyondTrust instance uses a self-signed certificate or internal CA.
If not set, the system's trusted root certificates are used.

=head2 caProvider

CAProvider points to a Secret or ConfigMap containing a PEM-encoded CA certificate.
This is used to validate the BeyondTrust Workload Credentials API TLS certificate.
Use this as an alternative to CABundle when you want to reference an existing Kubernetes resource.

=head2 folderPath

FolderPath specifies the default folder path for secret retrieval.
Secrets will be fetched from this folder unless overridden in the ExternalSecret spec.
Example: "production/database" or "dev/api-keys"
Leave empty to retrieve secrets from the root folder.
For folder organization, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api#folders

=head2 server

Server configures the BeyondTrust Workload Credentials server connection details.
Includes the API URL and Site ID for your BeyondTrust instance.
For API reference, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api

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
