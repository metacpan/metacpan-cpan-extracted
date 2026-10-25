use strict;
use warnings;
use Test2::V0;

# k82: the TokenStore contract, through the in-memory store the token_auth
# tests run on. Offline.
use Langertha::Knarr::TokenStore::Memory;

my $class = 'Langertha::Knarr::TokenStore::Memory';

my $store = $class->new;
ok( $store->DOES('Langertha::Knarr::TokenStore'), 'Memory does the TokenStore role' );
can_ok( $store, qw( lookup_f lookup available start poll invalidate on_invalidate hash_token ) );

subtest 'hash_token: lowercase hex sha256 of the token bytes' => sub {
  is( $store->hash_token('abc'),
    'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', 'known vector' );
  my $upgraded = "t\xe4k";
  utf8::upgrade($upgraded);
  is( $store->hash_token($upgraded), $store->hash_token("t\xe4k"),
    'characters below 256 are the bytes, upgraded or not' );
  is( $store->hash_token("t\x{263a}k"), $store->hash_token("t\xe2\x98\xbak"),
    'a wide character string hashes as its UTF-8 bytes' );
  like( $store->hash_token('x'), qr/\A[0-9a-f]{64}\z/, 'lowercase hex only' );
};

my @invalidated;
$store->on_invalidate( sub { push @invalidated, @_ } );

my $future = time + 900;
$store->add( token => 'tok-valid', model => 'gpt-4o', provider => 'openai', expires => $future );
$store->add( token => 'tok-old',   model => 'gpt-4o', provider => 'openai', expires => time - 1 );
$store->add( hash  => uc $store->hash_token('tok-by-hash'), model => 'claude', provider => 'anthropic' );

subtest 'lookups: hit, unknown, expired; every one reaches the store' => sub {
  my $before = $store->lookups;
  my $f = $store->lookup_f( $store->hash_token('tok-valid') );
  isa_ok( $f, 'Future' );
  is( $f->get, { model => 'gpt-4o', provider => 'openai', expires => $future }, 'valid token -> its row' );
  is( $store->lookups, $before + 1, 'counted' );

  is( $store->lookup_f( $store->hash_token('tok-unknown') )->get, undef, 'unknown -> undef' );
  is( $store->lookup_f( $store->hash_token('tok-old') )->get, undef, 'expired -> undef' );
  is( $store->lookups, $before + 3, 'misses count too' );

  is( $store->lookup( $store->hash_token('tok-valid') )->{model}, 'gpt-4o', 'blocking lookup: hit' );
  is( $store->lookup( $store->hash_token('tok-old') ), undef, 'blocking lookup: expired' );
  is( $store->lookups, $before + 5, 'blocking lookups count' );

  my $row = $store->lookup_f( uc $store->hash_token('tok-valid') )->get;
  is( $row->{model}, 'gpt-4o', 'an uppercase hash finds the row' );
  $row->{model} = 'tampered';
  is( $store->lookup( $store->hash_token('tok-valid') )->{model}, 'gpt-4o', 'rows are copies' );

  my $by_hash = $store->lookup( $store->hash_token('tok-by-hash') );
  is( $by_hash->{model}, 'claude', 'a row added by (uppercase) hash' );
  cmp_ok( $by_hash->{expires}, '>', time, 'expires defaults to the future' );
};

subtest 'revoke is silent, notify invalidates' => sub {
  @invalidated = ();
  $store->add( token => 'tok-revoke', model => 'm' );
  ok( $store->lookup_f( $store->hash_token('tok-revoke') )->get, 'there before' );
  $store->revoke( token => 'tok-revoke' );
  is( \@invalidated, [], 'revoke alone fires nothing (a DELETE without NOTIFY)' );
  is( $store->lookup_f( $store->hash_token('tok-revoke') )->get, undef, 'gone after revoke' );
  $store->notify;
  is( \@invalidated, ['notify'], 'notify -> invalidate(notify)' );
};

subtest 'disconnect: unavailable, invalidated, lookups fail; reconnect' => sub {
  @invalidated = ();
  my $before = $store->lookups;
  $store->disconnect;
  ok( !$store->available, 'not available' );
  is( \@invalidated, ['disconnect'], 'disconnect -> invalidate(disconnect)' );

  my $f = $store->lookup_f( $store->hash_token('tok-valid') );
  ok( $f->is_failed, 'lookup_f fails while disconnected' );
  my ( $message, $category ) = $f->failure;
  is( $message, "token store unavailable\n", 'fixed failure text' );
  is( $category, 'token_store', 'failure category' );
  like( dies { $store->lookup( $store->hash_token('tok-valid') ) },
    qr/\Atoken store unavailable/, 'blocking lookup croaks' );
  is( $store->lookups, $before, 'nothing reached the store' );

  $store->reconnect;
  ok( $store->available, 'available again' );
  is( $store->lookup_f( $store->hash_token('tok-valid') )->get->{model}, 'gpt-4o', 'lookups work again' );
};

subtest 'on_invalidate: one listener, a dying one does not propagate' => sub {
  my @first;
  my @second;
  my $s = $class->new;
  $s->on_invalidate( sub { push @first, @_ } );
  $s->on_invalidate( sub { push @second, @_ } );
  $s->notify;
  is( [ \@first, \@second ], [ [], ['notify'] ], 'setting replaces the listener' );
  $s->on_invalidate( sub { die "listener broke\n" } );
  ok( lives { $s->notify }, 'a dying listener is contained' );
  ok( lives { $class->new->notify }, 'no listener: nothing happens' );
};

subtest 'start and poll are harmless; available => 0 starts disconnected' => sub {
  my $s = $class->new( available => 0 );
  ok( lives { $s->start; $s->poll }, 'start, poll' );
  ok( !$s->available, 'starts disconnected' );
  ok( $s->lookup_f('00')->is_failed, 'fails until reconnect' );
};

subtest 'argument errors' => sub {
  like( dies { $class->new->add( token => 't' ) }, qr/model required/, 'add needs a model' );
  like( dies { $class->new->add( model => 'm' ) }, qr/token or hash required/, 'add needs token or hash' );
  like( dies { $class->new->revoke }, qr/token or hash required/, 'revoke needs token or hash' );
};

done_testing;
