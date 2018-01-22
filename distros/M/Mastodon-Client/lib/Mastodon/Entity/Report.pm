package Mastodon::Entity::Report;

use strict;
use warnings;

our $VERSION = '0.013';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Bool );

has id           => ( is => 'ro', isa => Int, );
has action_taken => ( is => 'ro', isa => Bool, required => 1, );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Report- A Mastodon report

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#report>

=head1 ATTRIBUTES

=over 4

=item B<id>

Target id of the report.

=item B<action_taken>

The action taken in response to the report.

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
