package IO::K8s::ExternalSecrets::V1::BeyondtrustAuth;
# ABSTRACT: Auth configures how the operator authenticates with Beyondtrust.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiKey         => '+IO::K8s::ExternalSecrets::V1::BeyondTrustProviderSecretRef';
k8s certificate    => '+IO::K8s::ExternalSecrets::V1::BeyondTrustProviderSecretRef';
k8s certificateKey => '+IO::K8s::ExternalSecrets::V1::BeyondTrustProviderSecretRef';
k8s clientId       => '+IO::K8s::ExternalSecrets::V1::BeyondTrustProviderSecretRef';
k8s clientSecret   => '+IO::K8s::ExternalSecrets::V1::BeyondTrustProviderSecretRef';






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::BeyondtrustAuth - Auth configures how the operator authenticates with Beyondtrust.

=head1 VERSION

version 1.108

=head2 apiKey

APIKey If not provided then ClientID/ClientSecret become required.

=head2 certificate

Certificate (cert.pem) for use when authenticating with an OAuth client Id using a Client Certificate.

=head2 certificateKey

Certificate private key (key.pem). For use when authenticating with an OAuth client Id

=head2 clientId

ClientID is the API OAuth Client ID.

=head2 clientSecret

ClientSecret is the API OAuth Client Secret.

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
