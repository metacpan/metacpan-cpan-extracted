package IO::K8s::ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecretSpec;
# ABSTRACT: BeyondtrustWorkloadCredentialsDynamicSecretSpec defines the desired spec for BeyondtrustWorkloadCredentials dynamic generator.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s controller    => Str;
k8s provider      => '+IO::K8s::ExternalSecrets::V1::BeyondtrustWorkloadCredentialsProvider', { required => 'schema' };
k8s retrySettings => '+IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecretSpec - BeyondtrustWorkloadCredentialsDynamicSecretSpec defines the desired spec for BeyondtrustWorkloadCredentials dynamic generator.

=head1 VERSION

version 1.108

=head2 controller

Controller selects the controller that should handle this generator.
Leave empty to use the default controller.

=head2 provider

Provider contains the BeyondtrustWorkloadCredentials provider configuration including authentication,
server connection details, and the folder path to the dynamic secret definition.
The folderPath should point to a dynamic secret definition that has been created in
BeyondTrust Workload Credentials (e.g., "production/aws-temp").
For setup details, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api

=head2 retrySettings

RetrySettings configures exponential backoff for failed API requests.
If not specified, uses the default retry settings.

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
