package Mastodon::Entity::Mention;

use strict;
use warnings;

our $VERSION = '0.010';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str Int );
use Mastodon::Types qw( URI Acct );

has acct     => ( is => 'ro', isa => Acct, coerce => 1, required => 1, );
has id       => ( is => 'ro', isa => Int, );
has url      => ( is => 'ro', isa => URI,  coerce => 1, );
has username => ( is => 'ro', isa => Str, required => 1, );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Mention - A mention in Mastodon

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#mention>

=head1 ATTRIBUTES

=over 4

=item B<url>

URL of user's profile (can be remote).

=item B<username>

The C<username> of the account.

=item B<acct>

Equals C<username> for local users, includes C<@domain> for remote ones.

=item B<id>

Account ID.

=back

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
