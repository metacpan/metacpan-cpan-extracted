package IO::K8s::ExternalSecrets::V1::OvhClientMTLS;
# ABSTRACT: OvhClientMTLS defines the configuration required to authenticate to OVHcloud's Secret Manager using mTLS.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s caBundle      => Str;
k8s caProvider    => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s certSecretRef => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector', { required => 'schema' };
k8s keySecretRef  => '+IO::K8s::ExternalSecrets::V1::SecretKeySelector', { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::OvhClientMTLS - OvhClientMTLS defines the configuration required to authenticate to OVHcloud's Secret Manager using mTLS.

=head1 VERSION

version 1.108

=head2 caBundle

No description in the upstream schema.

=head2 caProvider

CAProvider provides a custom certificate authority for accessing the provider's store.
The CAProvider points to a Secret or ConfigMap resource that contains a PEM-encoded certificate.

=head2 certSecretRef

SecretKeySelector is a reference to a specific 'key' within a Secret resource.
In some instances, `key` is a required field.

=head2 keySecretRef

SecretKeySelector is a reference to a specific 'key' within a Secret resource.
In some instances, `key` is a required field.

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
