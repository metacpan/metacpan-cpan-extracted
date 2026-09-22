package IO::K8s::ExternalSecrets::V1::ClusterSecretStoreCondition;
# ABSTRACT: ClusterSecretStoreCondition describes a condition by which to choose namespaces to process ExternalSecrets in for a ClusterSecretStore instance.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s namespaceRegexes  => [Str];
k8s namespaceSelector => 'Meta::V1::LabelSelector';
k8s namespaces        => [Str], { pattern => qr/^[a-z0-9]([-a-z0-9]*[a-z0-9])?$/ };




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ClusterSecretStoreCondition - ClusterSecretStoreCondition describes a condition by which to choose namespaces to process ExternalSecrets in for a ClusterSecretStore instance.

=head1 VERSION

version 1.108

=head2 namespaceRegexes

Choose namespaces by using regex matching

=head2 namespaceSelector

Choose namespace using a labelSelector

=head2 namespaces

Choose namespaces by name

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
