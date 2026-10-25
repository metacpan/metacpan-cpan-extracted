package Langertha::Knarr::TokenStore;
# ABSTRACT: Role for the stores token_auth looks access tokens up in
our $VERSION = '1.103';
use Moose::Role;
use Digest::SHA qw( sha256_hex );
use Log::Any qw( $log );


requires qw( lookup_f lookup available );

has on_invalidate => (
  is => 'rw',
  isa => 'Maybe[CodeRef]',
);

sub start { }

sub poll { }

sub invalidate {
  my ($self, $reason) = @_;
  my $cb = $self->on_invalidate or return;
  eval { $cb->($reason); 1 }
    or $log->errorf( 'token store: invalidate listener failed: %s', $@ );
  return;
}

sub hash_token {
  my ($self, $token) = @_;
  my $bytes = $token;
  utf8::downgrade( $bytes, 1 ) or utf8::encode($bytes);
  return lc sha256_hex($bytes);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::TokenStore - Role for the stores token_auth looks access tokens up in

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    package My::TokenStore;
    use Moose;
    with 'Langertha::Knarr::TokenStore';

    sub lookup_f  { my ($self, $hash) = @_; ... }   # Future: row or undef
    sub lookup    { my ($self, $hash) = @_; ... }   # row or undef, blocking
    sub available { ... }

    # the consumer (Langertha::Knarr::Authorizer::Token):
    $store->on_invalidate( sub { %cache = () } );
    $store->start;
    my $row = await $store->lookup_f( $store->hash_token($bearer) );
    # { model => 'gpt-4o', provider => 'openai', expires => 1792512000 }

=head1 DESCRIPTION

The interface between C<token_auth> and the place the issued tokens live.
A store answers one question: which row belongs to this token hash, if the
token has not expired yet. It never sees the token itself, only
L</hash_token> of it, and it holds no cache: the caller caches hits and
throws its cache away whenever the store calls L</on_invalidate>.

A store calls L</invalidate> when a row may have changed behind the
caller's back (a notification from the database) and when it loses its
connection, since a revocation sent while it was gone would otherwise be
missed. While L</available> is false the caller rejects every token.

Stores: L<Langertha::Knarr::TokenStore::Pg> (PostgreSQL, LISTEN/NOTIFY) and
L<Langertha::Knarr::TokenStore::Memory> (tests).

A row is a HashRef C<< { model, provider, expires } >> with C<expires> as
epoch seconds. A store returns only rows whose C<expires> is still in the
future at the time of the lookup.

=head2 lookup_f

    my $row = await $store->lookup_f($hash_hex);

Required. A L<Future> done with the row of the token hash, or with
C<undef> when there is none or it has expired. It fails only on a store
error (also while the store is not L</available>), with a fixed text that
names no credential.

=head2 lookup

    my $row = $store->lookup($hash_hex);

Required. L</lookup_f> for a caller without a running event loop (the PSGI
adapter): blocks, delivers pending invalidations first, then asks. Croaks
on a store error.

=head2 available

Required. True while the store can answer. False while it has no
connection (not yet connected, lost, reconnecting); the caller then answers
C<503>.

=head2 start

    $store->start;

Opens the store's connection if it has one and it is not open yet, without
waiting for it; a second call does nothing. L<Langertha::Knarr> calls it
through L<Langertha::Knarr::Authorizer::Token/start> in the process that
serves; otherwise the first lookup does the same. The default does nothing.

=head2 poll

    $store->poll;

Delivers the invalidations that have arrived, without waiting. A caller
without an event loop (L<Langertha::Knarr::PSGI>) calls it before it reads
its cache, since nothing else would deliver them there. The default does
nothing (a store that invalidates synchronously needs no poll).

=head2 on_invalidate

Optional CodeRef, read-write. The one listener the store calls through
L</invalidate>, with the reason as its argument (C<notify>,
C<disconnect>). Setting it replaces the previous listener: a store serves
one authorizer.

=head2 invalidate

    $store->invalidate('notify');

Calls L</on_invalidate> with the reason, if one is set. A listener that
dies is logged, not propagated: the store's own state must not depend on it.

=head2 hash_token

    my $hash = $store->hash_token($token);

The lowercase hex SHA-256 of the token's bytes, the form a store looks up.
The token's characters are its bytes (as a header value read off the wire
is); a string with characters above 255 is encoded as UTF-8 first.

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
