package IO::K8s::ExternalSecrets::V1::BeyondtrustProvider;
# ABSTRACT: Beyondtrust configures this store to sync secrets using Password Safe provider.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth   => '+IO::K8s::ExternalSecrets::V1::BeyondtrustAuth', { required => 'schema' };
k8s server => '+IO::K8s::ExternalSecrets::V1::BeyondtrustServer', { required => 'schema' };



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::BeyondtrustProvider - Beyondtrust configures this store to sync secrets using Password Safe provider.

=head1 VERSION

version 1.108

=head2 auth

Auth configures how the operator authenticates with Beyondtrust.

=head2 server

Auth configures how API server works.

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
