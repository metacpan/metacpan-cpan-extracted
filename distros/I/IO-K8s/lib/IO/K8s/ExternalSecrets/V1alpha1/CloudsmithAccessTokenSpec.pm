package IO::K8s::ExternalSecrets::V1alpha1::CloudsmithAccessTokenSpec;
# ABSTRACT: CloudsmithAccessTokenSpec defines the configuration for generating a Cloudsmith access token using OIDC authentication.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiUrl            => Str;
k8s orgSlug           => Str, { required => 'schema' };
k8s serviceAccountRef => '+IO::K8s::ExternalSecrets::V1::ServiceAccountSelector', { required => 'schema' };
k8s serviceSlug       => Str, { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1alpha1::CloudsmithAccessTokenSpec - CloudsmithAccessTokenSpec defines the configuration for generating a Cloudsmith access token using OIDC authentication.

=head1 VERSION

version 1.108

=head2 apiUrl

APIURL configures the Cloudsmith API URL. Defaults to https://api.cloudsmith.io.

=head2 orgSlug

OrgSlug is the organization slug in Cloudsmith

=head2 serviceAccountRef

Name of the service account you are federating with

=head2 serviceSlug

ServiceSlug is the service slug in Cloudsmith for OIDC authentication

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
