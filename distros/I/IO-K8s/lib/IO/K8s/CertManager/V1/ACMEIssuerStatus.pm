package IO::K8s::CertManager::V1::ACMEIssuerStatus;
# ABSTRACT: ACME specific status options.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s lastPrivateKeyHash  => Str;
k8s lastRegisteredEmail => Str;
k8s uri                 => Str;




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEIssuerStatus - ACME specific status options.

=head1 VERSION

version 1.108

=head2 lastPrivateKeyHash

LastPrivateKeyHash is a hash of the private key associated with the latest
registered ACME account, in order to track changes made to registered account
associated with the Issuer

=head2 lastRegisteredEmail

LastRegisteredEmail is the email associated with the latest registered
ACME account, in order to track changes made to registered account
associated with the  Issuer

=head2 uri

URI is the unique account identifier, which can also be used to retrieve
account details from the CA

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
