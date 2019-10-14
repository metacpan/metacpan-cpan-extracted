package Mastodon::Entity::Account;

use strict;
use warnings;

our $VERSION = '0.016';

use Moo;
with 'Mastodon::Role::Entity';

use Types::Standard qw( Int Str Bool );
use Mastodon::Types qw( Acct URI DateTime );

use Log::Any;
my $log = Log::Any->get_logger( category => 'Mastodon' );

has acct            => ( is => 'ro', isa => Acct, required => 1, );
has avatar          => ( is => 'ro', isa => URI, coerce => 1, required => 1, );
has avatar_static   => ( is => 'ro', isa => URI, coerce => 1, );
has created_at      => ( is => 'ro', isa => DateTime, coerce => 1, );
has display_name    => ( is => 'ro', isa => Str, );
has followers_count => ( is => 'ro', isa => Int, );
has following_count => ( is => 'ro', isa => Int, );
has header          => ( is => 'ro', isa => URI, coerce => 1, );
has header_static   => ( is => 'ro', isa => URI, coerce => 1, );
has id              => ( is => 'ro', isa => Int, );
has locked          => ( is => 'ro', isa => Bool, coerce => 1, );
has note            => ( is => 'ro', isa => Str, );
has statuses_count  => ( is => 'ro', isa => Int, );
has url             => ( is => 'ro', isa => URI, coerce => 1, );
has username        => ( is => 'ro', isa => Str, );

foreach my $pair (
    [ fetch        => 'get_account' ],
    [ followers    => undef ],
    [ following    => undef ],
    [ statuses     => undef ],
    [ follow       => undef ],
    [ unfollow     => undef ],
    [ block        => undef ],
    [ unblock      => undef ],
    [ mute         => undef ],
    [ unmute       => undef ],
    [ relationship => 'relationships' ],
    [ authorize    => 'authorize_follow' ],
    [ reject       => 'reject_follow' ],
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

sub remote_follow {
  my $self = shift;
  croak $log->fatal(q{Cannot call 'remote_follow' without client})
    unless $self->_client;
  $self->_client->remote_follow($self->acct, @_);
}

sub report {
  my ($self, $params) = @_;
  croak $log->fatal(q{Cannot call 'report' without client})
    unless $self->_client;
  $self->_client->report({
    %{$params},
    account_id => $self->id,
  });
}

1;

=encoding utf8

=head1 NAME

Mastodon::Entity::Account - A Mastodon user account

=head1 DESCRIPTION

This object should not be manually created. It is intended to be generated
from the data received from a Mastodon server using the coercions in
L<Mastodon::Types>.

For current information, see the
L<Mastodon API documentation|https://github.com/tootsuite/documentation/blob/master/Using-the-API/API.md#account>

=head1 ATTRIBUTES

=over 4

=item B<id>

The ID of the account

=item B<username>

The username of the account

=item B<acct>

Equals C<username> for local users, includes C<@domain> for remote ones

=item B<display_name>

The account's display name

=item B<locked>

Boolean for when the account cannot be followed without waiting for approval
first

=item B<created_at>

The time the account was created

=item B<followers_count>

The number of followers for the account

=item B<following_count>

The number of accounts the given account is following

=item B<statuses_count>

The number of statuses the account has made

=item B<note>

Biography of user

=item B<url>

URL of the user's profile page (can be remote)

=item B<avatar>

URL to the avatar image

=item B<avatar_static>

URL to the avatar static image (gif)

=item B<header>

URL to the header image

=item B<header_static>

URL to the header static image (gif)

=back

=head1 METHODS

This class provides the following convenience methods. They act as a shortcut,
passing the appropriate identifier of the current object as the first argument
to the corresponding methods in L<Mastodon::Client>.

=over 4

=item B<fetch>

A shortcut to C<get_account>.

=item B<followers>

A shortcut to C<followers>.

=item B<following>

A shortcut to C<following>.

=item B<statuses>

A shortcut to C<statuses>.

=item B<follow>

A shortcut to C<follow>.

=item B<unfollow>

A shortcut to C<unfollow>.

=item B<remote_follow>

A shortcut to C<remote_follow>.

=item B<report>

A shortcut to C<report>.

=item B<block>

A shortcut to C<block>.

=item B<unblock>

A shortcut to C<unblock>.

=item B<mute>

A shortcut to C<mute>.

=item B<unmute>

A shortcut to C<unmute>.

=item B<relationship>

A shortcut to C<relationships>.

=item B<authorize>

A shortcut to C<authorize_follow>.

=item B<reject>

A shortcut to C<reject_follow>.

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
