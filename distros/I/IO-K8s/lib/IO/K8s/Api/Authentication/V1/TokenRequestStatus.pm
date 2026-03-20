package IO::K8s::Api::Authentication::V1::TokenRequestStatus;
# ABSTRACT: TokenRequestStatus is the result of a token request.
our $VERSION = '1.009';
use IO::K8s::Resource;

k8s expirationTimestamp => Time, 'required';


k8s token => Str, 'required';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Api::Authentication::V1::TokenRequestStatus - TokenRequestStatus is the result of a token request.

=head1 VERSION

version 1.009

=head2 expirationTimestamp

ExpirationTimestamp is the time of expiration of the returned token.

=head2 token

Token is the opaque bearer token.

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
