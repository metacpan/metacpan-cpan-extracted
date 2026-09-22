package IO::K8s::ExternalSecrets::V1::NebiusMysteryboxProvider;
# ABSTRACT: NebiusMysterybox configures this store to sync secrets using NebiusMysterybox provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s apiDomain  => Str, { required => 'schema' };
k8s auth       => '+IO::K8s::ExternalSecrets::V1::NebiusAuth', { required => 'schema' };
k8s caProvider => '+IO::K8s::ExternalSecrets::V1::NebiusCAProvider';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::NebiusMysteryboxProvider - NebiusMysterybox configures this store to sync secrets using NebiusMysterybox provider

=head1 VERSION

version 1.108

=head2 apiDomain

NebiusMysterybox API endpoint

=head2 auth

Auth defines parameters to authenticate in MysteryBox

=head2 caProvider

The provider for the CA bundle to use to validate NebiusMysterybox server certificate.

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
