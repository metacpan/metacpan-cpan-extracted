package Mastodon::Entity::Status;

use strict;
use warnings;

our $VERSION = '0.015';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Maybe Int Str Bool ArrayRef Enum );
use Mastodon::Types qw(
  URI Account Status DateTime Attachment Mention Tag Application
);

use Log::Any;
my $log = Log::Any->get_logger( category => 'Mastodon' );

has account => (
  is => 'ro', isa => Account, coerce => 1, required => 1,
);

has application => (
  is => 'ro', isa => Maybe [Application], coerce => 1,
);

has content => (
  is => 'ro', isa => Str,
);

has created_at => (
  is => 'ro', isa => DateTime, coerce => 1,
);

has emojis => (
  is => 'ro', isa => ArrayRef,
);

has favourited => (
  is => 'ro', isa => Bool,
);

has favourites_count => (
  is => 'ro', isa => Int, required => 1,
);

has id => (
  is => 'ro', isa => Int,
);

has in_reply_to_account_id => (
  is => 'ro', isa => Maybe [Int],
);

has in_reply_to_id => (
  is => 'ro', isa => Maybe [Int],
);

has media_attachments => (
  is => 'ro', isa => ArrayRef [Attachment], coerce => 1,
);

has mentions => (
  is => 'ro', isa => ArrayRef [Mention], coerce => 1,
);

has reblog => (
  is => 'ro', isa => Maybe [Status], coerce => 1,
);

has reblogged => (
  is => 'ro', isa => Bool,
);

has reblogs_count => (
  is => 'ro', isa => Int,
);

has sensitive => (
  is => 'ro', isa => Bool,
);

has spoiler_text => (
  is => 'ro', isa => Str,
);

has tags => (
  is => 'ro', isa => ArrayRef [Tag], coerce => 1,
);

has uri => (
  is => 'ro', isa => Str,
);

has url => (
  is => 'ro', isa => URI, coerce => 1,
);

has visibility => (
  is => 'ro', isa => Enum[qw(
    public unlisted private direct
  )],
  required => 1,
);

foreach my $pair (
    [ fetch            => 'get_status' ],
    [ fetch_context    => 'get_status_context' ],
    [ fetch_card       => 'get_status_card' ],
    [ fetch_reblogs    => 'get_status_reblogs' ],
    [ fetch_favourites => 'get_status_favourites' ],
    [ delete           => 'delete_status' ],
    [ boost            => 'reblog' ],
    [ unboost          => 'unreblog' ],
    [ favourite        => undef ],
    [ unfavourite      => undef ],
  ) {

  my ($name, $method) = @{$pair};
  $method //= $name;

  no strict 'refs';
  *{ __PACKAGE__ . '::' . $name } = sub {
    my $self = shift;
    croak $log->fatal(qq{Cannot call '$name' without client})
      unless $self->_client;
    $self->_client->$method($self->id, @_);
  };
}

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Status - A Mastodon status

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#status>

=head1 ATTRIBUTES

=over 4

=item B<id>

The ID of the status.

=item B<uri>

A Fediverse-unique resource ID.

=item B<url>

URL to the status page (can be remote).

=item B<account>

The L<Mastodon::Entity::Account> which posted the status.

=item B<in_reply_to_id>

C<undef> or the ID of the status it replies to.

=item B<in_reply_to_account_id>

C<undef> or the ID of the account it replies to.

=item B<reblog>

C<undef> or the reblogged L<Mastodon::Entity::Status>.

=item B<content>

Body of the status; this will contain HTML (remote HTML already sanitized).

=item B<created_at>

The time the status was created as a L<DateTime> object.

=item B<reblogs_count>

The number of reblogs for the status.

=item B<favourites_count>

The number of favourites for the status.

=item B<reblogged>

Whether the authenticated user has reblogged the status.

=item B<favourited>

Whether the authenticated user has favourited the status.

=item B<sensitive>

Whether media attachments should be hidden by default.

=item B<spoiler_text>

If not empty, warning text that should be displayed before the actual content.

=item B<visibility>

One of: C<public>, C<unlisted>, C<private>, C<direct>.

=item B<media_attachments>

An array of L<Mastodon::Entity::Attachment> objects.

=item B<mentions>

An array of L<Mastodon::Entity::Mention> objects.

=item B<tags>

An array of L<Mastodon::Entity::Tag> objects.

=item B<application>

Application from which the status was posted, as a
L<Mastodon::Entity::Application> object.

=back

=head1 METHODS

This class provides the following convenience methods. They act as a shortcut,
passing the appropriate identifier of the current object as the first argument
to the corresponding methods in L<Mastodon::Client>.

=over 4

=item B<fetch>

A shortcut to C<get_status>.

=item B<fetch_context>

A shortcut to C<get_status_context>.

=item B<fetch_card>

A shortcut to C<get_status_card>.

=item B<fetch_reblogs>

A shortcut to C<get_status_reblogs>.

=item B<fetch_favourites>

A shortcut to C<get_status_favourites>.

=item B<delete>

A shortcut to C<delete_status>.

=item B<boost>

A shortcut to C<reblog>.

=item B<unboost>

A shortcut to C<unreblog>.

=item B<favourite>

A shortcut to C<favourite>.

=item B<unfavourite>

A shortcut to C<unfavourite>.

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
