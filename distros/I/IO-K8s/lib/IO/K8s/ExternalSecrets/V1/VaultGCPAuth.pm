package IO::K8s::ExternalSecrets::V1::VaultGCPAuth;
# ABSTRACT: Gcp authenticates with Vault using Google Cloud Platform authentication method GCP authentication method
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s location          => Str;
k8s path              => Str, { default => 'gcp' };
k8s projectID         => Str;
k8s role              => Str, { required => 'schema' };
k8s secretRef         => '+IO::K8s::ExternalSecrets::V1::GCPSMAuthSecretRef';
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';
k8s workloadIdentity  => '+IO::K8s::ExternalSecrets::V1::GCPWorkloadIdentity';








1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::VaultGCPAuth - Gcp authenticates with Vault using Google Cloud Platform authentication method GCP authentication method

=head1 VERSION

version 1.108

=head2 location

Location optionally defines a location/region for the secret

=head2 path

Path where the GCP auth method is enabled in Vault, e.g: "gcp"

=head2 projectID

Project ID of the Google Cloud Platform project

=head2 role

Vault Role. In Vault, a role describes an identity with a set of permissions, groups, or policies you want to attach to a user of the secrets engine.

=head2 secretRef

Specify credentials in a Secret object

=head2 serviceAccountRef

ServiceAccountRef to a service account for impersonation

=head2 workloadIdentity

Specify a service account with Workload Identity

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
