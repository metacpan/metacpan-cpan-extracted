package IO::K8s::ExternalSecrets::V1::AkeylessProvider;
# ABSTRACT: Akeyless configures this store to sync secrets using Akeyless Vault provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s akeylessGWApiURL => Str, { required => 'schema' };
k8s authSecretRef    => '+IO::K8s::ExternalSecrets::V1::AkeylessAuth', { required => 'schema' };
k8s caBundle         => Str;
k8s caProvider       => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s ignoreCache      => Bool;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::AkeylessProvider - Akeyless configures this store to sync secrets using Akeyless Vault provider

=head1 VERSION

version 1.108

=head2 akeylessGWApiURL

Akeyless GW API Url from which the secrets to be fetched from.

=head2 authSecretRef

Auth configures how the operator authenticates with Akeyless.

=head2 caBundle

PEM/base64 encoded CA bundle used to validate Akeyless Gateway certificate. Only used
if the AkeylessGWApiURL URL is using HTTPS protocol. If not set the system root certificates
are used to validate the TLS connection.

=head2 caProvider

The provider for the CA bundle to use to validate Akeyless Gateway certificate.

=head2 ignoreCache

IgnoreCache bypasses the Gateway cache for secret reads when true.
Only relevant when akeylessGWApiURL points to an Akeyless Gateway.

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
