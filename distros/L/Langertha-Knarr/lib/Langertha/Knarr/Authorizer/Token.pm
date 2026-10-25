package Langertha::Knarr::Authorizer::Token;
# ABSTRACT: One short-lived token per model, checked against a token store
our $VERSION = '1.103';
use Moose;
use Future;
use Log::Any qw( $log );
use Scalar::Util qw( weaken );
use namespace::autoclean;

with 'Langertha::Knarr::Authorizer';


has store => (
  is       => 'ro',
  does     => 'Langertha::Knarr::TokenStore',
  required => 1,
);

has match_model => (
  is      => 'ro',
  isa     => 'Bool',
  default => 1,
);

# Hits by token hash. Dropped whole on every invalidation.
has _cache => (
  is      => 'ro',
  default => sub { {} },
);

# Counts invalidations: a lookup that started before one must not put its
# row into the new cache.
has _generation => (
  is      => 'rw',
  default => 0,
);

# The process that started the store: once per process (k82).
has _started_pid => (
  is      => 'rw',
  default => 0,
);

sub BUILD {
  my ($self) = @_;
  weaken( my $weak = $self );
  $self->store->on_invalidate( sub {
    my ($reason) = @_;
    my $self = $weak or return;
    $self->clear_cache;
    $log->debugf( 'token check: cache dropped (%s)', $reason // 'invalidate' );
  } );
}


sub start {
  my ($self) = @_;
  return if $self->_started_pid == $$;
  $self->_started_pid($$);
  $self->store->start;
  return;
}


sub clear_cache {
  my ($self) = @_;
  %{ $self->_cache } = ();
  $self->_generation( $self->_generation + 1 );
  return;
}


sub identify_f {
  my ( $self, $http_req, $action ) = @_;
  return Future->done( $self->_anonymous ) if $action eq 'a2a_card';
  my ( $hash, $refused ) = $self->_token_hash($http_req);
  return Future->done($refused) if $refused;
  if ( my $result = $self->_cached($hash) ) {
    return Future->done($result);
  }
  # A miss asks the store, which connects on its first lookup and fails
  # every lookup while it is not available.
  my $generation = $self->_generation;
  weaken( my $weak = $self );
  my $f = eval { $self->store->lookup_f($hash) }
    // Future->fail( 'lookup did not start', 'token_store' );
  # The store's failure text stays with the store: it logs what it may.
  return $f->then( sub {
    my ($row) = @_;
    my $self = $weak or return Future->done( __PACKAGE__->_unavailable('authorizer gone') );
    return Future->done( $self->_found( $hash, $row, $generation ) );
  } )->else( sub {
    return Future->done( __PACKAGE__->_unavailable('lookup failed') );
  } );
}


sub identify {
  my ( $self, $http_req, $action ) = @_;
  return $self->_anonymous if $action eq 'a2a_card';
  my ( $hash, $refused ) = $self->_token_hash($http_req);
  return $refused if $refused;
  my $row = eval { $self->store->lookup($hash) };
  return $self->_unavailable('lookup failed') if $@;
  return $self->_found( $hash, $row );
}


sub authorize {
  my ( $self, $identity, $action, $model ) = @_;
  return ( 403, 'forbidden: not available with token auth' ) if $action eq 'manifest';
  return unless $action eq 'chat' || $action eq 'show';
  return unless $self->match_model;
  my $allowed = $identity->{model};
  return if defined $model && defined $allowed && $model eq $allowed;
  $log->debug('token check: model not allowed for this token');
  return ( 403, 'forbidden: model not allowed for this token' );
}


sub visible_models {
  my ( $self, $identity, $models ) = @_;
  my $model = $identity->{model};
  return [] unless defined $model && length $model;
  return [ { id => $model, object => 'model' } ];
}


sub forwards_client_key { 0 }

sub _anonymous { return { identity => {} } }

sub _unauthorized {
  my ( $self, $reason ) = @_;
  $log->debugf( 'token check: %s', $reason );
  return { status => 401, message => 'unauthorized' };
}

sub _unavailable {
  my ( $self, $reason ) = @_;
  $log->debugf( 'token check: %s', $reason );
  return { status => 503, message => 'token check unavailable' };
}

# The hash of the one token the request presents, or ( undef, refusal ).
sub _token_hash {
  my ( $self, $http_req ) = @_;
  my %tokens;
  for my $name ( 'Authorization', 'x-api-key' ) {
    my $value = scalar $http_req->header($name);
    next unless defined $value;
    my $bearer = lc $name eq 'authorization';
    for my $element ( split /,/, $value ) {
      $element =~ s/\A\s+|\s+\z//g;
      next if $bearer && $element !~ s/\ABearer\s+//i;
      next unless length $element;
      $tokens{$element} = 1;
    }
  }
  return ( undef, $self->_unauthorized('no token') ) unless %tokens;
  return ( undef, $self->_unauthorized('more than one token') ) if keys %tokens > 1;
  my ($token) = keys %tokens;
  return $self->store->hash_token($token);
}

# The identity of a cached row that has not expired. An expired one leaves.
# A store that lost its connection has dropped the cache by then; should
# one say nothing, a hit is still refused while it is not available.
sub _cached {
  my ( $self, $hash ) = @_;
  my $row = $self->_cache->{$hash} or return;
  return $self->_unavailable('store not available') unless $self->store->available;
  return $self->_identity($row) if $self->_live($row);
  delete $self->_cache->{$hash};
  return $self->_unauthorized('expired token');
}

# A looked-up row as the identify result; cached when no invalidation came
# in since the lookup started ($generation; undef: not cached).
sub _found {
  my ( $self, $hash, $row, $generation ) = @_;
  return $self->_unauthorized('unknown token') unless ref $row eq 'HASH';
  return $self->_unauthorized('expired token') unless $self->_live($row);
  $self->_cache->{$hash} = $row
    if defined $generation && $generation == $self->_generation;
  return $self->_identity($row);
}

sub _live {
  my ( $self, $row ) = @_;
  return defined $row->{expires} && $row->{expires} > time;
}

sub _identity {
  my ( $self, $row ) = @_;
  return { identity => {
    model    => $row->{model},
    provider => $row->{provider},
    expires  => $row->{expires},
  } };
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Knarr::Authorizer::Token - One short-lived token per model, checked against a token store

=head1 VERSION

version 1.103

=head1 SYNOPSIS

    use Langertha::Knarr::Authorizer::Token;
    use Langertha::Knarr::TokenStore::Memory;
    use Langertha::Knarr::Handler::TokenRoutes;

    my $store = Langertha::Knarr::TokenStore::Memory->new;
    $store->add( token => 'tok-1', model => 'gpt-4o', provider => 'openai',
                 expires => time + 900 );

    my $knarr = Langertha::Knarr->new(
      authorizer => Langertha::Knarr::Authorizer::Token->new( store => $store ),
      handler    => Langertha::Knarr::Handler::TokenRoutes->new( routes => {
        openai => { provider => 'openai', key_env => 'OPENAI_API_KEY' },
      } ),
    );

=head1 DESCRIPTION

The L<Langertha::Knarr::Authorizer> behind C<token_auth>: a platform issues a
short-lived token for exactly one model, and Knarr checks it against a
L<Langertha::Knarr::TokenStore> (a database view of the issued tokens).

=head2 Identify

The token comes as C<Authorization: Bearer> I<token> or C<x-api-key>; a
header sent twice counts as one value of comma-separated elements, like the
proxy key (an C<Authorization> element without C<Bearer> is no token). No
token, or more than one distinct token, is C<401>. The token's
L<Langertha::Knarr::TokenStore/hash_token> is looked up; an unknown,
revoked or expired token is C<401> C<unauthorized>, the same text as a
wrong proxy key. The A2A agent card stays anonymous.

Hits are cached by hash. A cached row is used only while its C<expires>
is in the future, and the cache is dropped whole whenever the store calls
its L<Langertha::Knarr::TokenStore/on_invalidate> (a notification on the
database's channel, a lost connection), so a revocation takes effect
without a restart. A lookup that was in flight when the cache was dropped
answers its request but is not cached. Misses are not cached.

When a lookup fails -- the store is not
L<Langertha::Knarr::TokenStore/available> (connection lost, reconnecting)
or broke down -- a request with a token is refused with C<503>
C<token check unavailable>: fail-closed, but not C<401>, so a platform does
not take a valid token for a bad one and the client may try again. The
answer says nothing about the token; a request without one still gets
C<401>. A cached row is not used either while the store is not available.
The store connects when the serving process calls L</start>, else on its
first lookup.

The synchronous path (L<Langertha::Knarr::PSGI>) asks the store for every
request instead of using the cache: the store's blocking lookup is what
picks up its pending notifications.

The identity is C<< { model, provider, expires } >> from the token's row,
never the token or its hash. Nothing here logs either; a refusal is logged
at debug level as C<token check: ...> with its reason only.

=head2 Authorize

With L</match_model> (the default) a chat request and C<POST /api/show>
must name the token's model, else C<403>
C<forbidden: model not allowed for this token> (no model name in the
text). A request that names no model (A2A, ACP without C<agent_name>) has
been given the token's model by then
(L<Langertha::Knarr::Request/apply_grant>). The model lists
(C</v1/models>, C</api/tags>, ACP C</agents>) show the token's model only.

The provider manifest (C</.well-known/langertha.json>) is refused with
C<403> C<forbidden: not available with token auth>: it describes the whole
model surface of the Knarr, which a token for one model must not see, and
its build is shared by every client. C</api/version> needs a valid token
and nothing more.

L</forwards_client_key> is false: a token-checked request never goes
through the raw passthrough, and C<Authorization> and C<x-api-key> are
dropped from every header set Knarr forwards, so the token never reaches an
upstream.

=head2 store

Required. A L<Langertha::Knarr::TokenStore>. The authorizer sets its
L<Langertha::Knarr::TokenStore/on_invalidate>: a store serves one
authorizer.

=head2 match_model

Default true. False lets a token use any model (the lists still show only
its own).

=head2 start

    $authorizer->start($loop);

Starts the store (L<Langertha::Knarr::TokenStore/start>) the first time it
is called in a process; later calls in the same process do nothing.
L<Langertha::Knarr> calls it in the process that serves, once its loop is
set up, so the store's connection is under way before the first request --
L<Langertha::Knarr::TokenStore::Pg/start> returns before its connect attempt
is done. A forked worker is a new process and starts its own.

=head2 clear_cache

Drops every cached row. The store's invalidation calls it.

=head2 identify_f

    my $result = await $authorizer->identify_f( $http_req, $action );

C<< { identity => { model, provider, expires } } >>, or
C<< { status => 401, message => 'unauthorized' } >>, or
C<< { status => 503, message => 'token check unavailable' } >>; the agent
card gets C<< { identity => {} } >>. Never fails.

=head2 identify

    my $result = $authorizer->identify( $http_req, $action );

The same result, with the store's blocking
L<Langertha::Knarr::TokenStore/lookup> for every request (no cache).

=head2 authorize

    my ( $status, $message ) = $authorizer->authorize( $identity, $action, $model );

C<403> for the manifest, and with L</match_model> for a C<chat> or C<show>
whose model is not the token's; empty otherwise.

=head2 visible_models

    my $models = $authorizer->visible_models( $identity, $listed );

C<< [ { id => $token_model, object => 'model' } ] >>, whatever the handler
lists; empty for an identity without a model.

=head2 forwards_client_key

False: the token never goes upstream.

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
