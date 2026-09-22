package IO::K8s::Traefik::V1alpha1::TLSStore;
# ABSTRACT: TLSStore is the CRD implementation of a Traefik TLS Store.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'traefik.io/v1alpha1',
    resource_plural => 'tlsstores';
with 'IO::K8s::Role::Namespaced';

k8s spec => '+IO::K8s::Traefik::V1alpha1::TLSStoreSpec', { required => 'schema' };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Traefik::V1alpha1::TLSStore - TLSStore is the CRD implementation of a Traefik TLS Store.

=head1 VERSION

version 1.108

=head2 spec

TLSStoreSpec defines the desired state of a TLSStore.

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
