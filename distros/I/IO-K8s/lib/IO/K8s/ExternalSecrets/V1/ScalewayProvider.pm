package IO::K8s::ExternalSecrets::V1::ScalewayProvider;
# ABSTRACT: Scaleway configures this store to sync secrets using the Scaleway provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s accessKey => '+IO::K8s::ExternalSecrets::V1::ScalewayProviderSecretRef', { required => 'schema' };
k8s apiUrl    => Str;
k8s projectId => Str, { required => 'schema' };
k8s region    => Str, { required => 'schema' };
k8s secretKey => '+IO::K8s::ExternalSecrets::V1::ScalewayProviderSecretRef', { required => 'schema' };






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ScalewayProvider - Scaleway configures this store to sync secrets using the Scaleway provider.

=head1 VERSION

version 1.108

=head2 accessKey

AccessKey is the non-secret part of the api key.

=head2 apiUrl

APIURL is the url of the api to use. Defaults to https://api.scaleway.com

=head2 projectId

ProjectID is the id of your project, which you can find in the console: https://console.scaleway.com/project/settings

=head2 region

Region where your secrets are located: https://developers.scaleway.com/en/quickstart/#region-and-zone

=head2 secretKey

SecretKey is the non-secret part of the api key.

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
