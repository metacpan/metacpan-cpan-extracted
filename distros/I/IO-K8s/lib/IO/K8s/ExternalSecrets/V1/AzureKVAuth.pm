package IO::K8s::ExternalSecrets::V1::AzureKVAuth;
# ABSTRACT: Auth configures how the operator authenticates with Azure.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientCertificate => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s clientId          => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s clientSecret      => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s tenantId          => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AzureKVAuth - Auth configures how the operator authenticates with Azure.

=head1 VERSION

version 1.108

=head2 clientCertificate

The Azure ClientCertificate of the service principle used for authentication.

=head2 clientId

The Azure clientId of the service principle or managed identity used for authentication.

=head2 clientSecret

The Azure ClientSecret of the service principle used for authentication.

=head2 tenantId

The Azure tenantId of the managed identity used for authentication.

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
