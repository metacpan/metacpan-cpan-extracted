package IO::K8s::ExternalSecrets::V1::KubernetesAuth;
# ABSTRACT: Auth configures how secret-manager authenticates with a Kubernetes instance.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s cert           => '+IO::K8s::ExternalSecrets::V1::CertAuth';
k8s serviceAccount => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector';
k8s token          => '+IO::K8s::ExternalSecrets::V1::TokenAuth';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::KubernetesAuth - Auth configures how secret-manager authenticates with a Kubernetes instance.

=head1 VERSION

version 1.108

=head2 cert

has both clientCert and clientKey as secretKeySelector

=head2 serviceAccount

points to a service account that should be used for authentication

=head2 token

use static token to authenticate with

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
