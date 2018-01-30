package Mastodon::Entity::Results;

use strict;
use warnings;

our $VERSION = '0.014';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Str ArrayRef );
use Mastodon::Types qw( Account Status );

has accounts => ( is => 'ro', isa => ArrayRef [Account], );
has hashtags => ( is => 'ro', isa => ArrayRef [Str], required => 1, ); # Not Tag!
has statuses => ( is => 'ro', isa => ArrayRef [Status], );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Results - A Mastodon search result

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#results>

=head1 ATTRIBUTES

=over 4

=item B<accounts>

An array of matched L<Mastodon::Entity::Account> objects.

=item B<statuses>

An array of matchhed L<Mastodon::Entity::Status> objects.

=item B<hashtags>

An array of matched hashtags, as strings.

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
