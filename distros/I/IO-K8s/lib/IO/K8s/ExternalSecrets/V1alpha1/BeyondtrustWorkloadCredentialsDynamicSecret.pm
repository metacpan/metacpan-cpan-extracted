package IO::K8s::ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecret;
# ABSTRACT: BeyondtrustWorkloadCredentialsDynamicSecret represents a generator that requests dynamic credentials from BeyondTrust Workload Credentials.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'generators.external-secrets.io/v1alpha1',
    resource_plural => 'beyondtrustworkloadcredentialsdynamicsecrets';
with 'IO::K8s::Role::Namespaced';

k8s spec => '+IO::K8s::ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecretSpec';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::BeyondtrustWorkloadCredentialsDynamicSecret - BeyondtrustWorkloadCredentialsDynamicSecret represents a generator that requests dynamic credentials from BeyondTrust Workload Credentials.

=head1 VERSION

version 1.108

=head2 spec

BeyondtrustWorkloadCredentialsDynamicSecretSpec defines the desired spec for BeyondtrustWorkloadCredentials dynamic generator.
This generator enables obtaining temporary, short-lived credentials from BeyondTrust Workload Credentials.
For more information, see: https://docs.beyondtrust.com/bt-docs/docs/secrets-api

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
