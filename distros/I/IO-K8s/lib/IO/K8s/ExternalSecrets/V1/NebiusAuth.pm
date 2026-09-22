package IO::K8s::ExternalSecrets::V1::NebiusAuth;
# ABSTRACT: Auth defines parameters to authenticate in MysteryBox
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s serviceAccountCredsSecretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s tokenSecretRef               => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s workloadIdentity             => '+IO::K8s::ExternalSecrets::V1::NebiusWorkloadIdentity';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::NebiusAuth - Auth defines parameters to authenticate in MysteryBox

=head1 VERSION

version 1.108

=head2 serviceAccountCredsSecretRef

ServiceAccountCreds references a Kubernetes Secret key that contains a JSON
document with service account credentials used to get an IAM token.

Expected JSON structure:
{
  "subject-credentials": {
    "alg": "RS256",
    "private-key": "-----BEGIN PRIVATE KEY-----\n<private-key>\n-----END PRIVATE KEY-----\n",
    "kid": "<public-key-id>",
    "iss": "<issuer-service-account-id>",
    "sub": "<subject-service-account-id>"
  }
}

=head2 tokenSecretRef

Token authenticates with Nebius Mysterybox by presenting a token.

=head2 workloadIdentity

WorkloadIdentity defines configuration for workload identity authentication to Nebius IAM.

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
