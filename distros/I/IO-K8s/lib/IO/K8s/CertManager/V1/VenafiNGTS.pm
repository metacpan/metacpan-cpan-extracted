package IO::K8s::CertManager::V1::VenafiNGTS;
# ABSTRACT: NGTS specifies Palo Alto Networks Next Generation Trust Services (NGTS) configuration using OAuth 2.0 Client Credentials.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s credentialsRef => '+IO::K8s::CertManager::V1::CertManagerLocalObjectReference', { required => 'schema' };
k8s tokenEndpoint  => Str;
k8s tsgID          => Str, { required => 'schema' };
k8s url            => Str;





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::VenafiNGTS - NGTS specifies Palo Alto Networks Next Generation Trust Services (NGTS) configuration using OAuth 2.0 Client Credentials.

=head1 VERSION

version 1.108

=head2 credentialsRef

CredentialsRef is a reference to a Kubernetes Secret containing the OAuth 2.0
Client ID and Client Secret. The secret must contain the keys 'client-id' and
'client-secret'.

=head2 tokenEndpoint

TokenEndpoint is the OAuth 2.0 token endpoint URL used to obtain access tokens,
for example "https://auth.apps.paloaltonetworks.com/oauth2/access_token".
Defaults to "https://auth.apps.paloaltonetworks.com/oauth2/access_token" if not set.

=head2 tsgID

TSGID is the Tenant Service Group ID used to scope the OAuth 2.0 access token,
for example "1234567890". The tsg_id: prefix is added automatically.
This field is required.

=head2 url

URL is the base URL for the NGTS API endpoint.
Defaults to "https://api.strata.paloaltonetworks.com/ngts" if not set.

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
