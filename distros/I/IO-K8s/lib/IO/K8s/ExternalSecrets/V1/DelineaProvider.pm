package IO::K8s::ExternalSecrets::V1::DelineaProvider;
# ABSTRACT: Delinea DevOps Secrets Vault https://docs.delinea.com/online-help/products/devops-secrets-vault/current
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s clientId     => '+IO::K8s::ExternalSecrets::V1::DelineaProviderSecretRef', { required => 'schema' };
k8s clientSecret => '+IO::K8s::ExternalSecrets::V1::DelineaProviderSecretRef', { required => 'schema' };
k8s tenant       => Str, { required => 'schema' };
k8s tld          => Str;
k8s urlTemplate  => Str;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::DelineaProvider - Delinea DevOps Secrets Vault https://docs.delinea.com/online-help/products/devops-secrets-vault/current

=head1 VERSION

version 1.108

=head2 clientId

ClientID is the non-secret part of the credential.

=head2 clientSecret

ClientSecret is the secret part of the credential.

=head2 tenant

Tenant is the chosen hostname / site name.

=head2 tld

TLD is based on the server location that was chosen during provisioning.
If unset, defaults to "com".

=head2 urlTemplate

URLTemplate
If unset, defaults to "https://%s.secretsvaultcloud.%s/v1/%s%s".

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
