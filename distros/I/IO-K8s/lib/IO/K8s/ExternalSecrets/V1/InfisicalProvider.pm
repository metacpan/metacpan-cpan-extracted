package IO::K8s::ExternalSecrets::V1::InfisicalProvider;
# ABSTRACT: Infisical configures this store to sync secrets using the Infisical provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth         => '+IO::K8s::ExternalSecrets::V1::InfisicalAuth', { required => 'schema' };
k8s caBundle     => Str;
k8s caProvider   => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s hostAPI      => Str, { default => 'https://app.infisical.com/api' };
k8s secretsScope => '+IO::K8s::ExternalSecrets::V1::MachineIdentityScopeInWorkspace', { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::InfisicalProvider - Infisical configures this store to sync secrets using the Infisical provider

=head1 VERSION

version 1.108

=head2 auth

Auth configures how the Operator authenticates with the Infisical API

=head2 caBundle

CABundle is a PEM-encoded CA certificate bundle used to validate
the Infisical server's TLS certificate. Mutually exclusive with CAProvider.

=head2 caProvider

CAProvider is a reference to a Secret or ConfigMap that contains a CA certificate.
The certificate is used to validate the Infisical server's TLS certificate.
Mutually exclusive with CABundle.

=head2 hostAPI

HostAPI specifies the base URL of the Infisical API. If not provided, it defaults to "https://app.infisical.com/api".

=head2 secretsScope

SecretsScope defines the scope of the secrets within the workspace

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
