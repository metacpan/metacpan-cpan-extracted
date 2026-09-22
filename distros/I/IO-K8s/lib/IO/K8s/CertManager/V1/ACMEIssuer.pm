package IO::K8s::CertManager::V1::ACMEIssuer;
# ABSTRACT: ACME configures this issuer to communicate with a RFC8555 (ACME) server to obtain signed x509 certificates.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s caBundle                    => Str;
k8s disableAccountKeyGeneration => Bool;
k8s email                       => Str;
k8s enableDurationFeature       => Bool;
k8s externalAccountBinding      => '+IO::K8s::CertManager::V1::ACMEExternalAccountBinding';
k8s preferredChain              => Str;
k8s privateKeySecretRef         => '+IO::K8s::CertManager::V1::SecretKeySelector', { required => 'schema' };
k8s profile                     => Str;
k8s server                      => Str, { required => 'schema' };
k8s skipTLSVerify               => Bool;
k8s solvers                     => ['+IO::K8s::CertManager::V1::ACMEChallengeSolver'];












1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuer - ACME configures this issuer to communicate with a RFC8555 (ACME) server to obtain signed x509 certificates.

=head1 VERSION

version 1.108

=head2 caBundle

Base64-encoded bundle of PEM CAs which can be used to validate the certificate
chain presented by the ACME server.
Mutually exclusive with SkipTLSVerify; prefer using CABundle to prevent various
kinds of security vulnerabilities.
If CABundle and SkipTLSVerify are unset, the system certificate bundle inside
the container is used to validate the TLS connection.

=head2 disableAccountKeyGeneration

Enables or disables generating a new ACME account key.
If true, the Issuer resource will *not* request a new account but will expect
the account key to be supplied via an existing secret.
If false, the cert-manager system will generate a new ACME account key
for the Issuer.
Defaults to false.

=head2 email

Email is the email address to be associated with the ACME account.
This field is optional, but it is strongly recommended to be set.
It will be used to contact you in case of issues with your account or
certificates, including expiry notification emails.
This field may be updated after the account is initially registered.

=head2 enableDurationFeature

Enables requesting a Not After date on certificates that matches the
duration of the certificate. This is not supported by all ACME servers
like Let's Encrypt. If set to true when the ACME server does not support
it, it will create an error on the Order.
Defaults to false.

=head2 externalAccountBinding

ExternalAccountBinding is a reference to a CA external account of the ACME
server.
If set, upon registration cert-manager will attempt to associate the given
external account credentials with the registered ACME account.

=head2 preferredChain

PreferredChain is the chain to use if the ACME server outputs multiple.
PreferredChain is no guarantee that this one gets delivered by the ACME
endpoint.
For example, for Let's Encrypt's DST cross-sign you would use:
"DST Root CA X3" or "ISRG Root X1" for the newer Let's Encrypt root CA.
This value picks the first certificate bundle in the combined set of
ACME default and alternative chains that has a root-most certificate with
this value as its issuer's commonname.

=head2 privateKeySecretRef

PrivateKey is the name of a Kubernetes Secret resource that will be used to
store the automatically generated ACME account private key.
Optionally, a `key` may be specified to select a specific entry within
the named Secret resource.
If `key` is not specified, a default of `tls.key` will be used.

=head2 profile

Profile allows requesting a certificate profile from the ACME server.
Supported profiles are listed by the server's ACME directory URL.

=head2 server

Server is the URL used to access the ACME server's 'directory' endpoint.
For example, for Let's Encrypt's staging endpoint, you would use:
"https://acme-staging-v02.api.letsencrypt.org/directory".
Only ACME v2 endpoints (i.e. RFC 8555) are supported.

=head2 skipTLSVerify

INSECURE: Enables or disables validation of the ACME server TLS certificate.
If true, requests to the ACME server will not have the TLS certificate chain
validated.
Mutually exclusive with CABundle; prefer using CABundle to prevent various
kinds of security vulnerabilities.
Only enable this option in development environments.
If CABundle and SkipTLSVerify are unset, the system certificate bundle inside
the container is used to validate the TLS connection.
Defaults to false.

=head2 solvers

Solvers is a list of challenge solvers that will be used to solve
ACME challenges for the matching domains.
Solver configurations must be provided in order to obtain certificates
from an ACME server.
For more information, see: https://cert-manager.io/docs/configuration/acme/

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
