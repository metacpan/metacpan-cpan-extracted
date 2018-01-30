package Mastodon::Entity::Notification;

use strict;
use warnings;

our $VERSION = '0.014';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Enum );
use Mastodon::Types qw( Status URI DateTime Account Acct );

has account    => ( is => 'ro', isa => Account, );
has created_at => ( is => 'ro', isa => DateTime, );
has id         => ( is => 'ro', isa => Int, );
has status     => ( is => 'ro', isa => Status, required => 1, coerce => 1, );
has type       => ( is => 'ro', isa => Enum[qw(
  mention reblog favourite follow
)], );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Notification - A Mastodon notification

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#notification>

=head1 ATTRIBUTES

=over 4

=item B<id>

The notification ID.

=item B<type>

One of: "mention", "reblog", "favourite", "follow".

=item B<created_at>

The time the notification was created.

=item B<account>

The Account sending the notification to the user as a
L<Mastodon::Entity::Account> object.

=item B<status>

The Status associated with the notification, if applicable. As a
L<Mastodon::Entity::Status> object.

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
