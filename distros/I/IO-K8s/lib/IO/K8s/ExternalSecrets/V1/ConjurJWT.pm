package IO::K8s::ExternalSecrets::V1::ConjurJWT;
# ABSTRACT: Jwt enables JWT authentication using Kubernetes service account tokens.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s account           => Str, { required => 'schema' };
k8s hostId            => Str;
k8s secretRef         => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';
k8s serviceID         => Str, { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ConjurJWT - Jwt enables JWT authentication using Kubernetes service account tokens.

=head1 VERSION

version 1.108

=head2 account

Account is the Conjur organization account name.

=head2 hostId

Optional HostID for JWT authentication. This may be used depending
on how the Conjur JWT authenticator policy is configured.

=head2 secretRef

Optional SecretRef that refers to a key in a Secret resource containing JWT token to
authenticate with Conjur using the JWT authentication method.

=head2 serviceAccountRef

Optional ServiceAccountRef specifies the Kubernetes service account for which to request
a token for with the `TokenRequest` API.

=head2 serviceID

The conjur authn jwt webservice id

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
