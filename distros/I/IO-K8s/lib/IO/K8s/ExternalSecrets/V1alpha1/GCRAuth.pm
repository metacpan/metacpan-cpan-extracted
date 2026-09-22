package IO::K8s::ExternalSecrets::V1alpha1::GCRAuth;
# ABSTRACT: Auth defines the means for authenticating with GCP
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s secretRef                  => '+IO::K8s::ExternalSecrets::V1::GCPSMAuthSecretRef';
k8s workloadIdentity           => '+IO::K8s::ExternalSecrets::V1alpha1::GCRWorkloadIdentity';
k8s workloadIdentityFederation => '+IO::K8s::ExternalSecrets::V1::GCPWorkloadIdentityFederation';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::GCRAuth - Auth defines the means for authenticating with GCP

=head1 VERSION

version 1.108

=head2 secretRef

GCPSMAuthSecretRef defines the reference to a secret containing Google Cloud Platform credentials.

=head2 workloadIdentity

GCPWorkloadIdentity defines the configuration for using GCP Workload Identity authentication.

=head2 workloadIdentityFederation

GCPWorkloadIdentityFederation holds the configurations required for generating federated access tokens.

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
