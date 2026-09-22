package IO::K8s::ExternalSecrets::V1::ConjurProvider;
# ABSTRACT: Conjur configures this store to sync secrets using conjur provider
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s auth       => '+IO::K8s::ExternalSecrets::V1::ConjurAuth', { required => 'schema' };
k8s caBundle   => Str;
k8s caProvider => '+IO::K8s::ExternalSecrets::V1::CAProvider';
k8s url        => Str, { required => 'schema' };





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::ExternalSecrets::V1::ConjurProvider - Conjur configures this store to sync secrets using conjur provider

=head1 VERSION

version 1.108

=head2 auth

Defines authentication settings for connecting to Conjur.

=head2 caBundle

CABundle is a PEM encoded CA bundle that will be used to validate the Conjur server certificate.

=head2 caProvider

Used to provide custom certificate authority (CA) certificates
for a secret store. The CAProvider points to a Secret or ConfigMap resource
that contains a PEM-encoded certificate.

=head2 url

URL is the endpoint of the Conjur instance.

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
