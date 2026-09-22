package IO::K8s::ExternalSecrets::V1::StoreGeneratorSourceRef;
# ABSTRACT: SourceRef points to a store or generator which contains secret values ready to use.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s generatorRef => 'Autoscaling::V1::CrossVersionObjectReference';
k8s storeRef     => '+IO::K8s::ExternalSecrets::V1::SecretStoreRef';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::StoreGeneratorSourceRef - SourceRef points to a store or generator which contains secret values ready to use.

=head1 VERSION

version 1.108

=head2 generatorRef

GeneratorRef points to a generator custom resource.

=head2 storeRef

SecretStoreRef defines which SecretStore to fetch the ExternalSecret data.

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
