package IO::K8s::ExternalSecrets::V1::IBMProvider;
# ABSTRACT: IBM configures this store to sync secrets using IBM Cloud provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth       => '+IO::K8s::ExternalSecrets::V1::IBMAuth', { required => 'schema' };
k8s serviceUrl => Str;



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::IBMProvider - IBM configures this store to sync secrets using IBM Cloud provider

=head1 VERSION

version 1.108

=head2 auth

Auth configures how secret-manager authenticates with the IBM secrets manager.

=head2 serviceUrl

ServiceURL is the Endpoint URL that is specific to the Secrets Manager service instance

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
