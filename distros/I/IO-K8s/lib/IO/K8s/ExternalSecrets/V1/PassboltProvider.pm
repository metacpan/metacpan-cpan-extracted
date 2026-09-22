package IO::K8s::ExternalSecrets::V1::PassboltProvider;
# ABSTRACT: PassboltProvider provides access to Passbolt secrets manager.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth       => '+IO::K8s::ExternalSecrets::V1::PassboltAuth', { required => 'schema' };
k8s caBundle   => Str;
k8s caProvider => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s host       => Str, { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::PassboltProvider - PassboltProvider provides access to Passbolt secrets manager.

=head1 VERSION

version 1.108

=head2 auth

Auth defines the information necessary to authenticate against Passbolt Server

=head2 caBundle

PEM encoded CA bundle used to validate Passbolt server certificate. Only used
if the Host URL is using HTTPS protocol. If not set the system root certificates
are used to validate the TLS connection.

=head2 caProvider

The provider for the CA bundle to use to validate Passbolt server certificate.

=head2 host

Host defines the Passbolt Server to connect to

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
