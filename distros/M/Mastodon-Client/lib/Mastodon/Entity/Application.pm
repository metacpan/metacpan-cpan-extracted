package Mastodon::Entity::Application;

use strict;
use warnings;

our $VERSION = '0.015';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str Maybe );
use Mastodon::Types qw( URI );

has name     => ( is => 'ro', isa => Str, );
has website  => ( is => 'ro', isa => Maybe[URI], coerce => 1, required => 1,);

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Application - A Mastodon application

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#application>

=head1 ATTRIBUTES

=over 4

=item B<name>

Name of the app.

=item B<website>

Homepage URL of the app.

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
