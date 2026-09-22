package IO::K8s::ExternalSecrets::V1::VaultKubernetesServiceAccountTokenAuth;
# ABSTRACT: Optional ServiceAccountToken specifies the Kubernetes service account for which to request a token for with the `TokenRequest` API.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s audiences         => [Str];
k8s expirationSeconds => Int;
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector', { required => 'schema' };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::VaultKubernetesServiceAccountTokenAuth - Optional ServiceAccountToken specifies the Kubernetes service account for which to request a token for with the `TokenRequest` API.

=head1 VERSION

version 1.108

=head2 audiences

Optional audiences field that will be used to request a temporary Kubernetes service
account token for the service account referenced by `serviceAccountRef`.
Defaults to a single audience `vault` it not specified.

Deprecated: use serviceAccountRef.Audiences instead

=head2 expirationSeconds

Optional expiration time in seconds that will be used to request a temporary
Kubernetes service account token for the service account referenced by
`serviceAccountRef`.

Deprecated: this will be removed in the future.
Defaults to 10 minutes.

=head2 serviceAccountRef

Service account field containing the name of a kubernetes ServiceAccount.

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
