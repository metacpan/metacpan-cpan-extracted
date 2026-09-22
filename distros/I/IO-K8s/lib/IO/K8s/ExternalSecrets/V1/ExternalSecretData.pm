package IO::K8s::ExternalSecrets::V1::ExternalSecretData;
# ABSTRACT: ExternalSecretData defines the connection between the Kubernetes Secret key (spec.data.<key>) and the Provider data.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s remoteRef => '+IO::K8s::ExternalSecrets::V1::ExternalSecretDataRemoteRef', { required => 'schema' };
k8s secretKey => Str, { required => 'schema', pattern => qr/^[-._a-zA-Z0-9]+$/ };
k8s sourceRef => '+IO::K8s::ExternalSecrets::V1::StoreSourceRef';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretData - ExternalSecretData defines the connection between the Kubernetes Secret key (spec.data.<key>) and the Provider data.

=head1 VERSION

version 1.108

=head2 remoteRef

RemoteRef points to the remote secret and defines
which secret (version/property/..) to fetch.

=head2 secretKey

The key in the Kubernetes Secret to store the value.

=head2 sourceRef

SourceRef allows you to override the source
from which the value will be pulled.

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
