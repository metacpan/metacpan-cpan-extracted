package IO::K8s::ExternalSecrets::V1::VaultCertAuth;
# ABSTRACT: Cert authenticates with TLS Certificates by passing client certificate, private key and ca certificate Cert authentication method
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientCert => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s path       => Str, { default => 'cert' };
k8s secretRef  => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector';
k8s vaultRole  => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::VaultCertAuth - Cert authenticates with TLS Certificates by passing client certificate, private key and ca certificate Cert authentication method

=head1 VERSION

version 1.108

=head2 clientCert

ClientCert is a certificate to authenticate using the Cert Vault
authentication method

=head2 path

Path where the Certificate authentication backend is mounted
in Vault, e.g: "cert"

=head2 secretRef

SecretRef to a key in a Secret resource containing client private key to
authenticate with Vault using the Cert authentication method

=head2 vaultRole

VaultRole specifies the Vault role to use for TLS certificate authentication.

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
