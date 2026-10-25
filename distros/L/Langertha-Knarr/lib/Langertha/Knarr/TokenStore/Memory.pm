package Langertha::Knarr::TokenStore::Memory;
# ABSTRACT: In-memory token store for tests of token_auth
our $VERSION = '1.103';
use Moose;
use Carp qw( croak );
use Future;


has available => (
  is => 'ro',
  isa => 'Bool',
  default => 1,
  writer => '_set_available',
);

has lookups => (
  is => 'ro',
  isa => 'Int',
  default => 0,
  writer => '_set_lookups',
);

has _rows => (
  is => 'ro',
  isa => 'HashRef',
  default => sub { {} },
);

# after the attributes: the role requires the available accessor
with 'Langertha::Knarr::TokenStore';

sub _hash_of {
  my ($self, %args) = @_;
  return lc $args{hash} if defined $args{hash};
  return $self->hash_token($args{token}) if defined $args{token};
  croak __PACKAGE__.": token or hash required";
}

sub add {
  my ($self, %args) = @_;
  croak __PACKAGE__."->add: model required" unless defined $args{model};
  $self->_rows->{ $self->_hash_of(%args) } = {
    model    => $args{model},
    provider => $args{provider},
    expires  => defined $args{expires} ? $args{expires} : time + 900,
  };
  return;
}

sub revoke {
  my ($self, %args) = @_;
  delete $self->_rows->{ $self->_hash_of(%args) };
  return;
}

sub notify { $_[0]->invalidate('notify') }

sub disconnect {
  my ($self) = @_;
  $self->_set_available(0);
  $self->invalidate('disconnect');
  return;
}

sub reconnect { $_[0]->_set_available(1); return }

sub _find {
  my ($self, $hash) = @_;
  $self->_set_lookups( $self->lookups + 1 );
  my $row = $self->_rows->{ lc $hash } or return;
  return unless $row->{expires} > time;
  return { %$row };
}

sub lookup_f {
  my ($self, $hash) = @_;
  return Future->fail("token store unavailable\n", 'token_store')
    unless $self->available;
  return Future->done( scalar $self->_find($hash) );
}

sub lookup {
  my ($self, $hash) = @_;
  croak "token store unavailable" unless $self->available;
  return scalar $self->_find($hash);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::TokenStore::Memory - In-memory token store for tests of token_auth

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr::TokenStore::Memory;

    my $store = Langertha::Knarr::TokenStore::Memory->new;
    $store->add( token => 'tok-1', model => 'gpt-4o', provider => 'openai',
                 expires => time + 900 );

    $store->revoke( token => 'tok-1' );
    $store->notify;        # what NOTIFY on the listen channel does
    $store->disconnect;    # available 0 + invalidate
    $store->reconnect;

    is $store->lookups, 3; # lookups that reached the store

=head1 DESCRIPTION

A L<Langertha::Knarr::TokenStore> that keeps its rows in a hash, with
handles to play the database's part: L</revoke> changes a row like a
C<DELETE>, L</notify> is the notification that follows it, L</disconnect>
and L</reconnect> are the connection going away and coming back. Every
lookup that reaches the store counts in L</lookups>, so a test can tell a
cache hit (no new lookup) from a miss.

Like L<Langertha::Knarr::TokenStore::Pg> it returns a row only while its
C<expires> is in the future, and fails every lookup while it is not
L</available>.

=head2 available

True unless L</disconnect> was called without a L</reconnect> since.
Default C<1>; C<< available => 0 >> starts disconnected.

=head2 lookups

Number of lookups (L</lookup_f> and L</lookup>) that reached the store
while it was available.

=head2 add

    $store->add( token => $token, model => $m, provider => $p, expires => $epoch );
    $store->add( hash  => $hash_hex, model => $m );

Adds or replaces the row of a token, given as the token itself or as its
L<Langertha::Knarr::TokenStore/hash_token>. C<model> is required,
C<provider> optional, C<expires> (epoch seconds) defaults to 900 seconds
from now. Fires no invalidation (a new token cannot be in a cache).

=head2 revoke

    $store->revoke( token => $token );   # or hash => $hash_hex

Removes the row of a token. Like a C<DELETE> without a trigger, it fires
nothing: a caller's cache keeps the row until L</notify>.

=head2 notify

Calls L<Langertha::Knarr::TokenStore/invalidate> with C<notify>.

=head2 disconnect

Sets L</available> to C<0> and invalidates with C<disconnect>.

=head2 reconnect

Sets L</available> back to C<1>.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-knarr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
