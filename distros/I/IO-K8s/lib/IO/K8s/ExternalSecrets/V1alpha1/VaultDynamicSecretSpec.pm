package IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecretSpec;
# ABSTRACT: VaultDynamicSecretSpec defines the desired spec of VaultDynamicSecret.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s allowEmptyResponse => Bool, { default => 0 };
k8s controller         => Str;
k8s getParameters      => { Str => 1 };
k8s method             => Str;
k8s parameters         => Str, { preserve_unknown => 1 };
k8s path               => Str, { required => 'schema' };
k8s provider           => '+IO::K8s::ExternalSecrets::V1::VaultProvider', { required => 'schema' };
k8s resultType         => Str, { enum => [qw(Data Auth Raw)], default => 'Data' };
k8s retrySettings      => '+IO::K8s::ExternalSecrets::V1::SecretStoreRetrySettings';










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::VaultDynamicSecretSpec - VaultDynamicSecretSpec defines the desired spec of VaultDynamicSecret.

=head1 VERSION

version 1.108

=head2 allowEmptyResponse

Do not fail if no secrets are found. Useful for requests where no data is expected.

=head2 controller

Used to select the correct ESO controller (think: ingress.ingressClassName)
The ESO controller is instantiated with a specific controller name and filters VDS based on this property

=head2 getParameters

GetParameters are query-string parameters passed to Vault on GET calls.
Each key may map to multiple values, matching HTTP query-string semantics.
Ignored for non-GET methods; use Parameters for write bodies.

=head2 method

Vault API method to use (GET/POST/other)

=head2 parameters

Parameters to pass to Vault write (for non-GET methods)

=head2 path

Vault path to obtain the dynamic secret from

=head2 provider

Vault provider common spec

=head2 resultType

Result type defines which data is returned from the generator.
By default, it is the "data" section of the Vault API response.
When using e.g. /auth/token/create the "data" section is empty but
the "auth" section contains the generated token.
Please refer to the vault docs regarding the result data structure.
Additionally, accessing the raw response is possibly by using "Raw" result type.

=head2 retrySettings

Used to configure http retries if failed

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
