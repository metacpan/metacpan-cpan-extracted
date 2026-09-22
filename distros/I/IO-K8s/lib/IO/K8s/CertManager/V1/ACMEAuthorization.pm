package IO::K8s::CertManager::V1::ACMEAuthorization;
# ABSTRACT: ACMEAuthorization contains data returned from the ACME server on an authorization that must be completed in order validate a DNS name on an ACME Order resource.
our $VERSION = '1.108';
use IO::K8s::Resource;

k8s challenges   => ['+IO::K8s::CertManager::V1::ACMEChallenge'];
k8s identifier   => Str;
k8s initialState => Str, { enum => [qw(valid ready pending processing invalid expired errored)] };
k8s url          => Str, { required => 'schema' };
k8s wildcard     => Bool;






1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::CertManager::V1::ACMEAuthorization - ACMEAuthorization contains data returned from the ACME server on an authorization that must be completed in order validate a DNS name on an ACME Order resource.

=head1 VERSION

version 1.108

=head2 challenges

Challenges specifies the challenge types offered by the ACME server.
One of these challenge types will be selected when validating the DNS
name and an appropriate Challenge resource will be created to perform
the ACME challenge process.

=head2 identifier

Identifier is the DNS name to be validated as part of this authorization

=head2 initialState

InitialState is the initial state of the ACME authorization when first
fetched from the ACME server.
If an Authorization is already 'valid', the Order controller will not
create a Challenge resource for the authorization. This will occur when
working with an ACME server that enables 'authz reuse' (such as Let's
Encrypt's production endpoint).
If not set and 'identifier' is set, the state is assumed to be pending
and a Challenge will be created.

=head2 url

URL is the URL of the Authorization that must be completed

=head2 wildcard

Wildcard will be true if this authorization is for a wildcard DNS name.
If this is true, the identifier will be the *non-wildcard* version of
the DNS name.
For example, if '*.example.com' is the DNS name being validated, this
field will be 'true' and the 'identifier' field will be 'example.com'.

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
