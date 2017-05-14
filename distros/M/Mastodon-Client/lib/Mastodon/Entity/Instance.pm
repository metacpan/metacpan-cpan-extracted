package Mastodon::Entity::Instance;

use strict;
use warnings;

our $VERSION = '0.011';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Bool Str );
use Mastodon::Types qw( URI );

has email       => ( is => 'ro', isa => Str, );
has description => ( is => 'ro', isa => Str, );
has title       => ( is => 'ro', isa => Str, );
has uri         => ( is => 'ro', isa => URI, coerce => 1, required => 1, );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Instance - A Mastodon instance

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#instance>

=head1 ATTRIBUTES

=over 4

=item B<uri>

URI of the current instance.

=item B<title>

The instance's title.

=item B<description>

A description for the instance.

=item B<email>

An email address which can be used to contact the instance administrator.

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
