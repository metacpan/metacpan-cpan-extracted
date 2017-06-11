package Mastodon::Entity::Error;

use strict;
use warnings;

our $VERSION = '0.012';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str );

has error => ( is => 'ro', isa => Str, required => 1, );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Error - An error in Mastodon

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#error>

=head1 ATTRIBUTES

=over 4

=item B<error>

A textual description of the error.

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
