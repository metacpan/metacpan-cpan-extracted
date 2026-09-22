package IO::K8s::ExternalSecrets::V1::SecretStore;
# ABSTRACT: SecretStore represents a secure external location for storing secrets, which can be referenced as part of `storeRef` fields.
our $VERSION = '1.108';
use IO::K8s::APIObject
    api_version     => 'external-secrets.io/v1',
    resource_plural => 'secretstores';
with 'IO::K8s::Role::Namespaced';

k8s spec   => '+IO::K8s::ExternalSecrets::V1::SecretStoreSpec';
k8s status => '+IO::K8s::ExternalSecrets::V1::SecretStoreStatus';



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::SecretStore - SecretStore represents a secure external location for storing secrets, which can be referenced as part of `storeRef` fields.

=head1 VERSION

version 1.108

=head2 spec

SecretStoreSpec defines the desired state of SecretStore.

=head2 status

SecretStoreStatus defines the observed state of the SecretStore.

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
