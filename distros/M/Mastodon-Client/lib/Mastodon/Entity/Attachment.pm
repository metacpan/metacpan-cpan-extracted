package Mastodon::Entity::Attachment;

use strict;
use warnings;

our $VERSION = '0.013';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Maybe Enum Int Str Bool );
use Mastodon::Types qw( Acct URI );

has id          => ( is => 'ro', isa => Int, );
has preview_url => ( is => 'ro', isa => URI, coerce => 1, required => 1, );
has remote_url  => ( is => 'ro', isa => URI, coerce => 1, );
has text_url    => ( is => 'ro', isa => Maybe [URI], coerce => 1, );
has url         => ( is => 'ro', isa => URI, coerce => 1, );
has type        => ( is => 'ro', isa => Enum[qw( image video gifv )], );

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Attachment - A Mastodon media attachment

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#attachment>

=head1 ATTRIBUTES

=over 4

=item B<id>

ID of the attachment.

=item B<type>

One of: "image", "video", "gifv".

=item B<url>

URL of the locally hosted version of the image.

=item B<remote_url>

For remote images, the remote URL of the original image.

=item B<preview_url>

URL of the preview image

=item B<text_url>

Shorter URL for the image, for insertion into text (only present on local
images).

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
