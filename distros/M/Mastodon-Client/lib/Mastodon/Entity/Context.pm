package Mastodon::Entity::Context;

use strict;
use warnings;

our $VERSION = '0.012';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( ArrayRef );
use Mastodon::Types qw( Status );

has ancestors   => ( is => 'ro', isa => ArrayRef [Status], required => 1, );
has descendants => ( is => 'ro', isa => ArrayRef [Status], );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Context - The context of a Mastodon status

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#context>

=head1 ATTRIBUTES

=over 4

=item B<ancestors>

The ancestors of the status in the conversation, as a list of
L<Mastodon::Entity::Status> objects.

=item B<descendants>

The descendants of the status in the conversation, as a list of
L<Mastodon::Entity::Status> objects.

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
