package IO::K8s::ExternalSecrets::V1::SecretServerProvider;
# ABSTRACT: SecretServer configures this store to sync secrets using SecretServer provider https://docs.delinea.com/online-help/secret-server/start.htm
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s caBundle                => Str;
k8s caProvider              => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s disableSiteIDValidation => Bool;
k8s domain                  => Str;
k8s password                => '+IO::K8s::ExternalSecrets::V1::SecretServerProviderRef';
k8s serverURL               => Str, { required => 'schema' };
k8s siteId                  => Int, { minimum => 1 };
k8s token                   => '+IO::K8s::ExternalSecrets::V1::SecretServerProviderRef';
k8s username                => '+IO::K8s::ExternalSecrets::V1::SecretServerProviderRef';










1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::SecretServerProvider - SecretServer configures this store to sync secrets using SecretServer provider https://docs.delinea.com/online-help/secret-server/start.htm

=head1 VERSION

version 1.108

=head2 caBundle

PEM/base64 encoded CA bundle used to validate Secret ServerURL. Only used
if the ServerURL URL is using HTTPS protocol. If not set the system root certificates
are used to validate the TLS connection.

=head2 caProvider

The provider for the CA bundle to use to validate Secret ServerURL certificate.

=head2 disableSiteIDValidation

DisableSiteIDValidation permits a missing site ID for new secrets.
The provider sends 0 if no site ID is set.

=head2 domain

Domain is the secret server domain.

=head2 password

Password is the secret server account password.
Required unless Token is set.

=head2 serverURL

ServerURL
URL to your secret server installation

=head2 siteId

SiteID is the ID of the Secret Server site for new secrets.
PushSecret metadata can override this value for one secret.
The provider uses 1 if this field is not set.

=head2 token

Token is an access token used to authenticate to the secret server,
as an alternative to Username and Password. When set, Username and
Password are not required and are ignored.

=head2 username

Username is the secret server account username.
Required unless Token is set.

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
