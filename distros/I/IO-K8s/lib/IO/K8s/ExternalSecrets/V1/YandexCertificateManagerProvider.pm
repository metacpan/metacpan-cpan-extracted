package IO::K8s::ExternalSecrets::V1::YandexCertificateManagerProvider;
# ABSTRACT: YandexCertificateManager configures this store to sync secrets using Yandex Certificate Manager provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiEndpoint => Str;
k8s auth        => '+IO::K8s::ExternalSecrets::V1::YandexAuth', { required => 'schema' };
k8s caProvider  => '+IO::K8s::ExternalSecrets::V1::YandexCAProvider';
k8s fetching    => '+IO::K8s::ExternalSecrets::V1::FetchingPolicy';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::YandexCertificateManagerProvider - YandexCertificateManager configures this store to sync secrets using Yandex Certificate Manager provider

=head1 VERSION

version 1.108

=head2 apiEndpoint

Yandex.Cloud API endpoint (e.g. 'api.cloud.yandex.net:443')

=head2 auth

Auth defines the information necessary to authenticate against Yandex.Cloud

=head2 caProvider

The provider for the CA bundle to use to validate Yandex.Cloud server certificate.

=head2 fetching

FetchingPolicy configures the provider to interpret the `data.secretKey.remoteRef.key` field in ExternalSecret as certificate ID or certificate name

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
