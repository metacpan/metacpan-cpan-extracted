package IO::K8s::Api::Authentication::V1::TokenReviewStatus;
# ABSTRACT: TokenReviewStatus is the result of the token authentication request.
our $VERSION = '1.100';
use IO::K8s::Resource;

k8s audiences => [Str];


k8s authenticated => Bool;


k8s error => Str;


k8s user => 'Authentication::V1::UserInfo';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authentication::V1::TokenReviewStatus - TokenReviewStatus is the result of the token authentication request.

=head1 VERSION

version 1.100

=head2 audiences

Audiences are audience identifiers chosen by the authenticator that are compatible with both the TokenReview and token. An identifier is any identifier in the intersection of the TokenReviewSpec audiences and the token's audiences. A client of the TokenReview API that sets the spec.audiences field should validate that a compatible audience identifier is returned in the status.audiences field to ensure that the TokenReview server is audience aware. If a TokenReview returns an empty status.audience field where status.authenticated is "true", the token is valid against the audience of the Kubernetes API server.

=head2 authenticated

Authenticated indicates that the token was associated with a known user.

=head2 error

Error indicates that the token couldn't be checked

=head2 user

User is the UserInfo associated with the provided token.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
