package Mastodon::Entity::Relationship;

use strict;
use warnings;

our $VERSION = '0.017';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Bool );

has id          => ( is => 'ro', isa => Int, );
has blocking    => ( is => 'ro', isa => Bool, coerce => 1, );
has followed_by => ( is => 'ro', isa => Bool, coerce => 1, );
has following   => ( is => 'ro', isa => Bool, coerce => 1, );
has muting      => ( is => 'ro', isa => Bool, coerce => 1, required => 1, );
has requested   => ( is => 'ro', isa => Bool, coerce => 1, );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Relationship - A Mastodon relationship

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#relationship>

=head1 ATTRIBUTES

=over 4

=item B<id>

Target account id.

=item B<following>

Whether the user is currently following the account.

=item B<followed_by>

Whether the user is currently being followed by the account.

=item B<blocking>

Whether the user is currently blocking the account.

=item B<muting>

Whether the user is currently muting the account.

=item B<requested>

Whether the user has requested to follow the account.

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
