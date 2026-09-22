package IO::K8s::ExternalSecrets::V1::ExternalSecretDataFromRemoteRef;
# ABSTRACT: ExternalSecretDataFromRemoteRef defines the connection between the Kubernetes Secret keys and the Provider data when using DataFrom to fetch multiple values from a Provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s extract   => '+IO::K8s::ExternalSecrets::V1::ExternalSecretDataRemoteRef';
k8s find      => '+IO::K8s::ExternalSecrets::V1::ExternalSecretFind';
k8s rewrite   => ['+IO::K8s::ExternalSecrets::V1::ExternalSecretRewrite'];
k8s sourceRef => '+IO::K8s::ExternalSecrets::V1::StoreGeneratorSourceRef';





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ExternalSecretDataFromRemoteRef - ExternalSecretDataFromRemoteRef defines the connection between the Kubernetes Secret keys and the Provider data when using DataFrom to fetch multiple values from a Provider.

=head1 VERSION

version 1.108

=head2 extract

Used to extract multiple key/value pairs from one secret
Note: Extract does not support sourceRef.Generator or sourceRef.GeneratorRef.

=head2 find

Used to find secrets based on tags or regular expressions
Note: Find does not support sourceRef.Generator or sourceRef.GeneratorRef.

=head2 rewrite

Used to rewrite secret Keys after getting them from the secret Provider
Multiple Rewrite operations can be provided. They are applied in a layered order (first to last)

=head2 sourceRef

SourceRef points to a store or generator
which contains secret values ready to use.
Use this in combination with Extract or Find pull values out of
a specific SecretStore.
When sourceRef points to a generator Extract or Find is not supported.
The generator returns a static map of values

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
